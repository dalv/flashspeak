/// The two rating buttons. A deliberate product choice (decision 0005):
/// Hard maps to FSRS Again and Easy to FSRS Good.
enum ReviewRating: Int, Codable, Sendable {
    case hard = 1
    case easy = 3

    /// The FSRS grade: 1 Again, 2 Hard, 3 Good, 4 Easy.
    var fsrsGrade: Double {
        switch self {
        case .hard: 1
        case .easy: 3
        }
    }
}
