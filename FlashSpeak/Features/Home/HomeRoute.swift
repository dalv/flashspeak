/// Screens pushed from Home. Those built in Milestone 3 show a placeholder until then.
enum HomeRoute: Hashable {
    case audioRecall
    case flashcards
    case manageCards
    case presetCategories
    case settings

    var title: String {
        switch self {
        case .audioRecall: "Audio recall"
        case .flashcards: "Flashcards"
        case .manageCards: "Manage cards"
        case .presetCategories: "Preset categories"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .audioRecall: "headphones"
        case .flashcards: "rectangle.on.rectangle"
        case .manageCards: "list.bullet"
        case .presetCategories: "square.grid.2x2"
        case .settings: "gearshape"
        }
    }
}
