/// How translations sound. Each language has a default register in the
/// Worker's prompt; `.casual` means that everyday default.
enum Register: String, Codable, CaseIterable, Sendable {
    case casual
    case neutral
    case polite
}
