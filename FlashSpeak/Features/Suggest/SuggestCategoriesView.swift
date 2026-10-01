import SwiftUI

/// Pick a situation (or describe your own) to get phrases at your level.
struct SuggestCategoriesView: View {
    @Bindable var model: NewPhraseModel

    @Environment(\.languageTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.l) {
                VStack(alignment: .leading, spacing: DS.Spacing.xxs) {
                    Text("Pick a situation")
                        .appTextStyle(.title)
                        .foregroundStyle(DS.Color.ink)
                    Text("\(Text(theme.nativeName).font(NativeTextStyle.inline.customFont(for: theme.script))) · at your level, \(model.suggestionLevelRange)")
                        .appTextStyle(.subheadline)
                        .foregroundStyle(DS.Color.inkSecondary)
                }

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text("Or describe your own")
                        .appTextStyle(.sectionLabel)
                        .foregroundStyle(DS.Color.inkSecondary)
                    TextField("e.g. at acro practice", text: $model.customCategory)
                        .appTextStyle(.callout)
                        .padding(.horizontal, DS.Spacing.m)
                        .frame(minHeight: DS.Size.minTouch + 4)
                        .background(DS.Color.surface, in: .rect(cornerRadius: DS.Radius.field, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: DS.Radius.field, style: .continuous)
                                .strokeBorder(DS.Color.hairline, lineWidth: DS.Size.hairlineWidth)
                        }
                        .submitLabel(.go)
                        .onSubmit(startSuggestions)
                }

                ForEach(SuggestCategories.groups) { group in
                    VStack(alignment: .leading, spacing: DS.Spacing.s) {
                        Text(group.title)
                            .appTextStyle(.sectionLabel)
                            .foregroundStyle(DS.Color.inkSecondary)
                        FlowLayout {
                            ForEach(group.categories, id: \.self) { category in
                                Chip(category, isSelected: model.selectedCategory == category) {
                                    model.select(category: category)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.bottom, DS.Spacing.l)
        }
        .scrollDismissesKeyboard(.interactively)
        .safeAreaBar(edge: .bottom) {
            PrimaryButton("Suggest \(SuggestModel.batchSize) phrases", action: startSuggestions)
                .disabled(model.suggestionCategory == nil)
                .padding(.vertical, DS.Spacing.s)
        }
    }

    private func startSuggestions() {
        model.startSuggestions()
    }
}
