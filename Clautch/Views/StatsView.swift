import SwiftUI

/// Usage statistics window showing daily and weekly session time.
struct StatsView: View {
    @State private var stats = SessionStats.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Usage Stats")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Text("Resets \(SessionStats.weekResetLabel)")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Summary cards
            HStack(spacing: 12) {
                summaryCard(title: "Today", value: SessionStats.format(stats.todayTotal))
                summaryCard(title: "This Week", value: SessionStats.format(stats.weekTotal))
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            // Weekly bar chart
            VStack(alignment: .leading, spacing: 8) {
                Text("This Week")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                weeklyChart
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Mood sparkline
            if !stats.moodHistory.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mood")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)

                    MoodSparkline(samples: stats.moodHistory)
                        .frame(height: 30)

                    MoodLegend()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }

            Spacer()
        }
        .frame(minWidth: 320, minHeight: 280)
    }

    // MARK: - Components

    private func summaryCard(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(10)
    }

    private var weeklyChart: some View {
        let days = stats.weekDays
        let maxSeconds = max(days.map(\.seconds).max() ?? 1, 1)
        let todayIndex = Calendar.current.component(.weekday, from: Date()) // 1=Sun...7=Sat

        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                let isToday = index == adjustedTodayIndex(todayIndex, dayCount: days.count)
                VStack(spacing: 4) {
                    // Duration label
                    if day.seconds > 0 {
                        Text(SessionStats.format(day.seconds))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(isToday ? .primary : .secondary)
                    }

                    // Bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(isToday
                            ? Color.accentColor
                            : (day.seconds > 0 ? Color.accentColor.opacity(0.6) : Color.primary.opacity(0.08)))
                        .frame(height: max(day.seconds > 0 ? CGFloat(day.seconds / maxSeconds) * 100 : 4, 4))
                        .overlay(
                            isToday
                                ? RoundedRectangle(cornerRadius: 3)
                                    .strokeBorder(Color.accentColor, lineWidth: 1)
                                : nil
                        )

                    // Day label
                    Text(day.label)
                        .font(.system(size: 10, weight: isToday ? .bold : .medium))
                        .foregroundStyle(isToday ? .primary : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 140)
    }

    /// Map Calendar weekday (1=Sun) to the day array index (0=Mon typically).
    private func adjustedTodayIndex(_ weekday: Int, dayCount: Int) -> Int {
        // weekDays is Mon=0..Sun=6, Calendar weekday is Sun=1..Sat=7
        let mondayBased = (weekday + 5) % 7  // Mon=0..Sun=6
        return min(mondayBased, dayCount - 1)
    }
}

// MARK: - Mood Legend

/// Compact inline legend for mood colors used in sparklines and timelines.
struct MoodLegend: View {
    private static let items: [(String, Color)] = [
        ("Happy", .green),
        ("Neutral", .yellow),
        ("Sad", .blue),
        ("Frustrated", .red),
        ("Confused", .purple),
        ("Tired", .gray),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Self.items, id: \.0) { label, color in
                HStack(spacing: 3) {
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                    Text(label)
                        .font(.system(size: 8))
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Mood Sparkline

struct MoodSparkline: View {
    let samples: [SessionStats.MoodSample]

    var body: some View {
        Canvas { ctx, size in
            guard samples.count >= 2 else { return }
            let w = size.width
            let h = size.height
            let midY = h / 2

            // Draw baseline
            ctx.stroke(
                Path { p in p.move(to: CGPoint(x: 0, y: midY)); p.addLine(to: CGPoint(x: w, y: midY)) },
                with: .color(.primary.opacity(0.1)),
                lineWidth: 0.5
            )

            // Build sparkline path
            var path = Path()
            for (i, sample) in samples.enumerated() {
                let x = w * CGFloat(i) / CGFloat(samples.count - 1)
                let y = midY - CGFloat(sample.value) * (h / 2 - 2)
                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                else { path.addLine(to: CGPoint(x: x, y: y)) }
            }

            // Color based on latest mood
            let lastValue = samples.last?.value ?? 0
            let lineColor: Color = lastValue > 0.3 ? .green :
                                   lastValue < -0.3 ? .red : .yellow
            ctx.stroke(path, with: .color(lineColor.opacity(0.8)), lineWidth: 1.5)

            // Dots at each sample
            for (i, sample) in samples.enumerated() {
                let x = w * CGFloat(i) / CGFloat(samples.count - 1)
                let y = midY - CGFloat(sample.value) * (h / 2 - 2)
                ctx.fill(
                    Path(ellipseIn: CGRect(x: x - 1.5, y: y - 1.5, width: 3, height: 3)),
                    with: .color(lineColor.opacity(0.6))
                )
            }
        }
    }
}
