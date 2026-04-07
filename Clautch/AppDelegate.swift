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

        // Initialize gamification (loads streak/achievements, checks streak)
        _ = GamificationStore.shared

        // Install Claude Code hooks
        HookInstaller.shared.installIfNeeded()
        HookInstaller.shared.startPeriodicRepair()

        // Request notification permission
        NotificationService.shared.requestPermissionIfNeeded()

        // Silently check for updates on launch — only shows UI if a new version exists
        updaterController.updater.checkForUpdatesInBackground()

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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferredScreenChanged),
            name: .clautchPreferredScreenChanged,
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
        // Block until room cleanup completes so the presence record is
        // actually deleted before the process exits. We drain the RunLoop
        // to avoid deadlocking the MainActor.
        let done = DispatchSemaphore(value: 0)
        Task { @MainActor in
            await RoomManager.shared.leaveRoom()
            done.signal()
        }
        let deadline = Date(timeIntervalSinceNow: 3)
        while done.wait(timeout: .now()) == .timedOut, Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        }
    }

    // MARK: - Onboarding

    private func showOnboarding() {
        windowCoordinator.show(
            key: "onboarding",
            title: "Welcome to Clautch",
            size: NSSize(width: 440, height: 600),
            content: {
                OnboardingView { [weak self] _ in
                    DispatchQueue.main.async {
                        self?.rebuildMenu()
                        // Suppress accessory transition — notch panel keeps app alive
                        self?.windowCoordinator.suppressAccessoryTransition = true
                        self?.windowCoordinator.close(key: "onboarding")
                        // Fly creature to notch, THEN show the panel
                        self?.animateCreatureToNotch {
                            self?.setupNotchPanel()
                            NSApp.setActivationPolicy(.accessory)
                        }
                    }
                }
            }
        )
    }

    /// Animate a creature sprite from screen center up to the notch area, then set up the real panel.
    private func animateCreatureToNotch(completion: @escaping () -> Void) {
        guard let screen = preferredScreen(),
              let profile = UserProfile.current else {
            completion()
            return
        }
        let notchFrame = screen.effectiveNotchFrame

        // Create a small borderless window with the creature
        let spriteSize: CGFloat = 48
        let startFrame = NSRect(
            x: screen.frame.midX - spriteSize / 2,
            y: screen.frame.midY - spriteSize / 2,
            width: spriteSize,
            height: spriteSize
        )

        let flyWindow = NSWindow(
            contentRect: startFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        flyWindow.isOpaque = false
        flyWindow.backgroundColor = .clear
        flyWindow.level = .floating
        flyWindow.hasShadow = false

        let creatureView = PixelCreatureView(
            type: profile.creatureType,
            frame: 0,
            task: .idle,
            emotion: .happy,
            colorPreset: profile.colorPreset,
            accessory: profile.accessory
        )
        flyWindow.contentView = NSHostingView(rootView: creatureView.frame(width: spriteSize, height: spriteSize))
        flyWindow.orderFrontRegardless()

        // Target: shrink to creature size and land at notch
        let endSize: CGFloat = 12
        let endFrame = NSRect(
            x: notchFrame.midX - endSize / 2,
            y: notchFrame.midY - endSize / 2,
            width: endSize,
            height: endSize
        )

        // Animate: fly up, shrink, and fade
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.5
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            flyWindow.animator().setFrame(endFrame, display: true)
            flyWindow.animator().alphaValue = 0.0
        }, completionHandler: {
            flyWindow.close()
            completion()
        })
    }

    @objc private func changeCreature() {
        if windowCoordinator.isOpen("onboarding") {
            showOnboarding()
            return
        }
        notchPanel?.close()
        notchPanel = nil

        var didComplete = false
        windowCoordinator.show(
            key: "onboarding",
            title: "Welcome to Clautch",
            size: NSSize(width: 440, height: 600),
            content: {
                OnboardingView { [weak self] _ in
                    didComplete = true
                    DispatchQueue.main.async {
                        self?.rebuildMenu()
                        self?.windowCoordinator.suppressAccessoryTransition = true
                        self?.windowCoordinator.close(key: "onboarding")
                        self?.animateCreatureToNotch {
                            self?.setupNotchPanel()
                            NSApp.setActivationPolicy(.accessory)
                        }
                    }
                }
            },
            onClose: { [weak self] in
                // Dismissed without completing — restore the panel
                if !didComplete {
                    self?.setupNotchPanel()
                }
            }
        )
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

    @objc private func showAchievementsWindow() {
        windowCoordinator.show(
            key: "achievements",
            title: "Clautch Achievements",
            size: NSSize(width: 400, height: 500),
            minSize: NSSize(width: 360, height: 400),
            resizable: true,
            autosaveName: "ClautchAchievements",
            content: { AchievementsView() }
        )
    }

    @objc private func showMoodJournal() {
        windowCoordinator.show(
            key: "moodJournal",
            title: "Mood Journal",
            size: NSSize(width: 380, height: 380),
            minSize: NSSize(width: 340, height: 320),
            resizable: true,
            autosaveName: "ClautchMoodJournal",
            content: { MoodJournalView() }
        )
    }

    @objc private func showShareCard() {
        windowCoordinator.show(
            key: "shareCard",
            title: "Creature Card",
            size: NSSize(width: 440, height: 560),
            minSize: NSSize(width: 420, height: 520),
            resizable: false,
            autosaveName: "ClautchShareCard",
            content: { ShareCardView() }
        )
    }

    // MARK: - Notch Panel

    private static let preferredScreenKey = "com.clautch.preferredScreen"

    /// Find the preferred screen: user's saved choice, notch screens first, then any screen.
    private func preferredScreen() -> NSScreen? {
        if let savedId = UserDefaults.standard.string(forKey: Self.preferredScreenKey),
           let match = NSScreen.screens.first(where: { $0.localizedName == savedId }) {
            return match
        }
        // Prefer notch screens, fall back to primary display
        return NSScreen.screens.first(where: { $0.hasNotch }) ?? NSScreen.main ?? NSScreen.screens.first
    }

    private func setupNotchPanel() {
        NSApp.setActivationPolicy(.accessory)

        guard let screen = preferredScreen() else {
            logger.info("No screen available for panel")
            return
        }

        let panel = NotchPanel(screen: screen)
        let contentView = NotchContentView()
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.layer?.backgroundColor = .clear

        let hitTestView = NotchHitTestView(hostingView: hostingView)
        hitTestView.notchHeight = screen.effectiveNotchHeight
        hitTestView.isExpanded = NotchHoverState.shared.isHovered
        hitTestView.onClicked = { [weak self, weak hitTestView] in
            let expanding = !NotchHoverState.shared.isHovered
            hitTestView?.isExpanded = expanding
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                NotchHoverState.shared.isHovered = expanding
            }
            // Collapsed: lower window level so it doesn't block other windows below the notch
            // Expanded: raise to shielding level so the panel floats above everything
            self?.notchPanel?.level = expanding
                ? NSWindow.Level(rawValue: Int(CGShieldingWindowLevel()))
                : .statusBar
            NSSound(named: expanding ? "Pop" : "Tink")?.play()
        }
        panel.contentView = hitTestView
        // Start at appropriate level
        if !NotchHoverState.shared.isHovered {
            panel.level = .statusBar
        }
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

    @objc private func preferredScreenChanged() {
        let wasExpanded = NotchHoverState.shared.isHovered
        notchPanel?.close()
        notchPanel = nil
        setupNotchPanel()
        NotchHoverState.shared.isHovered = wasExpanded
        logger.info("Panel moved to preferred screen")
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
    }

    private func rebuildMenu() {
        let menu = NSMenu()
        menu.delegate = self
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

        // ── Header ──
        if let profile = UserProfile.current {
            let evo = GamificationStore.shared.evolution
            let evoLabel = evo == .baby ? "" : " (\(evo.displayName))"
            let profileItem = NSMenuItem(
                title: "\(profile.creatureType.displayName)\(evoLabel) — \(profile.displayName)",
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

        let achievementsItem = NSMenuItem(title: "Achievements…", action: #selector(showAchievementsWindow), keyEquivalent: "")
        achievementsItem.target = self
        menu.addItem(achievementsItem)

        let journalItem = NSMenuItem(title: "Mood Journal…", action: #selector(showMoodJournal), keyEquivalent: "")
        journalItem.target = self
        menu.addItem(journalItem)

        let shareItem = NSMenuItem(title: "Share Creature Card…", action: #selector(showShareCard), keyEquivalent: "")
        shareItem.target = self
        menu.addItem(shareItem)

        let changeItem = NSMenuItem(title: "Change Creature…", action: #selector(changeCreature), keyEquivalent: "")
        changeItem.target = self
        menu.addItem(changeItem)

        // ── Display ──
        let allScreens = NSScreen.screens
        if allScreens.count > 1 {
            menu.addItem(.separator())
            let displayItem = NSMenuItem(title: "Display", action: nil, keyEquivalent: "")
            displayItem.tag = 850
            let displayMenu = NSMenu()
            for screen in allScreens {
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
        updaterController.checkForUpdates(nil)
        // Sparkle creates its own window — bring app to front after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NSApp.activate(ignoringOtherApps: true)
            // Center Sparkle's window if it appeared
            if let sparkleWindow = NSApp.windows.first(where: {
                $0.isVisible && $0.title.contains("Software Update")
            }) {
                sparkleWindow.center()
                sparkleWindow.makeKeyAndOrderFront(nil)
            }
        }
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
            RoomManager.shared.pauseSync()
            Task { @MainActor in
                SessionStats.shared.stopTracking()
            }
            logger.info("Clautch paused")
        } else {
            SocketServer.shared.start()
            setupNotchPanel()
            startSessionBadgeTimer()
            RoomManager.shared.resumeSync()
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
        windowCoordinator.show(
            key: "settings",
            title: "Clautch Settings",
            size: NSSize(width: 440, height: 380),
            autosaveName: "ClautchSettings",
            content: { SettingsView() }
        )
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
            let quests = GamificationStore.shared
            let questStr = "Quests: \(quests.completedQuestCount)/\(quests.dailyQuests.count)"
            statsItem.title = "\(today) today · \(week) this week · \(questStr)"
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
