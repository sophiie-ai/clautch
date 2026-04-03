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
        guard bounds.contains(local) else { return nil }

        // NSView coordinates: y=0 is bottom, y increases upward.
        // Window top (maxY) = top of screen / notch area.

        if !isExpanded {
            // Collapsed: only accept clicks within the menu bar / notch height.
            let minY = bounds.maxY - notchHeight
            return local.y >= minY ? self : nil
        }

        // Expanded: check if the hosting view has opaque content at this point.
        // The SwiftUI view clips to PanelClipShape, so subviews outside
        // the visible island shape return nil from their own hitTest.
        if let hit = hostingView.hitTest(convert(local, to: hostingView)) {
            return hit === hostingView ? self : self
        }

        // Fallback: accept clicks in the top portion where the panel is drawn.
        // The panel extends from the top down; the bottom ~40% of the window
        // frame is empty space below the island.
        let panelMaxHeight = notchHeight + 120  // generous bound for panel content
        let minY = bounds.maxY - panelMaxHeight
        return local.y >= minY ? self : nil
    }
}
