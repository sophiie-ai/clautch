import AppKit

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

        // Stay above the menu bar but below popovers and sheets
        level = NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
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
