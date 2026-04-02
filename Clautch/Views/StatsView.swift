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

            Spacer()
        }
        .frame(width: 360, height: 320)
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

        return HStack(alignment: .bottom, spacing: 6) {
            ForEach(Array(days.enumerated()), id: \.offset) { _, day in
                VStack(spacing: 4) {
                    // Duration label
                    if day.seconds > 0 {
                        Text(SessionStats.format(day.seconds))
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }

                    // Bar
                    RoundedRectangle(cornerRadius: 3)
                        .fill(day.seconds > 0 ? Color.accentColor : Color.primary.opacity(0.08))
                        .frame(height: max(day.seconds > 0 ? CGFloat(day.seconds / maxSeconds) * 100 : 4, 4))

                    // Day label
                    Text(day.label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 140)
    }
}
