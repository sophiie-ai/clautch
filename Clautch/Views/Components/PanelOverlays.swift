import SwiftUI

// MARK: - Event Log Overlay

struct EventLogOverlay: View {
    @State private var feed = ActivityFeed.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(feed.items.prefix(4)) { item in
                HStack(spacing: 4) {
                    Text(item.text)
                        .font(.system(size: 7, design: .monospaced))
                        .lineLimit(1)
                    Spacer()
                    Text(item.timeAgo)
                        .font(.system(size: 6))
                        .foregroundStyle(.white.opacity(0.3))
                }
                .foregroundStyle(.white.opacity(0.55))
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(item.text), \(item.timeAgo) ago")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Activity log")
    }
}

// MARK: - Status Bar Overlay

struct StatusBarOverlay: View {
    @State private var stateMachine = StateMachine.shared
    @State private var stats = SessionStats.shared
    @State private var gamification = GamificationStore.shared

    var body: some View {
        HStack(spacing: 6) {
            let task = stateMachine.sessionStore.effectiveSession?.state.task ?? .idle
            HStack(spacing: 3) {
                Circle()
                    .fill(taskColor(task))
                    .frame(width: 4, height: 4)
                Text(task.displayLabel)
                    .font(.system(size: 6, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Status expiry countdown
            if let status = stateMachine.activeStatus, !status.isExpired {
                TimelineView(.periodic(from: .now, by: 60)) { _ in
                    let remaining = status.expiresAt.timeIntervalSinceNow
                    let label = remaining < 3600
                        ? "\(Int(remaining / 60))m"
                        : "\(Int(remaining / 3600))h\(Int(remaining.truncatingRemainder(dividingBy: 3600) / 60))m"
                    Text("\(status.displayEmoji) \(label)")
                        .font(.system(size: 6, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(remaining < 600 ? 0.7 : 0.45))
                }
            }

            if gamification.streak.currentStreak > 0 {
                StreakIndicator(count: gamification.streak.currentStreak)
            }

            Spacer()

            Text("\(SessionStats.format(stats.todayTotal))")
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))

            Text("·")
                .font(.system(size: 7))
                .foregroundStyle(.white.opacity(0.2))

            Text("Wk: \(SessionStats.format(stats.weekTotal))")
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.4))

            Text("·")
                .font(.system(size: 7))
                .foregroundStyle(.white.opacity(0.2))

            Text("Resets \(SessionStats.weekResetLabel)")
                .font(.system(size: 7, weight: .medium, design: .monospaced))
                .foregroundStyle(.white.opacity(0.3))
        }
    }

    private func taskColor(_ task: CreatureTask) -> Color {
        switch task {
        case .idle:       return .gray
        case .working:    return .cyan
        case .thinking:   return .yellow
        case .sleeping:   return .purple
        case .compacting: return .red
        }
    }

}
