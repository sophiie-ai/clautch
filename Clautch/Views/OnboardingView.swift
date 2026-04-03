import SwiftUI

/// Onboarding screen: pick a creature, enter a name, choose a color.
struct OnboardingView: View {
    var onComplete: (UserProfile) -> Void

    @State private var step = 0  // 0=creature, 1=style, 2=name
    @State private var selectedType: CreatureType = UserProfile.current?.creatureType ?? .ghost
    @State private var displayName: String = UserProfile.current?.displayName ?? ""
    @State private var colorPreset: CreatureColorPreset = UserProfile.current?.colorPreset ?? .none
    @State private var accessory: CreatureAccessory = UserProfile.current?.accessory ?? .none
    @State private var isHovering: CreatureType?
    @FocusState private var nameFieldFocused: Bool

    private let stepTitles = ["Choose your creature", "Pick a style", "What's your name?"]
    private let stepSubtitles = [
        "This little friend will live in your notch",
        "Give them some flair",
        "So your teammates know who you are",
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(i <= step ? Color.accentColor : Color.primary.opacity(0.15))
                        .frame(width: 8, height: 8)
                    if i < 2 {
                        Rectangle()
                            .fill(i < step ? Color.accentColor : Color.primary.opacity(0.15))
                            .frame(height: 2)
                            .frame(maxWidth: 40)
                    }
                }
            }
            .padding(.top, 24)
            .animation(.easeInOut(duration: 0.3), value: step)

            // Header
            Text(stepTitles[step])
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.top, 20)
                .id("title-\(step)")
                .transition(.opacity)

            Text(stepSubtitles[step])
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
                .id("subtitle-\(step)")
                .transition(.opacity)

            // Step content
            Group {
                switch step {
                case 0: creatureStep
                case 1: styleStep
                case 2: nameStep
                default: EmptyView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .id("step-\(step)")

            Spacer()

            // Navigation buttons
            HStack(spacing: 12) {
                if step > 0 {
                    Button(action: { withAnimation { step -= 1 } }) {
                        Text("Back")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.leftArrow, modifiers: [])
                }

                Spacer()

                // Skip (only on first launch, not when re-customizing)
                if UserProfile.current == nil && step < 2 {
                    Button(action: skipOnboarding) {
                        Text("Skip")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                if step < 2 {
                    Button(action: { withAnimation { step += 1 } }) {
                        Text("Next")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.accentColor)
                            )
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.rightArrow, modifiers: [])
                } else {
                    Button(action: complete) {
                        Text("Let's go!")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(canComplete ? Color.accentColor : Color.secondary.opacity(0.3))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canComplete)
                    .keyboardShortcut(.return, modifiers: [])
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 28)
        }
        .frame(width: 440, height: 600)
        .background(.background)
    }

    private var canComplete: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Step 0: Creature

    private var creatureStep: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(120), spacing: 16), count: 3), spacing: 16) {
            ForEach(CreatureType.allCases) { type in
                creatureCard(type)
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 28)
    }

    // MARK: - Step 1: Style

    private var styleStep: some View {
        VStack(spacing: 24) {
            // Live preview with contrast background
            TimelineView(.animation(minimumInterval: 1.0 / 4)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let frame = Int(t * 3) % max(selectedType.frames.count, 1)
                let bob = BobAnimation.value(time: t, period: 1.5, amplitude: 1.0)

                PixelCreatureView(
                    type: selectedType,
                    frame: frame,
                    task: .idle,
                    emotion: .neutral,
                    colorPreset: colorPreset,
                    accessory: accessory
                )
                .frame(width: 64, height: 64)
                .offset(y: bob)
            }
            .frame(height: 72)
            .background(
                Circle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 80, height: 80)
            )

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
                                    .fill(selected ? Color.accentColor.opacity(0.3) : Color.primary.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(selected ? Color.accentColor : .clear, lineWidth: 1.5)
                            )
                            .onTapGesture { accessory = acc }
                            .accessibilityLabel(acc == .none ? "No accessory" : "\(acc.rawValue) accessory")
                            .accessibilityAddTraits(acc == accessory ? .isSelected : [])
                    }
                }
            }
        }
        .padding(.top, 28)
    }

    // MARK: - Step 2: Name

    private var nameStep: some View {
        VStack(spacing: 20) {
            // Preview with selected style
            TimelineView(.animation(minimumInterval: 1.0 / 4)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let frame = Int(t * 3) % max(selectedType.frames.count, 1)
                let bob = BobAnimation.value(time: t, period: 1.5, amplitude: 1.0)

                PixelCreatureView(
                    type: selectedType,
                    frame: frame,
                    task: .idle,
                    emotion: .happy,
                    colorPreset: colorPreset,
                    accessory: accessory
                )
                .frame(width: 48, height: 48)
                .offset(y: bob)
            }
            .frame(height: 56)
            .background(
                Circle()
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: 64, height: 64)
            )

            TextField("Your name", text: $displayName)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.primary.opacity(0.08))
                .cornerRadius(10)
                .frame(maxWidth: 240)
                .focused($nameFieldFocused)
                .onSubmit { if canComplete { complete() } }
        }
        .padding(.top, 40)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                nameFieldFocused = true
            }
        }
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
                    colorPreset: selected ? colorPreset : .none,
                    accessory: selected ? accessory : .none
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.displayName) creature")
        .accessibilityAddTraits(type == selectedType ? .isSelected : [])
        .accessibilityHint("Double-click to select this creature")
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
            .accessibilityLabel(preset == .none ? "No color" : "\(preset.rawValue) color")
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityHint("Double-click to select this color")
    }

    // MARK: - Actions

    private func complete() {
        let name = displayName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        // Preserve existing peerId if re-customizing (keeps room membership)
        let peerId = UserProfile.current?.peerId ?? UUID().uuidString
        let profile = UserProfile(
            peerId: peerId,
            displayName: name,
            creatureType: selectedType,
            colorPreset: colorPreset,
            accessory: accessory
        )
        UserProfile.current = profile
        onComplete(profile)
    }

    private func skipOnboarding() {
        let peerId = UUID().uuidString
        let name = NSFullUserName().components(separatedBy: " ").first ?? "User"
        let profile = UserProfile(
            peerId: peerId,
            displayName: name,
            creatureType: .ghost,
            colorPreset: .none,
            accessory: .none
        )
        UserProfile.current = profile
        onComplete(profile)
    }
}
