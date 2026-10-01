import SwiftUI

/// One category on the list: icon, title, card count, a preview of its
/// words and its status button.
struct PresetCategoryCard: View {
    let category: PresetCategoryContent
    let status: PresetLibrary.Status
    let onOpen: () -> Void
    let onStart: () -> Void
    let onPause: () -> Void

    @Environment(\.languageTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            Button(action: onOpen) {
                HStack(alignment: .top, spacing: DS.Spacing.s) {
                    Image(systemName: category.kind?.systemImage ?? "square.grid.2x2")
                        .font(.system(size: DS.Size.playButtonRow * 0.45, weight: .semibold))
                        .foregroundStyle(theme.accentText)
                        .frame(width: DS.Size.playButtonRow, height: DS.Size.playButtonRow)
                        .background(theme.accentTint, in: .circle)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                        HStack(spacing: DS.Spacing.xs) {
                            Text(category.title)
                                .appTextStyle(.headline)
                                .foregroundStyle(DS.Color.ink)
                            if status == .learning {
                                LevelLabel("Learning")
                            } else if status == .paused {
                                LevelLabel("Paused", style: .neutral)
                            }
                        }
                        Text("\(category.items.count) cards")
                            .appTextStyle(.secondary)
                            .foregroundStyle(DS.Color.inkSecondary)
                        Text(preview)
                            .nativeTextStyle(.inline, script: theme.script)
                            .foregroundStyle(DS.Color.inkSecondary)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(DS.Color.inkTertiary)
                        .accessibilityHidden(true)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Shows every card")

            PresetStatusButton(status: status, onStart: onStart, onPause: onPause)
        }
        .padding(DS.Spacing.cardPadding)
        .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.tile))
    }

    private var preview: String {
        category.items.prefix(5).map(\.targetText).joined(separator: " · ")
    }
}
