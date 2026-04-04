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

    var body: some View {
        HStack(spacing: 6) {
            let task = stateMachine.sessionStore.effectiveSession?.state.task ?? .idle
            let emotion = stateMachine.sessionStore.effectiveSession?.state.emotion ?? .neutral

            HStack(spacing: 3) {
                Circle()
                    .fill(taskColor(task))
                    .frame(width: 4, height: 4)
                Text(task.displayLabel)
                    .font(.system(size: 6, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
            }

            if emotion != .neutral {
                Text(emotionLabel(emotion))
                    .font(.system(size: 5, weight: .medium))
                    .foregroundStyle(emotionColor(emotion).opacity(0.7))
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

    private func emotionLabel(_ emotion: CreatureEmotion) -> String {
        switch emotion {
        case .happy:      return "happy"
        case .sad:        return "sad"
        case .frustrated: return "frustrated"
        case .excited:    return "excited!"
        case .confused:   return "confused"
        case .tired:      return "tired"
        case .neutral:    return ""
        }
    }

    private func emotionColor(_ emotion: CreatureEmotion) -> Color {
        switch emotion {
        case .happy, .excited: return .green
        case .sad:             return .blue
        case .frustrated:      return .red
        case .confused:        return .yellow
        case .tired:           return .purple
        case .neutral:         return .gray
        }
    }
}
