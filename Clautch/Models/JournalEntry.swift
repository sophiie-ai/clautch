import Foundation

/// Types of events recorded in the creature journal.
enum JournalEntryType: String, Codable, CaseIterable, Sendable {
    case creation           // Creature first created
    case evolution          // Evolution stage changed
    case achievement        // Achievement unlocked
    case milestoneSession   // 10th, 25th, 50th, 100th session
    case personalityShift   // Dominant trait changed
    case streak             // Streak milestone (7, 14, 30 days)
    case interaction        // First pet, first room join, etc.
    case prestige           // Prestige rebirth

    var icon: String {
        switch self {
        case .creation:         return "🥚"
        case .evolution:        return "⬆"
        case .achievement:      return "⭐"
        case .milestoneSession: return "🎯"
        case .personalityShift: return "💫"
        case .streak:           return "🔥"
        case .interaction:      return "💕"
        case .prestige:         return "🌟"
        }
    }
}

/// A snapshot of the creature's state at the time of a journal entry.
struct CreatureSnapshot: Codable, Sendable {
    let creatureType: CreatureType
    let evolution: CreatureEvolution
    let dominantTrait: PersonalityTrait?
}

/// A single entry in the creature's life journal.
struct JournalEntry: Codable, Identifiable, Sendable {
    let id: UUID
    let date: Date
    let type: JournalEntryType
    let title: String
    let detail: String?
    let creatureSnapshot: CreatureSnapshot?

    init(type: JournalEntryType, title: String, detail: String? = nil, snapshot: CreatureSnapshot? = nil) {
        self.id = UUID()
        self.date = Date()
        self.type = type
        self.title = title
        self.detail = detail
        self.creatureSnapshot = snapshot
    }
}
