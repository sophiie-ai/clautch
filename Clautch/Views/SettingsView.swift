import SwiftUI
import ServiceManagement

extension Notification.Name {
    static let clautchPreferredScreenChanged = Notification.Name("com.clautch.preferredScreenChanged")
}

/// macOS Settings window with tabbed preferences using a toolbar-style tab bar.
struct SettingsView: View {
    @State private var selectedTab = 0

    private let tabs: [(String, String)] = [
        ("General", "gearshape"),
        ("Appearance", "paintbrush"),
        ("Display", "rectangle.inset.filled"),
        ("Notifications", "bell"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                    VStack(spacing: 4) {
                        Image(systemName: tab.1)
                            .font(.system(size: 16))
                        Text(tab.0)
                            .font(.system(size: 10))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
                    .background(selectedTab == index ? Color.accentColor.opacity(0.12) : Color.clear)
                    .foregroundStyle(selectedTab == index ? Color.accentColor : .secondary)
                    .onTapGesture { selectedTab = index }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)

            Divider()
                .padding(.top, 4)

            // Tab content
            Group {
                switch selectedTab {
                case 0: GeneralSettingsTab()
                case 1: AppearanceSettingsTab()
                case 2: DisplaySettingsTab()
                case 3: NotificationsSettingsTab()
                default: EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 440, height: 380)
    }
}

// MARK: - Appearance

private struct AppearanceSettingsTab: View {
    @State private var selectedType: CreatureType = UserProfile.current?.creatureType ?? .ghost
    @State private var colorPreset: CreatureColorPreset = UserProfile.current?.colorPreset ?? .none
    @State private var accessory: CreatureAccessory = UserProfile.current?.accessory ?? .none
    @State private var displayName: String = UserProfile.current?.displayName ?? ""

    var body: some View {
        Form {
            Section("Creature") {
                HStack(spacing: 16) {
                    // Live preview
                    TimelineView(.animation(minimumInterval: 1.0 / 4)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        let frame = Int(t * 3) % max(selectedType.frames.count, 1)
                        PixelCreatureView(
                            type: selectedType,
                            frame: frame,
                            task: .idle,
                            emotion: .neutral,
                            colorPreset: colorPreset,
                            accessory: accessory
                        )
                        .frame(width: 40, height: 40)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Picker("Type", selection: $selectedType) {
                            ForEach(CreatureType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Color", selection: $colorPreset) {
                            ForEach(CreatureColorPreset.allCases) { preset in
                                Text(preset == .none ? "Default" : preset.rawValue.capitalized).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)

                        Picker("Accessory", selection: $accessory) {
                            ForEach(CreatureAccessory.allCases) { acc in
                                Text(acc == .none ? "None" : "\(acc.emoji) \(acc.rawValue.capitalized)").tag(acc)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }

            Section("Profile") {
                TextField("Display Name", text: $displayName)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
        .onChange(of: selectedType) { _, _ in saveProfile() }
        .onChange(of: colorPreset) { _, _ in saveProfile() }
        .onChange(of: accessory) { _, _ in saveProfile() }
        .onChange(of: displayName) { _, newValue in
            if !newValue.trimmingCharacters(in: .whitespaces).isEmpty {
                saveProfile()
            }
        }
    }

    private func saveProfile() {
        let name = displayName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let peerId = UserProfile.current?.peerId ?? UUID().uuidString
        UserProfile.current = UserProfile(
            peerId: peerId,
            displayName: name,
            creatureType: selectedType,
            colorPreset: colorPreset,
            accessory: accessory
        )
    }
}

// MARK: - General

private struct GeneralSettingsTab: View {
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var settings = AnimationSettings.shared

    var body: some View {
        Form {
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = SMAppService.mainApp.status == .enabled
                    }
                }

            Toggle("Pause Clautch", isOn: $settings.isPaused)
                .help("Hides the notch panel and pauses all processing to save CPU")

        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}

// MARK: - Display

private struct DisplaySettingsTab: View {
    @State private var settings = AnimationSettings.shared
    @AppStorage("com.clautch.preferredScreen") private var preferredScreen = ""
    @State private var availableScreens: [ScreenInfo] = []

    struct ScreenInfo: Identifiable, Hashable {
        let id: String  // localizedName
        let name: String
        let hasNotch: Bool
        let resolution: String
    }

    var body: some View {
        Form {
            Section("Screen") {
                if availableScreens.isEmpty {
                    Text("No screens with a notch detected")
                        .foregroundStyle(.secondary)
                } else if availableScreens.count == 1 {
                    HStack {
                        Label(availableScreens[0].name, systemImage: "display")
                        Spacer()
                        Text(availableScreens[0].resolution)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Picker("Display", selection: $preferredScreen) {
                        ForEach(availableScreens) { screen in
                            HStack {
                                Text(screen.name)
                                Text(screen.resolution)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(screen.id)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    .onChange(of: preferredScreen) { _, _ in
                        // Notify AppDelegate to recreate the panel on the new screen
                        NotificationCenter.default.post(
                            name: .clautchPreferredScreenChanged,
                            object: nil
                        )
                    }
                }
            }

            Section("Panel") {
                Toggle("Show Event Log", isOn: $settings.showEventLog)
                    .help("Show recent activity events in the expanded panel")

                Toggle("Show Status Bar", isOn: $settings.showStatusBar)
                    .help("Show task, emotion, and usage stats at the bottom of the panel")
            }

            Section("Collapsed Mode") {
                Toggle("Reduce Animation When Collapsed", isOn: $settings.reduceAnimationWhenCollapsed)
                    .help("Lower animation frame rate when the panel is collapsed")

                Toggle("Hide When Collapsed", isOn: $settings.hideWhenCollapsed)
                    .help("Completely hide the creature below the notch until clicked")
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
        .onAppear { refreshScreens() }
    }

    private func refreshScreens() {
        availableScreens = NSScreen.screens.filter { $0.hasNotch }.map { screen in
            let w = Int(screen.frame.width)
            let h = Int(screen.frame.height)
            return ScreenInfo(
                id: screen.localizedName,
                name: screen.localizedName,
                hasNotch: screen.hasNotch,
                resolution: "\(w)×\(h)"
            )
        }
        // If no preference set, default to first screen
        if preferredScreen.isEmpty, let first = availableScreens.first {
            preferredScreen = first.id
        }
    }
}

// MARK: - Notifications

private struct NotificationsSettingsTab: View {
    @AppStorage("com.clautch.notificationsEnabled") private var notificationsEnabled = false
    @AppStorage("com.clautch.soundEffects") private var soundEffects = false

    var body: some View {
        Form {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .help("Show macOS notifications for session events, errors, and peer messages")

            Toggle("Sound Effects", isOn: $soundEffects)
                .help("Play subtle sounds when peers join, leave, send reactions, or chat")

            if notificationsEnabled || soundEffects {
                Text("Peer events trigger notifications and/or sounds when teammates interact in your room.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}
