import AppKit
import SwiftUI
import ServiceManagement
import os

class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchPanel: NotchPanel?
    private var onboardingWindow: NSWindow?
    private var roomWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var clickOutsideMonitor: Any?
    private let logger = Logger(subsystem: "com.clautch.app", category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Initialize state machine (sets up socket event callback)
        _ = StateMachine.shared

        // Install Claude Code hooks and start socket server
        HookInstaller.shared.installIfNeeded()
        HookInstaller.shared.startPeriodicRepair()
        SocketServer.shared.start()

        // Request notification permission
        NotificationService.shared.requestPermissionIfNeeded()

        // Setup menu bar
        setupStatusItem()

        // Show onboarding or go straight to notch panel
        if UserProfile.hasProfile {
            setupNotchPanel()
            // Auto-rejoin last room
            Task {
                await RoomManager.shared.autoRejoinIfNeeded()
            }
        } else {
            showOnboarding()
        }

        // Watch for screen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        logger.info("Clautch launched successfully")
    }

    func applicationWillTerminate(_ notification: Notification) {
        HookInstaller.shared.stopPeriodicRepair()
        SocketServer.shared.stop()
        if let monitor = clickOutsideMonitor { NSEvent.removeMonitor(monitor) }
        // Leave room gracefully
        Task { await RoomManager.shared.leaveRoom() }
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        let onboarding = OnboardingView { [weak self] _ in
            self?.onboardingWindow?.close()
            self?.onboardingWindow = nil
            self?.setupNotchPanel()
            self?.rebuildMenu()
            // Go back to accessory mode
            NSApp.setActivationPolicy(.accessory)
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 440, height: 540),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Welcome to Clautch"
        window.appearance = NSAppearance(named: .darkAqua)
        window.contentView = NSHostingView(rootView: onboarding)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        self.onboardingWindow = window
    }

    @objc private func changeCreature() {
        notchPanel?.close()
        notchPanel = nil
        showOnboarding()
    }

    // MARK: - Room Window

    @objc private func showRoomWindow() {
        if let existing = roomWindow, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let roomView = RoomView()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 380),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Clautch Room"
        window.contentView = NSHostingView(rootView: roomView)
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)

        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Return to accessory when closed
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] _ in
            self?.roomWindow = nil
            NSApp.setActivationPolicy(.accessory)
        }

        self.roomWindow = window
    }

    // MARK: - Notch Panel

    private func setupNotchPanel() {
        NSApp.setActivationPolicy(.accessory)

        // Check all screens for a notch — NSScreen.main may point to an
        // external display when the app launches in accessory mode.
        guard let screen = NSScreen.screens.first(where: { $0.hasNotch }) else {
            logger.info("No notch detected on any screen")
            return
        }

        let panel = NotchPanel(screen: screen)
        let contentView = NotchContentView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.layer?.backgroundColor = .clear

        let hitTestView = NotchHitTestView(hostingView: hostingView)
        hitTestView.onClicked = {
            let expanding = !NotchHoverState.shared.isHovered
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                NotchHoverState.shared.isHovered = expanding
            }
            NSSound(named: expanding ? "Pop" : "Tink")?.play()
        }
        panel.contentView = hitTestView
        panel.orderFrontRegardless()
        self.notchPanel = panel

        // Collapse when clicking outside the panel
        if let monitor = clickOutsideMonitor { NSEvent.removeMonitor(monitor) }
        clickOutsideMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            guard NotchHoverState.shared.isHovered,
                  let panel = self?.notchPanel else { return }
            let mouse = NSEvent.mouseLocation
            if !panel.frame.contains(mouse) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    NotchHoverState.shared.isHovered = false
                }
                NSSound(named: "Tink")?.play()
            }
        }

        logger.info("Notch panel created")
    }

    @objc private func screenDidChange() {
        guard onboardingWindow == nil else { return }
        notchPanel?.close()
        notchPanel = nil
        setupNotchPanel()
    }

    @objc private func didWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.screenDidChange()
            HookInstaller.shared.repairIfNeeded()
        }
    }

    // MARK: - Status Item (Menu Bar)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "ghost.fill",
                accessibilityDescription: "Clautch"
            )
        }

        rebuildMenu()
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(withTitle: "Clautch v0.1.0", action: nil, keyEquivalent: "")
        menu.addItem(.separator())

        // Profile info
        if let profile = UserProfile.current {
            let creatureItem = NSMenuItem(
                title: "\(profile.creatureType.displayName) — \(profile.displayName)",
                action: nil, keyEquivalent: ""
            )
            menu.addItem(creatureItem)
        }

        // Sessions header (dynamic content filled in menuWillOpen)
        menu.addItem(.separator())
        let sessionsHeader = NSMenuItem(title: "Sessions (0)", action: nil, keyEquivalent: "")
        sessionsHeader.tag = 300
        menu.addItem(sessionsHeader)
        let sentinel = NSMenuItem.separator()
        sentinel.tag = 399
        menu.addItem(sentinel)

        // Room
        let roomItem = NSMenuItem(
            title: "Room…",
            action: #selector(showRoomWindow),
            keyEquivalent: "r"
        )
        roomItem.target = self
        menu.addItem(roomItem)

        // Room status (dynamic, updated via delegate)
        let roomStatus = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        roomStatus.tag = 200
        menu.addItem(roomStatus)

        menu.addItem(.separator())

        let changeItem = NSMenuItem(
            title: "Change Creature…",
            action: #selector(changeCreature),
            keyEquivalent: ""
        )
        changeItem.target = self
        menu.addItem(changeItem)

        menu.addItem(.separator())

        // Notifications toggle
        let notifItem = NSMenuItem(
            title: "Notifications",
            action: #selector(toggleNotifications),
            keyEquivalent: ""
        )
        notifItem.target = self
        notifItem.tag = 500
        menu.addItem(notifItem)

        // Launch at Login toggle
        let loginItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        loginItem.target = self
        loginItem.tag = 600
        menu.addItem(loginItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Clautch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        self.statusItem?.menu = menu
    }

    // MARK: - Menu Actions

    @objc private func toggleNotifications() {
        Task { @MainActor in
            NotificationService.shared.isEnabled.toggle()
        }
    }

    @objc private func toggleLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
                logger.info("Unregistered from login items")
            } else {
                try service.register()
                logger.info("Registered as login item")
            }
        } catch {
            logger.error("Login item toggle failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Menu Delegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update room status
        if let item = menu.item(withTag: 200) {
            let rm = RoomManager.shared
            if let room = rm.currentRoom {
                item.title = "Room: \(room.roomCode) (\(rm.peerCount + 1) members)"
                item.isHidden = false
            } else {
                item.title = ""
                item.isHidden = true
            }
        }

        // Update sessions
        menu.items
            .filter { $0.tag >= 301 && $0.tag <= 398 }
            .forEach { menu.removeItem($0) }

        let active = StateMachine.shared.sessionStore.activeSessions
        if let header = menu.item(withTag: 300) {
            header.title = active.isEmpty ? "No active sessions" : "Sessions (\(active.count))"
        }

        if let sentinelIndex = menu.items.firstIndex(where: { $0.tag == 399 }) {
            for (i, session) in active.prefix(10).enumerated() {
                let shortId = String(session.id.prefix(8))
                let taskLabel = session.state.task.displayLabel
                let item = NSMenuItem(title: "  \(shortId)… — \(taskLabel)", action: nil, keyEquivalent: "")
                item.tag = 301 + i
                let symbolName: String = switch session.state.task {
                case .idle:       "circle"
                case .thinking:   "brain"
                case .working:    "hammer"
                case .sleeping:   "moon.zzz"
                case .compacting: "arrow.triangle.2.circlepath"
                }
                item.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: taskLabel)
                menu.insertItem(item, at: sentinelIndex + i)
            }
        }

        // Update toggles
        if let notifItem = menu.item(withTag: 500) {
            notifItem.state = NotificationService.shared.isEnabled ? .on : .off
        }
        if let loginItem = menu.item(withTag: 600) {
            loginItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        }
    }
}
