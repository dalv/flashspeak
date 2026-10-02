import SwiftUI

/// Every card in one category, playable, with the Flashcards and Audio
/// recall buttons.
struct PresetCategoryDetail: View {
    let category: PresetCategoryContent
    let model: PresetCategoriesModel

    var body: some View {
        List {
            Section {
                ForEach(category.items) { item in
                    PhraseRow(item.content, isPlaying: model.playingKey == item.key) {
                        model.play(item)
                    }
                }
            } header: {
                Text("\(category.items.count) cards")
                    .appTextStyle(.sectionLabel)
                    .foregroundStyle(DS.Color.inkSecondary)
            }
            .dsListRows()
        }
        .dsGroupedList()
        .safeAreaBar(edge: .bottom) {
            PresetSetButtons(
                membership: model.membership(of: category),
                pending: model.pendingChange(for: category),
                onTap: { set in model.toggle(category, in: set) },
                onConfirm: model.confirm,
                onDismiss: model.dismissChange
            )
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.vertical, DS.Spacing.s)
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear(perform: model.stopPlayback)
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    PresetCategoryDetailPreview(languageCode: "zh-CN")
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    PresetCategoryDetailPreview(languageCode: "id")
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    PresetCategoryDetailPreview(languageCode: "ko")
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    PresetCategoryDetailPreview(languageCode: "ja")
        .preferredColorScheme(.dark)
}

/// Numbers in one language.
private struct PresetCategoryDetailPreview: View {
    let languageCode: String
    @State private var model: PresetCategoriesModel

    init(languageCode: String) {
        self.languageCode = languageCode
        let dependencies = AppDependencies.preview()
        dependencies.settings.currentLanguageCode = languageCode
        _model = State(initialValue: PresetCategoriesModel(dependencies: dependencies))
    }

    var body: some View {
        if let category = model.dependencies.presets.category("numbers", in: languageCode) {
            NavigationStack { PresetCategoryDetail(category: category, model: model) }
                .languageTheme(model.theme)
                .onAppear(perform: model.refresh)
        }
    }
}
