import Foundation

/// Persisted user profile: creature choice, display name, color tint.
struct UserProfile: Codable, Sendable {
    var peerId: String
    var displayName: String
    var creatureType: CreatureType
    var colorPreset: CreatureColorPreset

    // MARK: - Persistence

    private static let key = "com.clautch.userProfile"

    /// The current user's profile, or `nil` if onboarding hasn't happened.
    static var current: UserProfile? {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            return try? JSONDecoder().decode(UserProfile.self, from: data)
        }
        set {
            if let profile = newValue,
               let data = try? JSONEncoder().encode(profile) {
                UserDefaults.standard.set(data, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// Whether the user has completed onboarding.
    static var hasProfile: Bool { current != nil }

    /// Create a new profile with defaults.
    static func create(
        displayName: String,
        creatureType: CreatureType,
        colorPreset: CreatureColorPreset = .none
    ) -> UserProfile {
        UserProfile(
            peerId: UUID().uuidString,
            displayName: displayName,
            creatureType: creatureType,
            colorPreset: colorPreset
        )
    }
}
