import Foundation

/// External pages linked from the app.
enum AppLinks {
    /// Apple's standard licence agreement, used until FlashSpeak has its own terms.
    static let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// The privacy policy page. Nil (and hidden) until its URL in `docs/` is confirmed.
    static let privacy: URL? = nil
}
