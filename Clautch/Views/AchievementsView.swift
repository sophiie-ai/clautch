import SwiftUI

/// Achievements gallery window — shows streak info and all achievement badges.
struct AchievementsView: View {
    @State private var gamification = GamificationStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Achievements")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text("\(gamification.earnedAchievements.count)/\(AchievementId.allCases.count)")
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    dailyQuestsSection
                    evolutionSection
                    streakSection
                    achievementsGrid
                }
                .padding(20)
            }
        }
        .frame(minWidth: 360, minHeight: 400)
    }

    // MARK: - Daily Quests Section

    private var dailyQuestsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Daily Quests")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer()
                Text("\(gamification.completedQuestCount)/\(gamification.dailyQuests.count)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            if gamification.dailyQuests.isEmpty {
                Text("Quests will appear when you start coding")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .padding(.vertical, 4)
            } else {
                ForEach(gamification.dailyQuests) { quest in
                    HStack(spacing: 10) {
                        Image(systemName: quest.completed ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 14))
                            .foregroundStyle(quest.completed ? .green : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(quest.title)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(quest.completed ? .secondary : .primary)
                                .strikethrough(quest.completed)

                            GeometryReader { geo in
                                let progress = quest.target > 0 ? min(CGFloat(quest.progress) / CGFloat(quest.target), 1.0) : 0
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.primary.opacity(0.06))
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(quest.completed ? Color.green.opacity(0.5) : Color.accentColor.opacity(0.6))
                                        .frame(width: geo.size.width * progress)
                                }
                            }
                            .frame(height: 3)
                        }

                        Text("\(quest.progress)/\(quest.target)")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }

    // MARK: - Evolution Section

    private var evolutionSection: some View {
        let evo = gamification.evolution
        let xp = gamification.xp
        let nextThreshold = evo.nextThreshold
        let progress: Double = if let next = nextThreshold {
            Double(xp - evo.xpThreshold) / Double(next - evo.xpThreshold)
        } else {
            1.0
        }

        return VStack(spacing: 8) {
            HStack {
                Text(evo.displayName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(evo.glowColor == .clear ? .primary : evo.glowColor)
                Spacer()
                if let next = nextThreshold {
                    Text("\(xp) / \(next) XP")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Text("\(xp) XP — Max Level")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            // XP progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [evo.glowColor == .clear ? .accentColor : evo.glowColor,
                                         evo.glowColor == .clear ? .accentColor.opacity(0.6) : evo.glowColor.opacity(0.6)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * min(max(progress, 0), 1))
                }
            }
            .frame(height: 6)

            // Stage labels
            HStack(spacing: 0) {
                ForEach(CreatureEvolution.allCases, id: \.rawValue) { stage in
                    Text(stage.displayName)
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(evo == stage ? .primary : .tertiary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Current streak
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        PixelFlame(intensity: flameIntensity)
                            .frame(width: 14, height: 20)
                        Text("\(gamification.streak.currentStreak)")
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                    Text("Current Streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                // Best streak
                VStack(spacing: 4) {
                    Text("\(gamification.streak.longestStreak)")
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundStyle(.primary.opacity(0.6))
                    Text("Best Streak")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Week calendar dots
            weekCalendar
        }
        .padding(16)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }

    private var flameIntensity: Int {
        let s = gamification.streak.currentStreak
        if s >= 30 { return 4 }
        if s >= 14 { return 3 }
        if s >= 7  { return 2 }
        if s >= 3  { return 1 }
        return 0
    }

    /// Last 7 days as colored dots — filled if a session was recorded that day.
    private var weekCalendar: some View {
        let calendar = Calendar.current
        let today = Date()
        let days: [(String, Bool)] = (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let key = SessionStats.dateKey(for: day)
            let hasData = SessionStats.shared.dailyTotals[key] != nil
                && (SessionStats.shared.dailyTotals[key] ?? 0) > 0
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE"
            return (fmt.string(from: day), hasData)
        }

        return HStack(spacing: 8) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 4) {
                    Circle()
                        .fill(day.1 ? Color.orange : Color.primary.opacity(0.1))
                        .frame(width: 8, height: 8)
                    Text(day.0)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Achievements Grid

    private var achievementsGrid: some View {
        let columns = [GridItem(.adaptive(minimum: 80), spacing: 12)]

        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(AchievementId.allCases) { achievement in
                achievementCard(achievement)
            }
        }
    }

    private func achievementCard(_ id: AchievementId) -> some View {
        let earned = gamification.isEarned(id)
        let record = gamification.earnedAchievements.first { $0.achievementId == id }

        return VStack(spacing: 6) {
            // Pixel art badge
            Canvas { ctx, size in
                let grid = id.pixels
                let rows = grid.count
                let cols = grid.first?.count ?? 5
                let px = min(size.width / CGFloat(cols), size.height / CGFloat(rows))

                for (r, row) in grid.enumerated() {
                    for (c, cell) in row.enumerated() {
                        guard cell != 0 else { continue }
                        let rect = CGRect(
                            x: CGFloat(c) * px, y: CGFloat(r) * px,
                            width: px + 0.5, height: px + 0.5
                        )
                        let color: Color
                        if earned {
                            color = cell == 1 ? id.primaryColor : id.secondaryColor
                        } else {
                            color = Color.primary.opacity(0.15)
                        }
                        ctx.fill(Path(rect), with: .color(color))
                    }
                }
            }
            .frame(width: 30, height: 30)

            // Title
            Text(earned ? id.title : "???")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(earned ? .primary : .secondary)
                .lineLimit(1)

            // Description or date
            if earned, let record {
                Text(record.earnedAt.formatted(.dateTime.month(.abbreviated).day()))
                    .font(.system(size: 7, weight: .medium))
                    .foregroundStyle(.secondary)
            } else {
                Text(id.description)
                    .font(.system(size: 7))
                    .foregroundStyle(.tertiary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(earned ? id.primaryColor.opacity(0.08) : Color.primary.opacity(0.02))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(earned ? id.primaryColor.opacity(0.2) : Color.clear, lineWidth: 1)
        )
        .help(earned ? id.description : "Locked: \(id.description)")
    }
}
