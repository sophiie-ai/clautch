import Foundation

/// Persisted user profile: creature choice, display name, color tint.
struct UserProfile: Codable, Sendable {
    var peerId: String
    var displayName: String
    var creatureType: CreatureType
    var colorPreset: CreatureColorPreset

    // MARK: - Persistence

    private static let key = "com.clautch.userProfile"

    /// In-memory cache to avoid re-decoding JSON from UserDefaults on every access.
    private static var cached: UserProfile?
    private static var cacheLoaded = false

    /// The current user's profile, or `nil` if onboarding hasn't happened.
    static var current: UserProfile? {
        get {
            if cacheLoaded { return cached }
            cacheLoaded = true
            if let data = UserDefaults.standard.data(forKey: key) {
                cached = try? JSONDecoder().decode(UserProfile.self, from: data)
            }
            return cached
        }
        set {
            cached = newValue
            cacheLoaded = true
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
