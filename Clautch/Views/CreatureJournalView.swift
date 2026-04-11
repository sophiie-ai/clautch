import SwiftUI

/// Creature life journal showing a timeline of significant events.
struct CreatureJournalView: View {
    @State private var journal = JournalStore.shared
    @State private var gamification = GamificationStore.shared
    @State private var personalityEngine = PersonalityEngine.shared
    @State private var stats = SessionStats.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Creature Journal")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text("\(journal.entries.count) entries")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            if journal.entries.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Text("No journal entries yet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                    Text("Your creature's story will unfold as you code")
                        .font(.system(size: 12))
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Summary header
                        summaryHeader
                            .padding(.top, 16)

                        // Timeline entries grouped by date
                        ForEach(journal.entriesByDate, id: \.date) { group in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(formattedDate(group.date))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                ForEach(group.entries) { entry in
                                    entryRow(entry)
                                }
                            }
                        }

                        Spacer(minLength: 8)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .frame(minWidth: 380, minHeight: 420)
    }

    // MARK: - Summary Header

    private var summaryHeader: some View {
        HStack(spacing: 12) {
            // Creature preview
            if let profile = UserProfile.current {
                PixelCreatureView(
                    type: profile.creatureType,
                    frame: 0,
                    task: .idle,
                    emotion: .neutral,
                    colorPreset: profile.colorPreset,
                    accessory: profile.accessory
                )
                .frame(width: 36, height: 36)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(UserProfile.current?.displayName ?? "Your Creature")
                    .font(.system(size: 14, weight: .semibold))
                HStack(spacing: 6) {
                    Text(gamification.evolution.displayName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                    if let trait = personalityEngine.personality.dominantTrait {
                        Text("\(trait.emoji) \(trait.displayName)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("Age")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("\(journal.creatureAgeDays)d")
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
            }
        }
        .padding(12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }

    // MARK: - Entry Row

    private func entryRow(_ entry: JournalEntry) -> some View {
        let mood = moodAtTime(entry.date)
        return HStack(spacing: 10) {
            Text(entry.type.icon)
                .font(.system(size: 14))
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                if let detail = entry.detail {
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Mood at time of event
            if let mood {
                Circle()
                    .fill(MoodJournalView.moodColor(mood))
                    .frame(width: 5, height: 5)
                    .help("Mood: \(mood)")
            }

            Text(timeString(entry.date))
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.02))
        .cornerRadius(8)
    }

    /// Find the creature's mood closest to the given time.
    private func moodAtTime(_ date: Date) -> String? {
        let dateKey = SessionStats.dateKey(for: date)
        guard let samples = stats.dailyMoodHistory[dateKey], !samples.isEmpty else { return nil }
        // Find the sample closest to the entry time
        return samples
            .min(by: { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) })?
            .emotion
    }

    // MARK: - Formatting

    private func formattedDate(_ key: String) -> String {
        let today = SessionStats.dateKey(for: Date())
        if key == today { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: key) else { return key }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        if key == SessionStats.dateKey(for: yesterday) { return "Yesterday" }
        let display = DateFormatter()
        display.dateFormat = "EEEE, MMM d"
        return display.string(from: date)
    }

    private func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
