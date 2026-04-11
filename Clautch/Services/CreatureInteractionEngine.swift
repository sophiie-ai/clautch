import Foundation
import os

/// Computes autonomous creature-to-creature interactions client-side.
/// When two creatures are near each other for a sustained period, triggers
/// a paired animation (face each other, bump, wave, play together, share).
@Observable
@MainActor
final class CreatureInteractionEngine {
    static let shared = CreatureInteractionEngine()

    private let logger = Logger(subsystem: "com.clautch.app", category: "Interaction")
    private let proximityThreshold: CGFloat = 0.15
    private let proximityDelay: TimeInterval = 3.0
    private let cooldownDuration: TimeInterval = 30.0
    private let interactionDuration: TimeInterval = 3.5

    /// Currently active autonomous interaction, if any.
    private(set) var activeInteraction: AutonomousInteraction?

    /// Tracks when each pair first became proximate.
    @ObservationIgnored private var proximityTimers: [String: Date] = [:]

    /// Tracks cooldown per pair to prevent spam.
    @ObservationIgnored private var cooldowns: [String: Date] = [:]

    /// Cached creature list for timer-driven updates.
    @ObservationIgnored private var lastCreatures: [CreatureDisplay] = []
    @ObservationIgnored private var tickTimer: Timer?

    struct AutonomousInteraction {
        let creatureA: String
        let creatureB: String
        let positionA: CGFloat
        let positionB: CGFloat
        let type: InteractionType
        let startedAt: Date
        let duration: TimeInterval

        var isActive: Bool {
            Date().timeIntervalSince(startedAt) < duration
        }

        /// Normalized progress 0...1.
        var progress: Double {
            min(1.0, Date().timeIntervalSince(startedAt) / duration)
        }
    }

    enum InteractionType: CaseIterable {
        case faceEachOther
        case bump
        case wave
        case playTogether
        case share
    }

    private init() {
        // Periodic tick so the engine advances even when the view isn't recomputing
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.update(creatures: self.lastCreatures)
            }
        }
    }

    /// Called with the current creature list. Also caches the list for timer ticks.
    func update(creatures: [CreatureDisplay]) {
        lastCreatures = creatures
        // Clear expired interaction
        if let active = activeInteraction, !active.isActive {
            activeInteraction = nil
        }

        // Don't start new interaction while one is active
        guard activeInteraction == nil else { return }
        guard creatures.count >= 2 else {
            proximityTimers.removeAll()
            return
        }

        let now = Date()

        // Find all nearby pairs
        var activePairKeys: Set<String> = []
        for i in 0..<creatures.count {
            for j in (i + 1)..<creatures.count {
                let dist = abs(creatures[i].xPosition - creatures[j].xPosition)
                guard dist < proximityThreshold else { continue }

                let key = pairKey(creatures[i].id, creatures[j].id)
                activePairKeys.insert(key)

                // Check cooldown
                if let lastInteraction = cooldowns[key],
                   now.timeIntervalSince(lastInteraction) < cooldownDuration {
                    continue
                }

                // Track proximity duration
                if proximityTimers[key] == nil {
                    proximityTimers[key] = now
                }

                if let startTime = proximityTimers[key],
                   now.timeIntervalSince(startTime) >= proximityDelay {
                    // Roll probability — social creatures interact more often
                    let baseProbability = 0.3
                    let socialBoost = (creatures[i].personality?.social ?? 0) * 0.3
                    let roll = Double.random(in: 0...1)
                    if roll < baseProbability + socialBoost {
                        triggerInteraction(
                            a: creatures[i].id, aPos: creatures[i].xPosition,
                            b: creatures[j].id, bPos: creatures[j].xPosition
                        )
                        proximityTimers.removeValue(forKey: key)
                    } else {
                        // Failed roll — reset timer so we check again later
                        proximityTimers[key] = now
                    }
                }
            }
        }

        // Clean up timers for pairs no longer proximate
        for key in proximityTimers.keys where !activePairKeys.contains(key) {
            proximityTimers.removeValue(forKey: key)
        }
    }

    private func triggerInteraction(a: String, aPos: CGFloat, b: String, bPos: CGFloat) {
        let type = InteractionType.allCases.randomElement() ?? .faceEachOther
        activeInteraction = AutonomousInteraction(
            creatureA: a,
            creatureB: b,
            positionA: aPos,
            positionB: bPos,
            type: type,
            startedAt: Date(),
            duration: interactionDuration
        )
        cooldowns[pairKey(a, b)] = Date()
        logger.info("Autonomous interaction: \(String(describing: type)) between \(a) and \(b)")
    }

    /// Whether the engine wants to override facing for a specific creature.
    /// Uses stored positions to determine correct facing direction.
    func facingOverride(for creatureId: String) -> Bool? {
        guard let active = activeInteraction, active.isActive,
              active.type == .faceEachOther || active.type == .bump || active.type == .wave else {
            return nil
        }
        if creatureId == active.creatureA {
            return active.positionB > active.positionA  // face toward B
        }
        if creatureId == active.creatureB {
            return active.positionA > active.positionB  // face toward A
        }
        return nil
    }

    private func pairKey(_ a: String, _ b: String) -> String {
        a < b ? "\(a)|\(b)" : "\(b)|\(a)"
    }
}
