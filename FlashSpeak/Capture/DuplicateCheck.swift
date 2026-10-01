/// What the duplicate check found for a new phrase.
enum DuplicateCheck: Equatable {
    case none
    /// Same English or same translation (normalized). Saving is blocked.
    case exact(Phrase)
    /// Close in meaning. The user can save anyway.
    case near(Phrase)

    var existing: Phrase? {
        switch self {
        case .none: nil
        case let .exact(phrase), let .near(phrase): phrase
        }
    }
}
