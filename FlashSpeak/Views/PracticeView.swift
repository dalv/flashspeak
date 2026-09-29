import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var allPhrases: [Phrase]

    @ObservedObject private var settings = SettingsManager.shared

    @State private var currentPhrase: Phrase?
    @State private var duePhrases: [Phrase] = []
    @State private var currentState: ViewState = .loading
    @State private var revealedCharacterCount: Int = 0

    private var language: Language { settings.currentLanguage }

    private var currentLanguagePhrases: [Phrase] {
        allPhrases.filter { $0.languageCode == settings.currentLanguageCode }
    }

    enum ViewState {
        case loading
        case showEnglish
        case showPronunciation
        case revealingScript
        case showAnswer
        case empty
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            switch currentState {
            case .loading:
                ProgressView()
            case .showEnglish:
                englishView
            case .showPronunciation:
                pronunciationView
            case .revealingScript:
                scriptRevealView
            case .showAnswer:
                answerView
            case .empty:
                emptyView
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Home") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadDuePhrases()
        }
    }

    // MARK: - State Views

    private var englishView: some View {
        VStack(spacing: 30) {
            Text("How do you say...")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(currentPhrase?.englishText ?? "")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            Spacer().frame(height: 40)

            Button(action: revealAnswer) {
                Text("Tap to reveal")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    // For languages with pronunciation guide (Chinese, Japanese, etc.)
    private var pronunciationView: some View {
        VStack(spacing: 30) {
            Text(currentPhrase?.englishText ?? "")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            Text(currentPhrase?.pronunciation ?? "")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            if let literal = currentPhrase?.literalTranslation, !literal.isEmpty {
                Text(literal)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: speakTranslation) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title)
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.1)))
            }

            Spacer().frame(height: 40)

            Button(action: startScriptReveal) {
                Text("Reveal characters")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
        .onAppear {
            if settings.autoPlayAudio {
                speakTranslation()
            }
        }
    }

    // For languages with pronunciation guide - progressive character reveal
    private var scriptRevealView: some View {
        let text = currentPhrase?.targetText ?? ""
        let characters = Array(text)
        let totalCharacters = characters.count
        let allRevealed = revealedCharacterCount >= totalCharacters

        return VStack(spacing: 30) {
            Text(currentPhrase?.englishText ?? "")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(currentPhrase?.pronunciation ?? "")
                .font(.title2)
                .multilineTextAlignment(.center)

            Button(action: speakTranslation) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title2)
                    .padding(8)
                    .background(Circle().fill(Color.blue.opacity(0.1)))
            }

            Divider()

            HStack(spacing: 4) {
                ForEach(0..<totalCharacters, id: \.self) { index in
                    Text(index < revealedCharacterCount ? String(characters[index]) : "?")
                        .font(.system(size: 44))
                        .frame(minWidth: 50)
                }
            }
            .padding()

            Spacer().frame(height: 40)

            if allRevealed {
                ratingButtons
            } else {
                Button(action: revealNextCharacter) {
                    Text("Tap for next character (\(revealedCharacterCount)/\(totalCharacters))")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
        }
    }

    // For languages without pronunciation guide - simple answer reveal
    private var answerView: some View {
        VStack(spacing: 30) {
            Text(currentPhrase?.englishText ?? "")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Divider()

            Text(currentPhrase?.targetText ?? "")
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()

            if let literal = currentPhrase?.literalTranslation, !literal.isEmpty {
                Text(literal)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button(action: speakTranslation) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title)
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.1)))
            }

            Spacer().frame(height: 40)

            ratingButtons
        }
        .onAppear {
            if settings.autoPlayAudio {
                speakTranslation()
            }
        }
    }

    private var ratingButtons: some View {
        VStack(spacing: 16) {
            Text("How was your recall?")
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(spacing: 20) {
                Button(action: { ratePhrase(.hard) }) {
                    Text("Hard")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { ratePhrase(.easy) }) {
                    Text("Easy")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("All caught up!")
                .font(.title)

            if let nextDate = SpacedRepetitionService.shared.getNextReviewDate(from: currentLanguagePhrases) {
                Text("Next review: \(nextDate.formatted(.relative(presentation: .named)))")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else if currentLanguagePhrases.isEmpty {
                Text("Add some phrases to get started!")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Button(action: { dismiss() }) {
                Text("Back to Home")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Actions

    private func loadDuePhrases() {
        duePhrases = SpacedRepetitionService.shared.getDuePhrases(from: currentLanguagePhrases)
        loadNextPhrase()
    }

    private func loadNextPhrase() {
        revealedCharacterCount = 0

        if let next = duePhrases.first {
            currentPhrase = next
            currentState = .showEnglish
        } else {
            currentPhrase = nil
            currentState = .empty
        }
    }

    private func revealAnswer() {
        if language.hasPronunciationGuide {
            currentState = .showPronunciation
        } else {
            currentState = .showAnswer
        }
    }

    private func startScriptReveal() {
        revealedCharacterCount = 0
        currentState = .revealingScript
    }

    private func revealNextCharacter() {
        let totalCharacters = currentPhrase?.targetText.count ?? 0
        if revealedCharacterCount < totalCharacters {
            revealedCharacterCount += 1
        }
    }

    private func speakTranslation() {
        if let text = currentPhrase?.targetText {
            TTSService.shared.speak(text, language: language)
        }
    }

    private func ratePhrase(_ rating: SpacedRepetitionService.Rating) {
        guard let phrase = currentPhrase else { return }

        SpacedRepetitionService.shared.updatePhrase(phrase, rating: rating)

        duePhrases.removeAll { $0.id == phrase.id }
        loadNextPhrase()
    }
}

#Preview {
    NavigationStack {
        PracticeView()
    }
    .modelContainer(for: Phrase.self, inMemory: true)
}
