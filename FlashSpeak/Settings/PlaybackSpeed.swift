/// How a phrase is played.
enum PlaybackSpeed: String, Codable, CaseIterable, Sendable {
    case natural
    /// About 0.6–0.75 of natural speed, pitch unchanged.
    case slow
    /// Each word on its own with a short pause.
    case wordByWord

    var title: String {
        switch self {
        case .natural: "Natural"
        case .slow: "Slow"
        case .wordByWord: "Word by word"
        }
    }
}
