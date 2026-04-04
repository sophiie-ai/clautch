import SwiftUI

/// Tiny pixel-art flame for the status bar overlay, showing the current streak count.
struct StreakIndicator: View {
    let count: Int

    var body: some View {
        HStack(spacing: 2) {
            PixelFlame(intensity: flameIntensity)
                .frame(width: 5, height: 7)
            Text("\(count)")
                .font(.system(size: 7, weight: .bold, design: .monospaced))
        }
        .foregroundStyle(flameColor.opacity(0.8))
    }

    private var flameIntensity: Int {
        if count >= 30 { return 4 }
        if count >= 14 { return 3 }
        if count >= 7  { return 2 }
        if count >= 3  { return 1 }
        return 0
    }

    private var flameColor: Color {
        switch flameIntensity {
        case 4:  return .yellow
        case 3:  return Color(red: 1.0, green: 0.8, blue: 0.1)
        case 2:  return Color(red: 1.0, green: 0.6, blue: 0.0)
        case 1:  return .orange
        default: return Color(red: 1.0, green: 0.5, blue: 0.0)
        }
    }
}

/// 3x5 pixel flame rendered with Canvas.
struct PixelFlame: View {
    let intensity: Int

    // Flames get taller/brighter with intensity
    private var grid: [[Int]] {
        if intensity >= 3 {
            return [
                [0,2,0],
                [2,1,2],
                [1,1,1],
                [1,1,1],
                [0,1,0],
            ]
        } else if intensity >= 1 {
            return [
                [0,0,0],
                [0,2,0],
                [2,1,2],
                [1,1,1],
                [0,1,0],
            ]
        } else {
            return [
                [0,0,0],
                [0,0,0],
                [0,2,0],
                [1,1,1],
                [0,1,0],
            ]
        }
    }

    var body: some View {
        Canvas { ctx, size in
            let rows = grid.count
            let cols = grid.first?.count ?? 3
            let px = min(size.width / CGFloat(cols), size.height / CGFloat(rows))

            for (r, row) in grid.enumerated() {
                for (c, cell) in row.enumerated() {
                    guard cell != 0 else { continue }
                    let rect = CGRect(
                        x: CGFloat(c) * px, y: CGFloat(r) * px,
                        width: px + 0.5, height: px + 0.5
                    )
                    let color: Color = cell == 1
                        ? Color(red: 1.0, green: 0.5, blue: 0.0)
                        : Color(red: 1.0, green: 0.85, blue: 0.2)
                    ctx.fill(Path(rect), with: .color(color))
                }
            }
        }
    }
}
