import Foundation
import os

/// Persists and queries the creature's life journal entries.
@Observable
@MainActor
final class JournalStore {
    static let shared = JournalStore()

    private static let storageKey = "com.clautch.creatureJournal"
    private static let maxEntries = 500
    private let logger = Logger(subsystem: "com.clautch.app", category: "Journal")

    private(set) var entries: [JournalEntry] = []

    private init() {
        entries = Self.load()
    }

    /// Add a new journal entry.
    func addEntry(_ entry: JournalEntry) {
        entries.append(entry)

        // Prune oldest if over cap
        if entries.count > Self.maxEntries {
            entries.removeFirst(entries.count - Self.maxEntries)
        }

        save()
        logger.info("Journal: \(entry.type.rawValue) — \(entry.title)")
    }

    /// Convenience: create and add an entry in one call.
    /// Pass `evolution` to avoid re-entering `GamificationStore.shared` — required
    /// when called from inside that store's `init` (e.g. streak-unlock paths).
    func record(type: JournalEntryType, title: String, detail: String? = nil, evolution: CreatureEvolution? = nil) {
        let snapshot = currentSnapshot(evolutionOverride: evolution)
        let entry = JournalEntry(type: type, title: title, detail: detail, snapshot: snapshot)
        addEntry(entry)
    }

    /// Entries filtered to a date range.
    func entries(from start: Date, to end: Date) -> [JournalEntry] {
        entries.filter { $0.date >= start && $0.date <= end }
    }

    /// Entries grouped by date key, most recent first.
    var entriesByDate: [(date: String, entries: [JournalEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            SessionStats.dateKey(for: entry.date)
        }
        return grouped
            .sorted { $0.key > $1.key }
            .map { (date: $0.key, entries: $0.value.sorted { $0.date > $1.date }) }
    }

    /// Age of the creature in days (from first journal entry or today).
    var creatureAgeDays: Int {
        guard let first = entries.first else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: first.date, to: Date()).day ?? 0)
    }

    // MARK: - Snapshot

    private func currentSnapshot(evolutionOverride: CreatureEvolution? = nil) -> CreatureSnapshot {
        let profile = UserProfile.current
        return CreatureSnapshot(
            creatureType: profile?.creatureType ?? .ghost,
            evolution: evolutionOverride ?? GamificationStore.shared.evolution,
            dominantTrait: PersonalityEngine.shared.personality.dominantTrait
        )
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private static func load() -> [JournalEntry] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return [] }
        return (try? JSONDecoder().decode([JournalEntry].self, from: data)) ?? []
    }
}
