import Foundation

/// Typed access to the fields stored as raw values or JSON.
extension Phrase {
    var phraseSource: PhraseSource {
        get { PhraseSource(rawValue: source) ?? .legacy }
        set { source = newValue.rawValue }
    }

    var gloss: [GlossPair] {
        get { Self.decode(glossData) ?? [] }
        set { glossData = Self.encode(newValue) }
    }

    var clarifications: [Clarification] {
        get { Self.decode(clarificationsData) ?? [] }
        set { clarificationsData = Self.encode(newValue) }
    }

    var cardState: CardState {
        get {
            CardState(
                phase: fsrsState.flatMap(CardState.Phase.init(rawValue:)) ?? .new,
                stability: fsrsStability ?? 0,
                difficulty: fsrsDifficulty ?? 0,
                due: nextReviewAt,
                lastReview: lastReviewedAt,
                lapses: fsrsLapses
            )
        }
        set {
            fsrsState = newValue.phase.rawValue
            fsrsStability = newValue.stability
            fsrsDifficulty = newValue.difficulty
            nextReviewAt = newValue.due
            lastReviewedAt = newValue.lastReview
            fsrsLapses = newValue.lapses
        }
    }

    var isPreset: Bool {
        presetCategory != nil
    }

    private static func decode<T: Decodable>(_ data: Data?) -> T? {
        data.flatMap { try? JSONDecoder().decode(T.self, from: $0) }
    }

    private static func encode<T: Encodable>(_ value: T) -> Data? {
        try? JSONEncoder().encode(value)
    }
}
