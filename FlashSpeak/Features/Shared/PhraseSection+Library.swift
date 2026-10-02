import Foundation

extension PhraseSection {
    var title: String {
        switch self {
        case .all: "All phrases"
        case .userPhrases: "User phrases"
        case let .preset(id): PresetCategoryKind(rawValue: id)?.title ?? id.capitalized
        }
    }

    /// The sections a review session can narrow to: everything, the user's
    /// own phrases, and each preset category added to that set.
    @MainActor
    static func reviewable(
        in languageCode: String,
        phrases: any PhraseRepository,
        set: PresetLibrary.ReviewSet
    ) -> [PhraseSection] {
        [.all, .userPhrases] + startedPresets(in: languageCode, phrases: phrases, set: set)
    }

    /// Preset categories with items in the store, in catalog order; with a
    /// set, only those added to it.
    @MainActor
    static func startedPresets(
        in languageCode: String,
        phrases: any PhraseRepository,
        set: PresetLibrary.ReviewSet? = nil
    ) -> [PhraseSection] {
        let all = ((try? phrases.phrases(in: languageCode, section: .all, sort: .newest)) ?? []).filter { phrase in
            switch set {
            case nil: true
            case .flashcards: !phrase.excludedFromFlashcards
            case .recall: !phrase.excludedFromRecall
            }
        }
        let started = Set(all.compactMap(\.presetCategory))
        let known = PresetCategoryKind.allCases.map(\.rawValue).filter(started.contains)
        let unknown = started.subtracting(known).sorted()
        return (known + unknown).map { .preset($0) }
    }
}
