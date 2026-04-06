import SwiftUI
import AppKit

/// A shareable creature profile card with stats, rendered at export-friendly resolution.
struct ShareCardView: View {
    @State private var gamification = GamificationStore.shared
    @State private var stats = SessionStats.shared

    private var profile: UserProfile? { UserProfile.current }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Creature Card")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Spacer()
                Menu {
                    Button("Copy to Clipboard") { copyToClipboard() }
                    Button("Save as PNG…") { saveAsPNG() }
                    Button("Share…") { shareSheet() }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .medium))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()

            // Card preview
            cardContent
                .padding(20)

            Spacer(minLength: 0)
        }
        .frame(minWidth: 420, minHeight: 520)
    }

    // MARK: - Card Content (also used for export)

    private var cardContent: some View {
        ShareCardContent(
            creatureType: profile?.creatureType ?? .ghost,
            colorPreset: profile?.colorPreset ?? .none,
            accessory: profile?.accessory ?? .none,
            evolution: gamification.evolution,
            displayName: profile?.displayName ?? "Clautcher",
            xp: gamification.xp,
            streak: gamification.streak.currentStreak,
            longestStreak: gamification.streak.longestStreak,
            totalSessions: gamification.counters.totalSessions,
            achievementsEarned: gamification.earnedAchievements.count,
            achievementsTotal: AchievementId.allCases.count,
            todayTime: stats.todayTotal
        )
    }

    // MARK: - Export Actions

    @MainActor
    private func renderImage() -> NSImage? {
        let content = ShareCardContent(
            creatureType: profile?.creatureType ?? .ghost,
            colorPreset: profile?.colorPreset ?? .none,
            accessory: profile?.accessory ?? .none,
            evolution: gamification.evolution,
            displayName: profile?.displayName ?? "Clautcher",
            xp: gamification.xp,
            streak: gamification.streak.currentStreak,
            longestStreak: gamification.streak.longestStreak,
            totalSessions: gamification.counters.totalSessions,
            achievementsEarned: gamification.earnedAchievements.count,
            achievementsTotal: AchievementId.allCases.count,
            todayTime: stats.todayTotal
        )
        let renderer = ImageRenderer(content: content.frame(width: 400, height: 480))
        renderer.scale = 2.0  // 2x for retina
        guard let cgImage = renderer.cgImage else { return nil }
        return NSImage(cgImage: cgImage, size: NSSize(width: 400, height: 480))
    }

    private func copyToClipboard() {
        guard let image = renderImage() else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])
    }

    private func saveAsPNG() {
        guard let image = renderImage(),
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let pngData = bitmap.representation(using: .png, properties: [:]) else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "clautch-creature.png"
        panel.begin { response in
            if response == .OK, let url = panel.url {
                try? pngData.write(to: url)
            }
        }
    }

    private func shareSheet() {
        guard let image = renderImage() else { return }
        let picker = NSSharingServicePicker(items: [image])
        // Show anchored to the window's content view
        if let window = NSApp.keyWindow, let contentView = window.contentView {
            picker.show(relativeTo: contentView.bounds, of: contentView, preferredEdge: .minY)
        }
    }
}

// MARK: - Card Content (Pure SwiftUI, used for both preview and export)

struct ShareCardContent: View {
    let creatureType: CreatureType
    let colorPreset: CreatureColorPreset
    let accessory: CreatureAccessory
    let evolution: CreatureEvolution
    let displayName: String
    let xp: Int
    let streak: Int
    let longestStreak: Int
    let totalSessions: Int
    let achievementsEarned: Int
    let achievementsTotal: Int
    let todayTime: TimeInterval

    var body: some View {
        VStack(spacing: 0) {
            // Sky + creature scene
            ZStack {
                // Mini sky gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.2, green: 0.45, blue: 0.75),
                        Color(red: 0.4, green: 0.65, blue: 0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Grass strip at bottom of scene
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color(red: 0.2, green: 0.5, blue: 0.25))
                        .frame(height: 30)
                }

                // Large creature
                VStack(spacing: 4) {
                    PixelCreatureView(
                        type: creatureType,
                        frame: 0,
                        task: .idle,
                        emotion: .happy,
                        colorPreset: colorPreset,
                        accessory: accessory,
                        evolution: evolution
                    )
                    .frame(width: 64, height: 64)

                    // Evolution glow label
                    if evolution != .baby {
                        Text(evolution.displayName)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(evolution == .elder ? Color.orange.opacity(0.8) : Color.cyan.opacity(0.8)))
                    }
                }
                .offset(y: -10)
            }
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            // Name + type
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                Text(creatureType.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 16)

            // Stats grid
            HStack(spacing: 0) {
                statCell(icon: "flame", value: "\(streak)", label: "Streak")
                Divider().frame(height: 36)
                statCell(icon: "terminal", value: "\(totalSessions)", label: "Sessions")
                Divider().frame(height: 36)
                statCell(icon: "star", value: "\(achievementsEarned)/\(achievementsTotal)", label: "Badges")
            }
            .padding(.top, 16)

            // XP bar
            VStack(spacing: 4) {
                HStack {
                    Text("\(xp) XP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                    Spacer()
                    Text("Today: \(SessionStats.format(todayTime))")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                GeometryReader { geo in
                    let nextThreshold = evolution.nextThreshold ?? evolution.xpThreshold
                    let progress = nextThreshold > 0 ? min(CGFloat(xp) / CGFloat(nextThreshold), 1.0) : 1.0
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.08))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 6)
            }
            .padding(.top, 16)

            Spacer(minLength: 8)

            // Watermark
            Text("clautch")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundStyle(.tertiary)
                .padding(.bottom, 8)
        }
        .padding(20)
        .frame(width: 400, height: 480)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    private func statCell(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.orange)
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
