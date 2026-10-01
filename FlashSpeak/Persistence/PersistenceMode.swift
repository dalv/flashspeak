import SwiftData

/// Where the store syncs. Local until the developer membership is renewed
/// (architecture.md, Persistence modes); switching is this one value, since
/// both modes use the same schema and store file.
enum PersistenceMode {
    case local
    case cloudKit

    static let current: PersistenceMode = .local

    static let cloudKitContainer = "iCloud.com.vladtamas.FlashSpeak"
}

extension ModelContainer {
    static let schema = Schema([Phrase.self, ReviewLog.self])

    /// The app's on-disk store.
    static func app(mode: PersistenceMode = .current) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: mode == .cloudKit ? .private(PersistenceMode.cloudKitContainer) : .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// An empty in-memory store for previews and tests.
    static func inMemory() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create in-memory store: \(error)")
        }
    }
}
