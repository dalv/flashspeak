import Foundation

/// Where the Worker lives.
///
/// The base is the legacy endpoint from the gitignored `APIConfig`; v2
/// paths are appended to it. DEBUG builds launched with `-localWorker` use
/// `wrangler dev` on this Mac instead (the simulator reaches localhost).
enum WorkerEndpoint {
    /// The client the app uses. DEBUG builds launched with
    /// `-fakeTranslation` use the fake client instead, for offline work.
    static func liveClient() -> any TranslationClient {
        #if DEBUG
        if CommandLine.arguments.contains("-fakeTranslation") {
            return FakeTranslationClient(delay: .milliseconds(900))
        }
        #endif
        return WorkerTranslationClient(baseURL: baseURL)
    }

    static let localURL = URL(string: "http://localhost:8787")!

    static var baseURL: URL {
        #if DEBUG
            if CommandLine.arguments.contains("-localWorker") {
                return localURL
            }
        #endif
        guard let url = URL(string: APIConfig.translationEndpoint) else {
            preconditionFailure("APIConfig.translationEndpoint is not a valid URL")
        }
        return url
    }
}
