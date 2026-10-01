import Foundation

/// Computes a card's next state from a rating. Pure and deterministic.
protocol Scheduler: Sendable {
    /// Identifies the algorithm and parameters, stored with each review.
    var version: String { get }
    func next(_ state: CardState, rating: ReviewRating, now: Date) -> CardState
}
