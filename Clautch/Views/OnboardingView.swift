import SwiftUI

/// Onboarding screen: pick a creature, enter a name, choose a color.
struct OnboardingView: View {
    var onComplete: (UserProfile) -> Void

    @State private var selectedType: CreatureType = .ghost
    @State private var displayName: String = ""
    @State private var colorPreset: CreatureColorPreset = .none
    @State private var accessory: CreatureAccessory = .none
    @State private var isHovering: CreatureType?
    @FocusState private var nameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Choose your creature")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 32)

            Text("This little friend will live in your notch")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
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
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    ForEach(CreatureColorPreset.allCases) { preset in
                        colorSwatch(preset)
                    }
                }
            }
            .padding(.top, 20)

            // Accessory picker
            VStack(spacing: 8) {
                Text("Accessory")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    ForEach(CreatureAccessory.allCases) { acc in
                        let selected = acc == accessory
                        Text(acc == .none ? "✕" : acc.emoji)
                            .font(.system(size: 14))
                            .frame(width: 28, height: 28)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selected ? Color.accentColor.opacity(0.3) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 1.5)
                            )
                            .onTapGesture { accessory = acc }
                    }
                }
            }
            .padding(.top, 12)

            // Name field
            HStack(spacing: 12) {
                Text("Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)

                TextField("What should we call you?", text: $displayName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, design: .rounded))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.primary.opacity(0.08))
                    .cornerRadius(8)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: 200)
                    .focused($nameFieldFocused)
                    .onSubmit { complete() }
            }
            .padding(.top, 20)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    nameFieldFocused = true
                }
            }

            Spacer()

            // Start button
            Button(action: complete) {
                Text("Let's go!")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
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
        .frame(width: 440, height: 600)
        .background(.background)
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
                    colorPreset: colorPreset,
                    accessory: type == selectedType ? accessory : .none
                )
                .frame(width: 48, height: 48)
                .offset(y: bob)
            }
            .frame(height: 52)

            Text(type.displayName)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 100, height: 90)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(selected
                    ? Color.accentColor.opacity(0.3)
                    : Color.primary.opacity(isHovering == type ? 0.08 : 0.04))
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
                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 2)
            )
            .overlay(
                // "No color" indicator
                preset == .none
                    ? AnyView(
                        Circle()
                            .strokeBorder(Color.secondary.opacity(0.5), lineWidth: 1)
                    )
                    : AnyView(EmptyView())
            )
            .shadow(color: selected ? Color.accentColor.opacity(0.3) : .clear, radius: 4)
            .onTapGesture { colorPreset = preset }
    }

    // MARK: - Actions

    private func complete() {
        let name = displayName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let profile = UserProfile.create(
            displayName: name,
            creatureType: selectedType,
            colorPreset: colorPreset,
            accessory: accessory
        )
        UserProfile.current = profile
        onComplete(profile)
    }
}
