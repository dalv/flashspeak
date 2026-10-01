import Foundation

enum TranslationError: Error, Equatable, Sendable {
    case offline
    /// The free daily limit is used up; the paywall opens and the phrase is kept.
    case limitReached
    case unsupportedLanguage
    case server(status: Int, message: String?)
    case invalidResponse

    var userMessage: String {
        switch self {
        case .offline: "You're offline. Your phrase will translate when you're back online."
        case .limitReached: "You've used today's free translations."
        case .unsupportedLanguage: "This language isn't supported."
        case .server: "The translation service had a problem. Try again in a moment."
        case .invalidResponse: "The translation came back garbled. Try again."
        }
    }
}
