import SwiftUI

/// Onboarding screen: pick a creature, enter a name, choose a color.
struct OnboardingView: View {
    var onComplete: (UserProfile) -> Void

    @State private var selectedType: CreatureType = .ghost
    @State private var displayName: String = NSFullUserName().components(separatedBy: " ").first ?? "Player"
    @State private var colorPreset: CreatureColorPreset = .none
    @State private var isHovering: CreatureType?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Choose your creature")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .padding(.top, 32)

            Text("This little friend will live in your notch")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
                .padding(.top, 4)

            // Creature grid
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(120), spacing: 16), count: 3), spacing: 16) {
                ForEach(CreatureType.allCases) { type in
                    creatureCard(type)
                }
            }
            .padding(.horizontal, 32)
            .padding(.top, 28)

            // Color picker
            VStack(spacing: 8) {
                Text("Color")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))

                HStack(spacing: 10) {
                    ForEach(CreatureColorPreset.allCases) { preset in
                        colorSwatch(preset)
                    }
                }
            }
            .padding(.top, 24)

            // Name field
            HStack(spacing: 12) {
                Text("Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                TextField("Your name", text: $displayName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(8)
                    .foregroundStyle(.white)
                    .frame(maxWidth: 200)
            }
            .padding(.top, 20)

            Spacer()

            // Start button
            Button(action: complete) {
                Text("Let's go!")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.accentColor)
                    )
            }
            .buttonStyle(.plain)
            .disabled(displayName.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.bottom, 32)
        }
        .frame(width: 440, height: 540)
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.95))
    }

    // MARK: - Creature Card

    private func creatureCard(_ type: CreatureType) -> some View {
        let selected = type == selectedType

        return VStack(spacing: 6) {
            // Animated preview
            TimelineView(.animation(minimumInterval: 1.0 / 4)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let frame = Int(t * 3) % type.frames.count
                let bob = BobAnimation.value(time: t, period: 1.5, amplitude: 1.0)

                PixelCreatureView(
                    type: type,
                    frame: frame,
                    task: .idle,
                    emotion: .neutral,
                    colorPreset: colorPreset
                )
                .frame(width: 48, height: 48)
                .offset(y: bob)
            }
            .frame(height: 52)

            Text(type.displayName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(width: 100, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selected
                    ? Color.accentColor.opacity(0.3)
                    : Color.white.opacity(isHovering == type ? 0.08 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
        )
        .onTapGesture { selectedType = type }
        .onHover { hovering in isHovering = hovering ? type : nil }
    }

    // MARK: - Color Swatch

    private func colorSwatch(_ preset: CreatureColorPreset) -> some View {
        let selected = preset == colorPreset
        let size: CGFloat = 22

        return Circle()
            .fill(preset.swatchColor)
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(selected ? .white : .clear, lineWidth: 2)
            )
            .overlay(
                // "No color" indicator
                preset == .none
                    ? AnyView(
                        Circle()
                            .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    : AnyView(EmptyView())
            )
            .shadow(color: selected ? .white.opacity(0.3) : .clear, radius: 4)
            .onTapGesture { colorPreset = preset }
    }

    // MARK: - Actions

    private func complete() {
        let name = displayName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let profile = UserProfile.create(
            displayName: name,
            creatureType: selectedType,
            colorPreset: colorPreset
        )
        UserProfile.current = profile
        onComplete(profile)
    }
}
