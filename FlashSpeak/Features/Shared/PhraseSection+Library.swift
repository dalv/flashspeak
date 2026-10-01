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
    /// own phrases, and each started preset category.
    @MainActor
    static func reviewable(in languageCode: String, phrases: any PhraseRepository) -> [PhraseSection] {
        [.all, .userPhrases] + startedPresets(in: languageCode, phrases: phrases)
    }

    /// Preset categories with items in the store, in catalog order.
    @MainActor
    static func startedPresets(in languageCode: String, phrases: any PhraseRepository) -> [PhraseSection] {
        let all = (try? phrases.phrases(in: languageCode, section: .all, sort: .newest)) ?? []
        let started = Set(all.compactMap(\.presetCategory))
        let known = PresetCategoryKind.allCases.map(\.rawValue).filter(started.contains)
        let unknown = started.subtracting(known).sorted()
        return (known + unknown).map { .preset($0) }
    }
}
