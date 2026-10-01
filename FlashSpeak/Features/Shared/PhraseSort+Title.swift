extension PhraseSort {
    var title: String {
        switch self {
        case .newest: "Newest first"
        case .oldest: "Oldest first"
        case .alphabetical: "A to Z"
        case .level: "Level"
        }
    }
}
