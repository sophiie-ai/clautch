import SwiftUI

/// Mood journal showing daily emotion timeline and summary stats.
struct MoodJournalView: View {
    @State private var stats = SessionStats.shared
    @State private var selectedDate: String

    init() {
        let today = SessionStats.dateKey(for: Date())
        _selectedDate = State(initialValue: today)
    }

    private var samples: [SessionStats.MoodSample] {
        stats.dailyMoodHistory[selectedDate] ?? []
    }

    private var summary: SessionStats.MoodJournalSummary {
        stats.journalSummary(for: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with date picker
            HStack {
                Text("Mood Journal")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                dayPicker
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            if samples.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text("No mood data")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Start a Claude Code session to begin tracking")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Creature mood illustration + dominant mood
                        dominantMoodHeader
                            .padding(.top, 16)

                        // Timeline strip
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Timeline")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            MoodTimeline(samples: samples)
                                .frame(height: 40)
                        }

                        // Summary cards
                        summaryGrid

                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .frame(minWidth: 360, minHeight: 340)
    }

    // MARK: - Components

    private var dayPicker: some View {
        HStack(spacing: 8) {
            Button(action: { navigateDay(-1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(previousDate == nil)

            Text(formattedDate(selectedDate))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.secondary)
                .frame(minWidth: 80)

            Button(action: { navigateDay(1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
            }
            .buttonStyle(.plain)
            .disabled(selectedDate >= SessionStats.dateKey(for: Date()))
        }
    }

    private var dominantMoodHeader: some View {
        HStack(spacing: 12) {
            // Creature preview showing dominant mood
            if let profile = UserProfile.current {
                PixelCreatureView(
                    type: profile.creatureType,
                    frame: 0,
                    task: .idle,
                    emotion: CreatureEmotion(rawValue: summary.dominantMood) ?? .neutral,
                    colorPreset: profile.colorPreset,
                    accessory: profile.accessory
                )
                .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Dominant Mood")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(moodColor(summary.dominantMood))
                        .frame(width: 8, height: 8)
                    Text(summary.dominantMood.capitalized)
                        .font(.system(size: 16, weight: .semibold))
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Active Time")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text(SessionStats.format(summary.activeTime))
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }

    private var summaryGrid: some View {
        HStack(spacing: 12) {
            summaryCard(title: "Mood Shifts", value: "\(summary.moodShifts)", icon: "arrow.triangle.swap")
            summaryCard(title: "Longest Streak", value: "\(summary.longestMoodStreak)", icon: "flame")
            summaryCard(title: "Samples", value: "\(summary.sampleCount)", icon: "chart.dots.scatter")
        }
    }

    private func summaryCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }

    // MARK: - Navigation

    private var previousDate: String? {
        let available = stats.journalDates // sorted most recent first
        guard let idx = available.firstIndex(of: selectedDate), idx + 1 < available.count else { return nil }
        return available[idx + 1]
    }

    private func navigateDay(_ offset: Int) {
        let cal = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let current = formatter.date(from: selectedDate),
              let next = cal.date(byAdding: .day, value: offset, to: current) else { return }
        let nextKey = SessionStats.dateKey(for: next)
        let today = SessionStats.dateKey(for: Date())
        if nextKey <= today {
            selectedDate = nextKey
        }
    }

    private func formattedDate(_ key: String) -> String {
        let today = SessionStats.dateKey(for: Date())
        if key == today { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: key) else { return key }
        let display = DateFormatter()
        display.dateFormat = "MMM d"
        return display.string(from: date)
    }

    // MARK: - Colors

    static func moodColor(_ emotion: String) -> Color {
        switch emotion {
        case "happy":      return .green
        case "excited":    return Color(red: 0.3, green: 0.9, blue: 0.3)
        case "neutral":    return .yellow
        case "confused":   return .purple
        case "tired":      return .gray
        case "sad":        return .blue
        case "frustrated": return .red
        default:           return .yellow
        }
    }

    private func moodColor(_ emotion: String) -> Color {
        Self.moodColor(emotion)
    }
}

// MARK: - Mood Timeline

/// Horizontal timeline showing colored emotion bands across the day.
struct MoodTimeline: View {
    let samples: [SessionStats.MoodSample]

    var body: some View {
        Canvas { ctx, size in
            guard !samples.isEmpty else { return }
            let w = size.width
            let h = size.height

            // Determine time range
            guard let first = samples.first?.timestamp,
                  let last = samples.last?.timestamp else { return }
            let range = max(last.timeIntervalSince(first), 1)

            // Draw emotion bands
            for i in 0..<samples.count {
                let start = samples[i].timestamp.timeIntervalSince(first)
                let end = i + 1 < samples.count
                    ? samples[i + 1].timestamp.timeIntervalSince(first)
                    : range
                let x = CGFloat(start / range) * w
                let bandW = max(CGFloat((end - start) / range) * w, 1)
                let color = MoodJournalView.moodColor(samples[i].emotion)
                ctx.fill(
                    Path(CGRect(x: x, y: 4, width: bandW, height: h - 8)),
                    with: .color(color.opacity(0.6))
                )
            }

            // Time labels at start and end
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            let startText = Text(timeFormatter.string(from: first))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.secondary)
            ctx.draw(ctx.resolve(startText), at: CGPoint(x: 16, y: h - 1), anchor: .bottom)

            let endText = Text(timeFormatter.string(from: last))
                .font(.system(size: 8, design: .monospaced))
                .foregroundStyle(.secondary)
            ctx.draw(ctx.resolve(endText), at: CGPoint(x: w - 16, y: h - 1), anchor: .bottom)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
