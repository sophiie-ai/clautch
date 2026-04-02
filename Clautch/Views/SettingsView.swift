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

            DisplaySettingsTab()
                .tabItem {
                    Label("Display", systemImage: "rectangle.inset.filled")
                }

            NotificationsSettingsTab()
                .tabItem {
                    Label("Notifications", systemImage: "bell")
                }
        }
        .frame(width: 400, height: 260)
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
