import Foundation

/// A clarification the user gave for a phrase, and the translation it replaced.
struct Clarification: Codable, Hashable, Sendable {
    var text: String
    var previousTargetText: String
    var date: Date
}
