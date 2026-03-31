import Foundation

/// Persisted user profile: creature choice, display name, color tint.
struct UserProfile: Codable, Sendable {
    var peerId: String
    var displayName: String
    var creatureType: CreatureType
    var colorPreset: CreatureColorPreset
    var accessory: CreatureAccessory

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
    init(peerId: String, displayName: String, creatureType: CreatureType, colorPreset: CreatureColorPreset, accessory: CreatureAccessory = .none) {
        self.peerId = peerId
        self.displayName = displayName
        self.creatureType = creatureType
        self.colorPreset = colorPreset
        self.accessory = accessory
    }

    /// Backward-compatible decoding: default accessory to .none for older profiles.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        peerId = try c.decode(String.self, forKey: .peerId)
        displayName = try c.decode(String.self, forKey: .displayName)
        creatureType = try c.decode(CreatureType.self, forKey: .creatureType)
        colorPreset = try c.decode(CreatureColorPreset.self, forKey: .colorPreset)
        accessory = try c.decodeIfPresent(CreatureAccessory.self, forKey: .accessory) ?? .none
    }

    static func create(
        displayName: String,
        creatureType: CreatureType,
        colorPreset: CreatureColorPreset = .none,
        accessory: CreatureAccessory = .none
    ) -> UserProfile {
        UserProfile(
            peerId: UUID().uuidString,
            displayName: displayName,
            creatureType: creatureType,
            colorPreset: colorPreset,
            accessory: accessory
        )
    }
}
