import AppKit
import SwiftUI

/// A host view that allows clicks to pass through transparent areas
/// while tracking mouse hover over the full panel area.
/// When collapsed, only the notch + creature peek area is clickable;
/// everything below passes through to windows underneath.
final class NotchHitTestView: NSView {
    private let hostingView: NSView
    var onHoverChanged: ((Bool) -> Void)?
    var onClicked: (() -> Void)?

    /// Set by the AppDelegate when the panel expands/collapses.
    var isExpanded: Bool = false

    /// The height of the menu bar / notch safe area (set once on init).
    var notchHeight: CGFloat = 32

    init<Content: View>(hostingView: NSHostingView<Content>) {
        self.hostingView = hostingView
        super.init(frame: .zero)

        addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for area in trackingAreas { removeTrackingArea(area) }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverChanged?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChanged?(false)
    }

    override func mouseDown(with event: NSEvent) {
        onClicked?()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)

        if isExpanded {
            // When expanded, accept clicks on the full panel
            return bounds.contains(local) ? self : nil
        }

        // When collapsed, only accept clicks in the notch/menubar strip.
        // The creature peeks ~16px below the notch, so allow that too.
        // View coordinate system: y=0 is top, y increases downward.
        // But NSView flipped: y=0 is bottom by default.
        // Our window frame: top = screen top, so higher y = lower on screen.
        // In non-flipped coordinates: higher y = closer to top of window = closer to notch.
        let collapsedClickableHeight = notchHeight + 20  // notch + creature peek area
        let minY = bounds.maxY - collapsedClickableHeight  // bottom bound of clickable strip

        if local.y >= minY && bounds.contains(local) {
            return self
        }
        return nil
    }
}
