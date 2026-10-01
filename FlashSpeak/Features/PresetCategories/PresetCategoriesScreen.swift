import SwiftUI

/// Ready-made categories of basic vocabulary. Browse and play freely;
/// "Start learning" adds a category to flashcards and audio recall.
struct PresetCategoriesScreen: View {
    @State private var model: PresetCategoriesModel
    @State private var selected: PresetCategoryContent?

    init(dependencies: AppDependencies) {
        _model = State(initialValue: PresetCategoriesModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Basic words every learner needs. Start a category to add it to your reviews; pause it any time without losing progress.")
                    .appTextStyle(.secondary)
                    .foregroundStyle(DS.Color.inkSecondary)

                if let error = model.errorMessage {
                    Text(error)
                        .appTextStyle(.secondary)
                        .foregroundStyle(DS.Color.danger)
                }

                if model.categories.isEmpty {
                    Text("Preset categories aren't available for \(model.theme.displayName) yet.")
                        .appTextStyle(.body)
                        .foregroundStyle(DS.Color.inkSecondary)
                }

                ForEach(model.categories) { category in
                    PresetCategoryCard(
                        category: category,
                        status: model.status(of: category),
                        onOpen: { selected = category },
                        onStart: { model.start(category) },
                        onPause: { model.pause(category) }
                    )
                }
            }
            .padding(.horizontal, DS.Spacing.screenPadding)
            .padding(.bottom, DS.Spacing.l)
        }
        .background(DS.Color.ground)
        .navigationTitle("Preset categories")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selected) { category in
            PresetCategoryDetail(category: category, model: model)
        }
        .languageTheme(model.theme)
        .onAppear(perform: model.refresh)
        .onChange(of: model.languageCode) { model.refresh() }
    }
}

/// Every card in one category, playable, with the status button.
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
            PresetStatusButton(
                status: model.status(of: category),
                onStart: { model.start(category) },
                onPause: { model.pause(category) }
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
    let dependencies = AppDependencies.preview()
    NavigationStack { PresetCategoriesScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "id"
    try? dependencies.presetLibrary.start("numbers", in: "id")
    return NavigationStack { PresetCategoriesScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ko"
    return NavigationStack { PresetCategoriesScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ja"
    return NavigationStack { PresetCategoriesScreen(dependencies: dependencies) }
        .dependencies(dependencies)
        .preferredColorScheme(.dark)
}
