import SwiftUI

/// Example clarifications. Tapping one starts a typed clarification with it.
struct ClarifyExamples: View {
    let onPick: (String) -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.xs) {
            Text("For example")
                .appTextStyle(.sectionLabel)
                .foregroundStyle(DS.Color.inkSecondary)
            ForEach(examples, id: \.self) { example in
                Button {
                    onPick(example)
                } label: {
                    Text(example)
                        .appTextStyle(.secondary)
                        .italic()
                        .foregroundStyle(DS.Color.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DS.Spacing.s)
                        .padding(.vertical, DS.Spacing.xs)
                        .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.field, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityHint("Starts a clarification with this text")
            }
        }
    }

    /// One sounded-out example per language, then two that work everywhere.
    private var examples: [String] {
        let soundedOut = switch theme.id {
        case "zh-CN": "It was something like “dai cha”…"
        case "ko": "It sounded like “juseyo” at the end…"
        case "ja": "It was something like “onegai”…"
        default: "It was something like “udah”…"
        }
        return [soundedOut, "Is there a more informal version?", "I'd say it to a friend, not a waiter"]
    }
}
