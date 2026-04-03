import AppKit
import SwiftUI

/// Manages auxiliary windows (Room, Stats, Onboarding) with common patterns:
/// show-or-focus, activation policy toggling, close observers, and frame autosave.
final class WindowCoordinator {
    private var windows: [String: NSWindow] = [:]
    private var closeTokens: [String: NSObjectProtocol] = [:]

    /// Show a window by key — reuses existing if open, otherwise creates from the builder.
    func show(
        key: String,
        title: String,
        size: NSSize,
        minSize: NSSize? = nil,
        resizable: Bool = false,
        autosaveName: String? = nil,
        content: () -> some View,
        onClose: (() -> Void)? = nil
    ) {
        // Reuse existing window
        if let existing = windows[key] {
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
            existing.makeKeyAndOrderFront(nil)
            existing.orderFrontRegardless()
            return
        }

        var styleMask: NSWindow.StyleMask = [.titled, .closable]
        if resizable { styleMask.insert([.resizable, .miniaturizable]) }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        if let minSize { window.minSize = minSize }
        if let name = autosaveName {
            window.setFrameAutosaveName(name)
        } else {
            window.center()
        }
        window.title = title
        window.contentView = NSHostingView(rootView: content())
        window.isReleasedWhenClosed = false

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()

        // Close observer
        let token = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.windows[key] = nil
            if let t = self?.closeTokens.removeValue(forKey: key) {
                NotificationCenter.default.removeObserver(t)
            }
            onClose?()
            // Return to accessory if no other managed windows are open
            if self?.windows.isEmpty ?? true {
                NSApp.setActivationPolicy(.accessory)
            }
        }
        closeTokens[key] = token
        windows[key] = window
    }

    /// Whether a window with the given key is currently open.
    func isOpen(_ key: String) -> Bool {
        windows[key] != nil
    }

    /// Whether any managed windows are open.
    var hasOpenWindows: Bool {
        !windows.isEmpty
    }
}
