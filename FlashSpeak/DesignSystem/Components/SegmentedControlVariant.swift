/// How a `SegmentedControl` looks.
enum SegmentedControlVariant: Sendable {
    /// Liquid Glass track; the selected segment is filled with the accent.
    /// For the language picker.
    case glassAccent
    /// Liquid Glass track; the selected segment is a solid surface thumb.
    /// For top-level mode switches (Speak / Type / Suggest).
    case glass
    /// Solid track, for use inside a content card (speed, register).
    /// Never glass, because glass doesn't go on content.
    case inline
}
