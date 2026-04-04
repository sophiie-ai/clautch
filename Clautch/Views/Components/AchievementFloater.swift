import SwiftUI

/// Celebration animation that floats up from the creature when an achievement is unlocked.
/// Follows the same pattern as ReactionFloater in CreatureIslandOverlay.
struct AchievementFloater: View {
    let achievementId: AchievementId
    var onComplete: (() -> Void)?

    @State private var floatOffset: CGFloat = 0
    @State private var opacity: Double = 1.0
    @State private var scale: CGFloat = 0.3

    var body: some View {
        VStack(spacing: 2) {
            // Pixel art badge
            Canvas { ctx, size in
                let grid = achievementId.pixels
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
                        let color = cell == 1 ? achievementId.primaryColor : achievementId.secondaryColor
                        ctx.fill(Path(rect), with: .color(color))
                    }
                }
            }
            .frame(width: 15, height: 15)

            // Title bubble
            Text(achievementId.title)
                .font(.system(size: 6, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill(achievementId.primaryColor.opacity(0.8))
                )
        }
        .scaleEffect(scale)
        .offset(y: floatOffset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: 3.0)) {
                floatOffset = -20
            }
            withAnimation(.easeIn(duration: 1.0).delay(2.0)) {
                opacity = 0
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(3))
                onComplete?()
            }
        }
    }
}
