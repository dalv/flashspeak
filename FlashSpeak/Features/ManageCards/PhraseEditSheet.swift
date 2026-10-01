import SwiftUI

/// Edits a saved phrase's text by hand. The schedule and history are kept.
struct PhraseEditSheet: View {
    let phrase: Phrase
    let dependencies: AppDependencies

    @State private var english: String
    @State private var target: String
    @State private var romanization: String
    @State private var reading: String
    @State private var usageNote: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.languageTheme) private var theme

    init(phrase: Phrase, dependencies: AppDependencies) {
        self.phrase = phrase
        self.dependencies = dependencies
        _english = State(initialValue: phrase.englishText)
        _target = State(initialValue: phrase.targetText)
        _romanization = State(initialValue: phrase.pronunciation)
        _reading = State(initialValue: phrase.reading ?? "")
        _usageNote = State(initialValue: phrase.usageNote ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("English") {
                    TextField("English", text: $english, axis: .vertical)
                }
                Section(theme.displayName) {
                    TextField("Translation", text: $target, axis: .vertical)
                        .nativeTextStyle(.row, script: theme.script)
                    if phrase.languageCode == "ja" {
                        TextField("Kana reading", text: $reading, axis: .vertical)
                    }
                    if phrase.languageCode != "id" {
                        TextField("Romanization", text: $romanization, axis: .vertical)
                    }
                }
                Section("Usage note") {
                    TextField("Optional", text: $usageNote, axis: .vertical)
                }
            }
            .dsGroupedList()
            .navigationTitle("Edit card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", systemImage: "checkmark", action: save)
                        .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !english.trimmed.isEmpty && !target.trimmed.isEmpty
    }

    private func save() {
        let newEnglish = english.trimmed
        if newEnglish != phrase.englishText {
            phrase.embedding = dependencies.embeddings.embedding(for: newEnglish).map(EmbeddingCoding.encode)
        }
        let newTarget = target.trimmed
        if newTarget != phrase.targetText {
            // The word-by-word gloss no longer matches hand-edited text.
            phrase.gloss = []
        }
        phrase.englishText = newEnglish
        phrase.targetText = newTarget
        phrase.pronunciation = romanization.trimmed
        phrase.reading = reading.trimmed.isEmpty ? nil : reading.trimmed
        phrase.usageNote = usageNote.trimmed.isEmpty ? nil : usageNote.trimmed
        phrase.updatedAt = .now
        try? dependencies.phrases.save()
        dismiss()
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview("Mandarin", traits: .modifier(DesignSystemPreview())) {
    PhraseEditPreview(languageCode: "zh-CN")
}

#Preview("Indonesian", traits: .modifier(DesignSystemPreview())) {
    PhraseEditPreview(languageCode: "id")
}

#Preview("Korean", traits: .modifier(DesignSystemPreview())) {
    PhraseEditPreview(languageCode: "ko")
}

#Preview("Japanese, dark", traits: .modifier(DesignSystemPreview())) {
    PhraseEditPreview(languageCode: "ja")
        .preferredColorScheme(.dark)
}

private struct PhraseEditPreview: View {
    let languageCode: String
    @State private var dependencies = AppDependencies.preview()

    var body: some View {
        if let phrase = try? dependencies.phrases.phrases(in: languageCode, section: .all, sort: .newest).first {
            PhraseEditSheet(phrase: phrase, dependencies: dependencies)
                .languageTheme(LanguageTheme.forCode(languageCode) ?? .mandarin)
        }
    }
}
