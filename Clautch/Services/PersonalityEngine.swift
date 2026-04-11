import Foundation
import os

/// Computes creature personality traits from accumulated usage stats.
/// Traits are recalculated on session end and persisted across launches.
@Observable
@MainActor
final class PersonalityEngine {
    static let shared = PersonalityEngine()

    private static let personalityKey = "com.clautch.creaturePersonality"
    private static let historyKey = "com.clautch.personalityHistory"
    private let logger = Logger(subsystem: "com.clautch.app", category: "Personality")

    private(set) var personality: CreaturePersonality

    /// Historical snapshots for detecting dominant trait shifts.
    private(set) var history: [PersonalitySnapshot] = []

    struct PersonalitySnapshot: Codable {
        let dominantTrait: PersonalityTrait?
        let date: Date
    }

    private init() {
        personality = Self.load() ?? CreaturePersonality()
        history = Self.loadHistory()
    }

    /// Recalculate all personality traits from current counters and stats.
    /// Called on session end — a natural breakpoint where stats are fresh.
    func recalculate() {
        let counters = GamificationStore.shared.counters
        let stats = SessionStats.shared
        let streak = GamificationStore.shared.streak

        let oldDominant = personality.dominantTrait
        let totalSessions = max(counters.totalSessions, 1)

        // Curious: unique tool variety relative to total usage
        let uniqueCount = Double(counters.uniqueToolNames.count)
        personality.curious = min(1.0, uniqueCount / 15.0)

        // Focused: average session length (total coding seconds / sessions)
        let avgMinutes = (counters.totalCodingSeconds / Double(totalSessions)) / 60.0
        personality.focused = min(1.0, avgMinutes / 120.0)

        // Social: reactions sent + room activity
        let socialScore = Double(counters.totalReactionsSent) + (counters.hasJoinedRoom ? 5.0 : 0.0)
        personality.social = min(1.0, socialScore / 30.0)

        // Nocturnal: ratio of night sessions to total
        let nightRatio = Double(counters.nightSessionCount) / Double(totalSessions)
        personality.nocturnal = min(1.0, nightRatio * 3.0)

        // Resilient: error recovery count
        personality.resilient = min(1.0, Double(counters.errorRecoveryCount) / 10.0)

        // Playful: speed bursts + emotion variety
        let playScore = Double(counters.speedBurstCount) + Double(stats.moodHistory.count) * 0.2
        personality.playful = min(1.0, playScore / 15.0)

        // Zen: longest positive mood run
        personality.zen = min(1.0, Double(counters.longestPositiveMoodRun) / 50.0)

        personality.lastUpdated = Date()
        save()

        // Detect dominant trait shift
        let newDominant = personality.dominantTrait
        if let newDominant, newDominant != oldDominant {
            let snapshot = PersonalitySnapshot(dominantTrait: newDominant, date: Date())
            history.append(snapshot)
            // Keep last 50 snapshots
            if history.count > 50 {
                history.removeFirst(history.count - 50)
            }
            saveHistory()
            JournalStore.shared.record(
                type: .personalityShift,
                title: "Became \(newDominant.displayName)",
                detail: newDominant.description
            )
            logger.info("Personality shift: \(oldDominant?.rawValue ?? "none") → \(newDominant.rawValue)")
        }
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(personality) {
            UserDefaults.standard.set(data, forKey: Self.personalityKey)
        }
    }

    private static func load() -> CreaturePersonality? {
        guard let data = UserDefaults.standard.data(forKey: personalityKey) else { return nil }
        return try? JSONDecoder().decode(CreaturePersonality.self, from: data)
    }

    private func saveHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: Self.historyKey)
        }
    }

    private static func loadHistory() -> [PersonalitySnapshot] {
        guard let data = UserDefaults.standard.data(forKey: historyKey) else { return [] }
        return (try? JSONDecoder().decode([PersonalitySnapshot].self, from: data)) ?? []
    }
}
