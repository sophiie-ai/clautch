import AppKit

extension NSWindow.Level {
    /// above menu bar, notch cover, and most system UI
    static let shielding = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
}

/// A borderless, transparent panel anchored to the notch area.
final class NotchPanel: NSPanel {

    init(screen: NSScreen) {
        let frame = screen.notchWindowFrame ?? NSRect(x: 0, y: 0, width: 260, height: 70)

        super.init(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        level = .shielding
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false

        // Appear on all Spaces, hide during Mission Control / Exposé
        collectionBehavior = [
            .fullScreenAuxiliary,
            .canJoinAllSpaces,
            .ignoresCycle,
        ]

        isMovable = false
        isMovableByWindowBackground = false
        acceptsMouseMovedEvents = true
    }
}
