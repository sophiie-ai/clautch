import AppKit
import SwiftUI
import ServiceManagement
import Sparkle
import os

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchPanel: NotchPanel?
    private let windowCoordinator = WindowCoordinator()
    private var statusItem: NSStatusItem?
    private var sessionBadgeTimer: Timer?
    private let logger = Logger(subsystem: "com.clautch.app", category: "AppDelegate")
    private lazy var updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Initialize state machine (sets up socket event callback)
        _ = StateMachine.shared

        // Install Claude Code hooks
        HookInstaller.shared.installIfNeeded()
        HookInstaller.shared.startPeriodicRepair()

        // Request notification permission
        NotificationService.shared.requestPermissionIfNeeded()

        // Register for CloudKit silent push notifications
        NSApp.registerForRemoteNotifications(matching: [])  // silent pushes only

        // Setup menu bar
        setupStatusItem()

        // If paused, only show menu bar — skip panel and socket
        if AnimationSettings.shared.isPaused {
            logger.info("Clautch launched in paused mode")
        } else if UserProfile.hasProfile {
            SocketServer.shared.start()
            setupNotchPanel()
            Task {
                await RoomManager.shared.autoRejoinIfNeeded()
            }
        } else {
            SocketServer.shared.start()
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

        // Clean up any mounted "Install Clautch" DMG volumes
        ejectInstallerVolumes()

        logger.info("Clautch launched successfully")
    }

    // MARK: - Deep Links

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        // clautch://join/CODE-TOKEN or clautch://join/CODE
        guard url.scheme == "clautch", url.host == "join" else {
            logger.warning("Unknown deep link: \(url)")
            return
        }
        let shareableCode = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !shareableCode.isEmpty else { return }

        logger.info("Deep link join: \(shareableCode)")
        Task { @MainActor in
            do {
                try await RoomManager.shared.joinRoom(shareableCode: shareableCode)
                // Show the room window after joining
                showRoomWindow()
            } catch {
                logger.error("Deep link join failed: \(error)")
                // Show room window anyway so user sees the error
                showRoomWindow()
            }
        }
    }

    func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
        // CloudKit silent push — trigger immediate peer sync
        Task { @MainActor in
            RoomManager.shared.handlePushNotification()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        sessionBadgeTimer?.invalidate()
        HookInstaller.shared.stopPeriodicRepair()
        SocketServer.shared.stop()
        // Leave room gracefully
        Task { await RoomManager.shared.leaveRoom() }
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        windowCoordinator.show(
            key: "onboarding",
            title: "Welcome to Clautch",
            size: NSSize(width: 440, height: 600),
            content: {
                OnboardingView { [weak self] _ in
                    // Close onboarding and set up the notch panel
                    DispatchQueue.main.async {
                        self?.setupNotchPanel()
                        self?.rebuildMenu()
                    }
                }
            }
        )
    }

    @objc private func changeCreature() {
        if windowCoordinator.isOpen("onboarding") {
            // Just re-show it
            showOnboarding()
            return
        }
        notchPanel?.close()
        notchPanel = nil
        showOnboarding()
    }

    // MARK: - Room Window

    @objc private func showRoomWindow() {
        windowCoordinator.show(
            key: "room",
            title: "Clautch Room",
            size: NSSize(width: 320, height: 420),
            minSize: NSSize(width: 300, height: 350),
            resizable: true,
            autosaveName: "ClautchRoom",
            content: { RoomView() }
        )
    }

    // MARK: - Stats Window

    @objc private func showStatsWindow() {
        windowCoordinator.show(
            key: "stats",
            title: "Clautch Usage Stats",
            size: NSSize(width: 360, height: 320),
            minSize: NSSize(width: 320, height: 280),
            resizable: true,
            autosaveName: "ClautchStats",
            content: { StatsView() }
        )
    }

    // MARK: - Notch Panel

    private static let preferredScreenKey = "com.clautch.preferredScreen"

    /// Find the preferred screen: user's saved choice, or first screen with a notch.
    private func preferredScreen() -> NSScreen? {
        let screens = NSScreen.screens.filter { $0.hasNotch }
        if let savedId = UserDefaults.standard.string(forKey: Self.preferredScreenKey),
           let match = screens.first(where: { $0.localizedName == savedId }) {
            return match
        }
        return screens.first
    }

    private func setupNotchPanel() {
        NSApp.setActivationPolicy(.accessory)

        guard let screen = preferredScreen() else {
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

        logger.info("Notch panel created")
    }

    @objc private func screenDidChange() {
        guard !windowCoordinator.isOpen("onboarding") else { return }
        let wasExpanded = NotchHoverState.shared.isHovered
        notchPanel?.close()
        notchPanel = nil
        setupNotchPanel()
        NotchHoverState.shared.isHovered = wasExpanded
    }

    @objc private func didWake() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.screenDidChange()
            HookInstaller.shared.repairIfNeeded()
        }
    }

    // MARK: - Status Item (Menu Bar)

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            let image = NSImage(named: "MenuBarIcon")
            image?.isTemplate = true
            image?.size = NSSize(width: 18, height: 18)
            button.image = image
            button.imagePosition = .imageLeading
        }

        rebuildMenu()
        startSessionBadgeTimer()
    }

    private var lastBadgeCount = -1
    private var creatureAnimTimer: Timer?
    private var creatureFrame = 0

    private func startSessionBadgeTimer() {
        sessionBadgeTimer?.invalidate()
        // 5-second interval is sufficient — activeSessions uses a 60s timeout
        sessionBadgeTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateSessionBadge()
            }
        }
    }

    @MainActor
    private func updateSessionBadge() {
        let count = StateMachine.shared.sessionStore.activeSessions.count
        guard count != lastBadgeCount else { return }
        lastBadgeCount = count
        guard let button = statusItem?.button else { return }
        button.title = count > 0 ? "\(count)" : ""

        // Start/stop creature animation based on setting
        if AnimationSettings.shared.menuBarCreature {
            startCreatureAnimation()
        } else {
            stopCreatureAnimation()
        }
    }

    @MainActor
    private func startCreatureAnimation() {
        guard creatureAnimTimer == nil else { return }
        updateMenuBarCreature()
        creatureAnimTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.creatureFrame += 1
                self?.updateMenuBarCreature()
            }
        }
    }

    private func stopCreatureAnimation() {
        creatureAnimTimer?.invalidate()
        creatureAnimTimer = nil
        // Restore default icon
        if let button = statusItem?.button {
            let image = NSImage(named: "MenuBarIcon")
            image?.isTemplate = true
            image?.size = NSSize(width: 18, height: 18)
            button.image = image
        }
    }

    @MainActor
    private func updateMenuBarCreature() {
        guard let profile = UserProfile.current,
              let button = statusItem?.button else { return }

        let type = profile.creatureType
        let frames = type.frames
        guard !frames.isEmpty else { return }
        let grid = frames[creatureFrame % frames.count]

        let size: CGFloat = 18
        let px = size / CGFloat(max(grid.first?.count ?? 8, 1))
        let image = NSImage(size: NSSize(width: size, height: size), flipped: true) { rect in
            for (r, row) in grid.enumerated() {
                for (c, cell) in row.enumerated() {
                    guard cell != 0 else { continue }
                    let color: NSColor = switch cell {
                    case 2: .labelColor          // eyes
                    case 3: .secondaryLabelColor  // mouth
                    default: .labelColor          // body
                    }
                    color.setFill()
                    NSRect(x: CGFloat(c) * px, y: CGFloat(r) * px, width: px + 0.5, height: px + 0.5).fill()
                }
            }
            return true
        }
        image.isTemplate = true
        button.image = image
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        // ── Header ──
        if let profile = UserProfile.current {
            let profileItem = NSMenuItem(
                title: "\(profile.creatureType.displayName) — \(profile.displayName)",
                action: nil, keyEquivalent: ""
            )
            menu.addItem(profileItem)
        }
        let statsItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        statsItem.tag = 150
        menu.addItem(statsItem)

        // ── Sessions ──
        menu.addItem(.separator())
        let sessionsHeader = NSMenuItem(title: "Sessions (0)", action: nil, keyEquivalent: "")
        sessionsHeader.tag = 300
        menu.addItem(sessionsHeader)
        let sentinel = NSMenuItem.separator()
        sentinel.tag = 399
        menu.addItem(sentinel)

        // ── Room ──
        menu.addItem(.separator())
        let roomItem = NSMenuItem(title: "Room…", action: #selector(showRoomWindow), keyEquivalent: "r")
        roomItem.target = self
        menu.addItem(roomItem)

        let roomStatus = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        roomStatus.tag = 200
        menu.addItem(roomStatus)

        let copyCodeItem = NSMenuItem(title: "Copy Invite Code", action: #selector(copyRoomCode), keyEquivalent: "")
        copyCodeItem.target = self
        copyCodeItem.tag = 201
        menu.addItem(copyCodeItem)

        let reactItem = NSMenuItem(title: "Send Reaction", action: nil, keyEquivalent: "")
        reactItem.tag = 250
        let reactMenu = NSMenu()
        for reaction in PeerReaction.allCases {
            let item = NSMenuItem(
                title: "\(reaction.emoji)  \(reaction.rawValue.capitalized)",
                action: #selector(sendReaction(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = reaction.rawValue
            reactMenu.addItem(item)
        }
        reactItem.submenu = reactMenu
        menu.addItem(reactItem)

        // ── Windows ──
        menu.addItem(.separator())
        let statsWindowItem = NSMenuItem(title: "Usage Stats…", action: #selector(showStatsWindow), keyEquivalent: "")
        statsWindowItem.target = self
        menu.addItem(statsWindowItem)

        let changeItem = NSMenuItem(title: "Change Creature…", action: #selector(changeCreature), keyEquivalent: "")
        changeItem.target = self
        menu.addItem(changeItem)

        // ── Display (notch screens only) ──
        let notchScreens = NSScreen.screens.filter { $0.hasNotch }
        if notchScreens.count > 1 {
            menu.addItem(.separator())
            let displayItem = NSMenuItem(title: "Display", action: nil, keyEquivalent: "")
            displayItem.tag = 850
            let displayMenu = NSMenu()
            for screen in notchScreens {
                let item = NSMenuItem(
                    title: screen.localizedName,
                    action: #selector(selectDisplay(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = screen.localizedName
                displayMenu.addItem(item)
            }
            displayItem.submenu = displayMenu
            menu.addItem(displayItem)
        }

        // ── System ──
        menu.addItem(.separator())

        let pauseItem = NSMenuItem(title: "Pause Clautch", action: #selector(togglePause), keyEquivalent: "")
        pauseItem.target = self
        pauseItem.tag = 800
        menu.addItem(pauseItem)

        let updateItem = NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "")
        updateItem.target = self
        menu.addItem(updateItem)

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(showSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())
        let aboutItem = NSMenuItem(title: "Clautch v\(version)", action: nil, keyEquivalent: "")
        menu.addItem(aboutItem)
        menu.addItem(withTitle: "Quit Clautch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        self.statusItem?.menu = menu
    }

    // MARK: - Menu Actions

    private var resignToken: NSObjectProtocol?

    @objc private func checkForUpdates() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        updaterController.checkForUpdates(nil)
        watchForResignActive()
    }

    /// Return to accessory mode as soon as the app loses focus.
    /// Covers Sparkle alerts, sheets, and any other transient windows.
    private func watchForResignActive() {
        guard resignToken == nil else { return }
        resignToken = NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.returnToAccessoryIfNeeded()
        }
    }

    private func returnToAccessoryIfNeeded() {
        guard !windowCoordinator.hasOpenWindows else { return }
        if let token = resignToken {
            NotificationCenter.default.removeObserver(token)
            resignToken = nil
        }
        NSApp.setActivationPolicy(.accessory)
    }

    @objc private func toggleNotifications() {
        Task { @MainActor in
            NotificationService.shared.isEnabled.toggle()
        }
    }

    @objc private func toggleReduceAnimation() {
        AnimationSettings.shared.reduceAnimationWhenCollapsed.toggle()
    }

    @objc private func toggleHideWhenCollapsed() {
        AnimationSettings.shared.hideWhenCollapsed.toggle()
    }

    @objc private func toggleStatusBar() {
        AnimationSettings.shared.showStatusBar.toggle()
    }

    @objc private func toggleEventLog() {
        AnimationSettings.shared.showEventLog.toggle()
    }

    @objc private func selectDisplay(_ sender: NSMenuItem) {
        guard let screenName = sender.representedObject as? String else { return }
        UserDefaults.standard.set(screenName, forKey: Self.preferredScreenKey)
        // Recreate the panel on the new screen
        notchPanel?.close()
        notchPanel = nil
        setupNotchPanel()
    }

    @objc private func togglePause() {
        let pausing = !AnimationSettings.shared.isPaused
        AnimationSettings.shared.isPaused = pausing

        if pausing {
            notchPanel?.close()
            notchPanel = nil
            SocketServer.shared.stop()
            sessionBadgeTimer?.invalidate()
            Task { @MainActor in
                SessionStats.shared.stopTracking()
            }
            logger.info("Clautch paused")
        } else {
            SocketServer.shared.start()
            setupNotchPanel()
            startSessionBadgeTimer()
            logger.info("Clautch resumed")
        }
    }

    @objc private func sendReaction(_ sender: NSMenuItem) {
        guard let rawValue = sender.representedObject as? String,
              let reaction = PeerReaction(rawValue: rawValue) else { return }
        Task { @MainActor in
            RoomManager.shared.sendReaction(reaction)
        }
    }

    @objc private func copyRoomCode() {
        Task { @MainActor in
            guard let room = RoomManager.shared.currentRoom else { return }
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(room.shareableCode, forType: .string)
        }
    }

    /// Eject any mounted "Install Clautch" DMG volumes left over from updates.
    private func ejectInstallerVolumes() {
        DispatchQueue.global(qos: .utility).async { [logger] in
            let fm = FileManager.default
            guard let volumes = try? fm.contentsOfDirectory(atPath: "/Volumes") else { return }
            for vol in volumes where vol.hasPrefix("Install Clautch") {
                let path = "/Volumes/\(vol)"
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/hdiutil")
                task.arguments = ["detach", path, "-quiet"]
                try? task.run()
                task.waitUntilExit()
                if task.terminationStatus == 0 {
                    logger.info("Ejected installer volume: \(vol)")
                }
            }
        }
    }

    @objc private func showSettings() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        // Open the SwiftUI Settings scene
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        // The Settings window is created lazily — find and bring it to front
        DispatchQueue.main.async {
            if let settingsWindow = NSApp.windows.first(where: {
                $0.title.contains("Settings") || $0.frameAutosaveName == "com.apple.SwiftUI.Settings"
            }) {
                if !settingsWindow.isVisible {
                    settingsWindow.center()
                }
                settingsWindow.makeKeyAndOrderFront(nil)
                settingsWindow.orderFrontRegardless()
            }
            self.watchForResignActive()
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
        if let copyItem = menu.item(withTag: 201) {
            copyItem.isHidden = RoomManager.shared.currentRoom == nil
        }

        // Update session stats
        if let statsItem = menu.item(withTag: 150) {
            let today = SessionStats.format(SessionStats.shared.todayTotal)
            let week = SessionStats.format(SessionStats.shared.weekTotal)
            let reset = SessionStats.weekResetLabel
            statsItem.title = "Usage: \(today) today · \(week) this week · Resets \(reset)"
        }
        if let reactItem = menu.item(withTag: 250) {
            reactItem.isHidden = RoomManager.shared.currentRoom == nil
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
        if let pauseItem = menu.item(withTag: 800) {
            pauseItem.state = AnimationSettings.shared.isPaused ? .on : .off
        }
        // Update display picker checkmarks
        if let displayItem = menu.item(withTag: 850),
           let displayMenu = displayItem.submenu {
            let current = preferredScreen()?.localizedName
            for item in displayMenu.items {
                item.state = (item.representedObject as? String) == current ? .on : .off
            }
        }
    }
}
