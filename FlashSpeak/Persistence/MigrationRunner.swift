import Foundation
import SwiftData

/// Runs `PhraseMigration` once per migration version, at launch.
@MainActor
enum MigrationRunner {
    private static let versionKey = "phraseMigrationVersion"

    static func runIfNeeded(context: ModelContext, defaults: UserDefaults = .standard) throws {
        guard defaults.integer(forKey: versionKey) < PhraseMigration.version else { return }
        let phrases = try context.fetch(FetchDescriptor<Phrase>())
        PhraseMigration.migrate(phrases)
        try context.save()
        defaults.set(PhraseMigration.version, forKey: versionKey)
    }
}
