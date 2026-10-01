import Foundation

/// A card's FSRS scheduling state. Pure value; stored on `Phrase`.
struct CardState: Equatable, Sendable {
    enum Phase: Int, Sendable {
        case new = 0
        case learning = 1
        case review = 2
        case relearning = 3
    }

    var phase: Phase
    /// Days until retrievability drops to 90%.
    var stability: Double
    /// 1 (easy) to 10 (hard).
    var difficulty: Double
    var due: Date
    var lastReview: Date?
    var lapses: Int

    static func new(due: Date) -> CardState {
        CardState(phase: .new, stability: 0, difficulty: 0, due: due, lastReview: nil, lapses: 0)
    }
}
