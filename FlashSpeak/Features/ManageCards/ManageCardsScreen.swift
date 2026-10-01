import SwiftUI

/// Every phrase in the current language, by section, with search and sort.
struct ManageCardsScreen: View {
    @State private var model: ManageCardsModel
    @State private var selected: Phrase?
    @State private var confirmsDeleteAll = false

    init(dependencies: AppDependencies) {
        _model = State(initialValue: ManageCardsModel(dependencies: dependencies))
    }

    init(model: ManageCardsModel) {
        _model = State(initialValue: model)
    }

    var body: some View {
        List {
            if model.sections.count > 1 {
                Section {
                    sectionChips
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            Section {
                if model.rows.isEmpty {
                    emptyRow
                } else {
                    ForEach(model.rows) { phrase in
                        row(for: phrase)
                    }
                }
            } header: {
                Text(countText)
                    .appTextStyle(.sectionLabel)
                    .foregroundStyle(DS.Color.inkSecondary)
            }
            .dsListRows()

            if model.totalCount > 0, model.section == .userPhrases {
                Section {
                    Button("Delete all \(model.theme.displayName) phrases", role: .destructive) {
                        confirmsDeleteAll = true
                    }
                    .frame(maxWidth: .infinity)
                }
                .dsListRows()
            }
        }
        .dsGroupedList()
        .searchable(text: $model.searchText, prompt: "Search phrases")
        .navigationTitle("Manage cards")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("Sort", systemImage: "arrow.up.arrow.down") {
                    Picker("Sort", selection: $model.sort) {
                        ForEach(PhraseSort.allCases, id: \.self) { sort in
                            Text(sort.title).tag(sort)
                        }
                    }
                }
                .tint(DS.Color.ink)
            }
        }
        .safeAreaBar(edge: .bottom) {
            if model.recentlyDeleted != nil {
                UndoBar(onUndo: model.undoDelete)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.default, value: model.recentlyDeleted != nil)
        .navigationDestination(item: $selected) { phrase in
            PhraseDetailScreen(phrase: phrase, dependencies: model.dependencies) {
                model.delete(phrase)
                selected = nil
            }
        }
        .sheet(isPresented: $confirmsDeleteAll) {
            DeleteAllSheet(
                languageName: model.deleteAllConfirmation,
                count: model.totalCount,
                isValid: model.canDeleteAll(typed:),
                onDelete: { model.deleteAll(typed: $0) }
            )
        }
        .languageTheme(model.theme)
        .onAppear(perform: model.reload)
        .onDisappear(perform: model.stopPlayback)
    }

    private var sectionChips: some View {
        ScrollView(.horizontal) {
            HStack(spacing: DS.Spacing.xs) {
                ForEach(model.sections, id: \.self) { section in
                    Chip(section.title, isSelected: model.section == section) {
                        model.section = section
                    }
                }
            }
            .padding(.vertical, DS.Spacing.xxs)
        }
        .scrollIndicators(.hidden)
    }

    private func row(for phrase: Phrase) -> some View {
        Button {
            selected = phrase
        } label: {
            PhraseRow(phrase.content, isPlaying: model.playingID == phrase.persistentModelID) {
                model.play(phrase)
            }
            .opacity(phrase.hiddenFromReview ? DS.Size.disabledOpacity * 1.5 : 1)
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .trailing) {
            if phrase.isPreset {
                Button(phrase.hiddenFromReview ? "Restore" : "Hide", systemImage: phrase.hiddenFromReview ? "eye" : "eye.slash") {
                    model.toggleHidden(phrase)
                }
                .tint(DS.Color.inkSecondary)
            } else {
                Button("Delete", systemImage: "trash", role: .destructive) {
                    model.delete(phrase)
                }
            }
        }
        .accessibilityHint(phrase.hiddenFromReview ? "Hidden from review" : "")
    }

    @ViewBuilder
    private var emptyRow: some View {
        if model.searchText.isEmpty {
            ContentUnavailableView("No phrases here yet", systemImage: "rectangle.on.rectangle")
                .foregroundStyle(DS.Color.inkSecondary)
        } else {
            ContentUnavailableView.search
        }
    }

    private var countText: String {
        let shown = model.searchText.isEmpty ? model.totalCount : model.rows.count
        let noun = shown == 1 ? "phrase" : "phrases"
        if model.isPresetSection {
            let hidden = model.rows.count(where: \.hiddenFromReview)
            return hidden > 0 ? "\(shown) \(noun) · \(hidden) hidden" : "\(shown) \(noun)"
        }
        return "\(shown) \(noun)"
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    NavigationStack { ManageCardsScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "id"
    return NavigationStack { ManageCardsScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ko"
    return NavigationStack { ManageCardsScreen(dependencies: dependencies) }
        .dependencies(dependencies)
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    let dependencies = AppDependencies.preview()
    dependencies.settings.currentLanguageCode = "ja"
    return NavigationStack { ManageCardsScreen(dependencies: dependencies) }
        .dependencies(dependencies)
        .preferredColorScheme(.dark)
}
