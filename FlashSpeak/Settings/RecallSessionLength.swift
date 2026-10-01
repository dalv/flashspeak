/// How many phrases an audio recall session plays.
enum RecallSessionLength: String, Codable, CaseIterable, Sendable {
    case ten
    case twenty
    case all

    /// Nil means every phrase in the section.
    var limit: Int? {
        switch self {
        case .ten: 10
        case .twenty: 20
        case .all: nil
        }
    }

    var title: String {
        switch self {
        case .ten: "10"
        case .twenty: "20"
        case .all: "All"
        }
    }
}
