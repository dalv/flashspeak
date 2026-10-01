import SwiftUI

/// The home screen: language picker, New phrase, and the two review actions.
struct HomeScreen: View {
    @State private var model: HomeModel
    @State private var path: [HomeRoute] = []
    @State private var newPhrase: NewPhraseModel?

    init(dependencies: AppDependencies) {
        _model = State(initialValue: HomeModel(dependencies: dependencies))
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(spacing: DS.Spacing.l) {
                    SegmentedControl(
                        selection: $model.languageCode,
                        options: Language.supportedCodes,
                        variant: .glassAccent
                    ) { code in
                        let theme = LanguageTheme.forCode(code) ?? .mandarin
                        Text(theme.nativeName)
                            .nativeTextStyle(.segment, script: theme.script)
                            .accessibilityLabel(theme.displayName)
                    }

                    HomeHeroCard(action: openNewPhrase)

                    HStack(spacing: DS.Spacing.s) {
                        HomeActionTile(
                            title: "Audio recall",
                            systemImage: "headphones",
                            detail: Text("\(model.phraseCount) phrases · hands-free")
                        ) { path.append(.audioRecall) }
                        HomeActionTile(
                            title: "Flashcards",
                            systemImage: "rectangle.on.rectangle",
                            detail: Text("\(Text("\(model.dueCount)").foregroundStyle(model.theme.accentText).bold()) due today")
                        ) { path.append(.flashcards) }
                    }
                    .disabled(model.isEmpty)

                    if model.isEmpty {
                        VStack(spacing: DS.Spacing.s) {
                            Text("Add a phrase, try suggested phrases, or start a preset category such as Numbers to begin practising.")
                                .appTextStyle(.secondary)
                                .foregroundStyle(DS.Color.inkSecondary)
                                .multilineTextAlignment(.center)
                            Button("Browse preset categories", systemImage: HomeRoute.presetCategories.systemImage) {
                                path.append(.presetCategories)
                            }
                            .buttonStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.screenPadding)
                .padding(.bottom, DS.Spacing.l)
            }
            .background(DS.Color.ground)
            .safeAreaBar(edge: .bottom) {
                HomeFreeCountFooter(remaining: model.translationsRemaining)
            }
            .navigationTitle("FlashSpeak")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Menu", systemImage: "line.3.horizontal") {
                        ForEach([HomeRoute.manageCards, .presetCategories, .settings], id: \.self) { route in
                            Button(route.title, systemImage: route.systemImage) { path.append(route) }
                        }
                    }
                    .tint(DS.Color.ink)
                }
            }
            .navigationDestination(for: HomeRoute.self) { route in
                destination(for: route)
            }
        }
        .languageTheme(model.theme)
        .fullScreenCover(item: $newPhrase, onDismiss: { model.refresh() }) { newPhrase in
            NewPhraseFlow(model: newPhrase)
                .languageTheme(model.theme)
        }
        .onAppear { model.refresh() }
        .task { await model.refreshReminder() }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPractice)) { _ in
            newPhrase = nil
            path = [.flashcards]
        }
    }

    @ViewBuilder
    private func destination(for route: HomeRoute) -> some View {
        switch route {
        case .flashcards:
            FlashcardsScreen(dependencies: model.dependencies) {
                path = [.audioRecall]
            }
        case .settings:
            SettingsScreen(dependencies: model.dependencies)
        case .audioRecall:
            AudioRecallScreen(dependencies: model.dependencies)
        case .manageCards:
            ManageCardsScreen(dependencies: model.dependencies)
        case .presetCategories:
            PresetCategoriesScreen(dependencies: model.dependencies)
        }
    }

    private func openNewPhrase() {
        newPhrase = model.makeNewPhrase()
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    HomeScreen(dependencies: dependencies).dependencies(dependencies)
}

#Preview("Indonesian, free", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "id"
    return HomeScreen(dependencies: dependencies).dependencies(dependencies)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview(isPro: true)
    dependencies.settings.currentLanguageCode = "ko"
    return HomeScreen(dependencies: dependencies).dependencies(dependencies)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview(isPro: true)
    dependencies.settings.currentLanguageCode = "ja"
    return HomeScreen(dependencies: dependencies).dependencies(dependencies)
        .preferredColorScheme(.dark)
}
