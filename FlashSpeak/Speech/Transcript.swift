/// The transcript so far: confirmed text plus the volatile tail that may still change.
struct Transcript: Equatable, Sendable {
    var finalized: String
    var volatile: String

    var text: String {
        [finalized, volatile].filter { !$0.isEmpty }.joined(separator: " ")
    }

    static let empty = Transcript(finalized: "", volatile: "")
}
