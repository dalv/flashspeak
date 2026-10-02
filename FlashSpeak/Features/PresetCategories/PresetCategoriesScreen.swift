import SwiftUI

/// Ready-made categories of basic vocabulary. Browse and play freely; add
/// a category to flashcards, audio recall or both.
struct PresetCategoriesScreen: View {
    @State private var model: PresetCategoriesModel
    @State private var selected: PresetCategoryContent?

    init(dependencies: AppDependencies) {
        _model = State(initialValue: PresetCategoriesModel(dependencies: dependencies))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.m) {
                Text("Basic words every learner needs. Add a category to flashcards, audio recall or both, and remove it any time.")
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
                        membership: model.membership(of: category),
                        pending: model.pendingChange(for: category),
                        onOpen: { selected = category },
                        onToggle: { set in model.toggle(category, in: set) },
                        onConfirm: model.confirm,
                        onDismiss: model.dismissChange
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

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    NavigationStack { PresetCategoriesScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "id"
    try? dependencies.presetLibrary.add("numbers", to: .flashcards, in: "id")
    try? dependencies.presetLibrary.add("numbers", to: .recall, in: "id")
    try? dependencies.presetLibrary.add("days", to: .recall, in: "id")
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
