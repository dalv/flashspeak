/// The preset categories (PRD, Phrase library). The raw value is the ID
/// stored in `Phrase.presetCategory`, so never change one.
enum PresetCategoryKind: String, CaseIterable, Codable, Sendable {
    case numbers
    case days
    case connectors
    case questions
    case time

    var title: String {
        switch self {
        case .numbers: "Numbers"
        case .days: "Days of the week"
        case .connectors: "Connector words"
        case .questions: "Question words"
        case .time: "Time words"
        }
    }

    var systemImage: String {
        switch self {
        case .numbers: "number"
        case .days: "calendar"
        case .connectors: "link"
        case .questions: "questionmark.bubble"
        case .time: "clock"
        }
    }
}
