import SwiftUI
import ServiceManagement

/// macOS Settings window with tabbed preferences.
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            AppearanceSettingsTab()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            DisplaySettingsTab()
                .tabItem {
                    Label("Display", systemImage: "rectangle.inset.filled")
                }

            NotificationsSettingsTab()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
        }
        .frame(width: 440, height: 340)
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

            Toggle("Animated Menu Bar Icon", isOn: $settings.menuBarCreature)
                .help("Show your creature as the menu bar icon instead of the default icon")
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}

// MARK: - Display

private struct DisplaySettingsTab: View {
    @State private var settings = AnimationSettings.shared

    var body: some View {
        Form {
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
    }
}

// MARK: - Notifications

private struct NotificationsSettingsTab: View {
    @AppStorage("com.clautch.notificationsEnabled") private var notificationsEnabled = false

    var body: some View {
        Form {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
                .help("Show macOS notifications for session events, errors, and peer messages")

            if notificationsEnabled {
                Text("You'll receive notifications for session completions, tool errors, and messages from room peers.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(.vertical, 8)
    }
}
