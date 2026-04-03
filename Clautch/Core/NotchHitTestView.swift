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

    /// Half-width of the expanded panel (from center). Set from screen geometry.
    var expandedPanelHalf: CGFloat = 150

    /// The bottom edge of the expanded panel (distance from top of window).
    var expandedPanelBottom: CGFloat = 160

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
        // Window top = screen top (notch area), so maxY = top of screen.
        let midX = bounds.midX

        if isExpanded {
            // Only accept clicks within the visible panel rectangle.
            // Panel runs from top of window (maxY) down to expandedPanelBottom from top.
            let panelTopY = bounds.maxY - expandedPanelBottom  // bottom edge of panel in view coords
            let panelLeft = midX - expandedPanelHalf
            let panelRight = midX + expandedPanelHalf

            if local.y >= panelTopY && local.x >= panelLeft && local.x <= panelRight {
                return self
            }
            return nil
        }

        // Collapsed: only accept clicks in the notch/menubar strip + creature peek.
        let collapsedClickableHeight = notchHeight + 20
        let minY = bounds.maxY - collapsedClickableHeight

        if local.y >= minY {
            return self
        }
        return nil
    }
}
