import AppKit
import SwiftUI

/// Manages auxiliary windows (Room, Stats, Onboarding, Settings) with common patterns:
/// show-or-focus, activation policy toggling, close observers, and frame autosave.
/// All windows are centered on first show and brought to front reliably.
final class WindowCoordinator {
    private var windows: [String: NSWindow] = [:]
    private var closeTokens: [String: NSObjectProtocol] = [:]

    /// When true, the next window close won't switch to accessory mode.
    /// Set this before programmatically closing a window when the app should stay alive.
    var suppressAccessoryTransition = false

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
        // Reuse existing window — just bring to front
        if let existing = windows[key] {
            bringToFront(existing)
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
        }
        // Always center if no saved position (frame at origin means no saved state)
        if window.frame.origin == .zero {
            window.center()
        }
        window.title = title
        window.contentView = NSHostingView(rootView: content())
        window.isReleasedWhenClosed = false

        bringToFront(window)

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
                if self?.suppressAccessoryTransition == true {
                    self?.suppressAccessoryTransition = false
                } else {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }
        closeTokens[key] = token
        windows[key] = window
    }

    /// Close a managed window by key.
    func close(key: String) {
        windows[key]?.close()
    }

    /// Whether a window with the given key is currently open.
    func isOpen(_ key: String) -> Bool {
        windows[key] != nil
    }

    /// Whether any managed windows are open.
    var hasOpenWindows: Bool {
        !windows.isEmpty
    }

    // MARK: - Private

    /// Reliably bring a window to the front, activating the app.
    private func bringToFront(_ window: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        // orderFrontRegardless as a fallback for stubborn cases
        window.orderFrontRegardless()
    }
}
