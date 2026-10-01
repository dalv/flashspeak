import Foundation

/// The preset categories shipped inside the app, per language.
struct PresetCatalog: Sendable {
    private let files: [String: PresetFile]

    init(files: [PresetFile]) {
        self.files = Dictionary(files.map { ($0.language, $0) }, uniquingKeysWith: { first, _ in first })
    }

    /// Loads `presets.<code>.json` for each supported language from the bundle.
    static func bundled(_ bundle: Bundle = .main) -> PresetCatalog {
        let files = Language.supportedCodes.compactMap { code -> PresetFile? in
            guard let url = bundle.url(forResource: "presets.\(code)", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(PresetFile.self, from: data)
        }
        return PresetCatalog(files: files)
    }

    static let empty = PresetCatalog(files: [])

    func file(for languageCode: String) -> PresetFile? {
        files[languageCode]
    }

    /// Categories in the order of `PresetCategoryKind`.
    func categories(for languageCode: String) -> [PresetCategoryContent] {
        let categories = files[languageCode]?.categories ?? []
        let order = PresetCategoryKind.allCases.map(\.rawValue)
        return categories.sorted {
            (order.firstIndex(of: $0.id) ?? .max) < (order.firstIndex(of: $1.id) ?? .max)
        }
    }

    func category(_ id: String, in languageCode: String) -> PresetCategoryContent? {
        files[languageCode]?.categories.first { $0.id == id }
    }
}
