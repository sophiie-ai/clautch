import AppKit
import SwiftUI

/// A host view that allows clicks to pass through transparent areas
/// while still responding to clicks on the creature / interactive elements.
final class NotchHitTestView: NSView {
    private let hostingView: NSView

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

    override func hitTest(_ point: NSPoint) -> NSView? {
        // Pass through clicks that land on the background (transparent areas).
        // Only intercept clicks that land on an actual subview with content.
        let hit = super.hitTest(point)
        return hit === self ? nil : hit
    }
}
