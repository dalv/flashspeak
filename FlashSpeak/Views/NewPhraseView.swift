import SwiftUI
import SwiftData

struct NewPhraseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var speechService = SpeechRecognitionService()
    @ObservedObject private var settings = SettingsManager.shared
    @ObservedObject private var usage = UsageManager.shared

    @State private var showingPaywall = false

    @State private var currentState: ViewState = .idle
    @State private var englishText: String = ""
    @State private var typedText: String = ""
    @State private var translationResult: TranslationService.TranslationResult?
    @State private var errorMessage: String?

    private var language: Language { settings.currentLanguage }

    enum ViewState {
        case idle
        case listening
        case translating
        case result
        case error
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            switch currentState {
            case .idle:
                idleView
            case .listening:
                listeningView
            case .translating:
                translatingView
            case .result:
                resultView
            case .error:
                errorView
            }

            Spacer()
        }
        .padding()
        .navigationTitle("New Phrase")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - State Views

    private var idleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Tap to start speaking")
                .font(.title2)
                .foregroundStyle(.secondary)

            if !usage.isSubscribed {
                Text("\(usage.remainingToday) free translations left today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(action: checkLimitAndStart) {
                Text("Start Recording")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(usage.canTranslate ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!usage.canTranslate)
            .padding(.horizontal, 40)

            if !usage.canTranslate {
                Button("Upgrade to Pro") {
                    showingPaywall = true
                }
                .font(.headline)
                .foregroundStyle(.blue)
            }

            // Type-in alternative
            VStack(spacing: 10) {
                Text("Can't talk right now? Type instead.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                TextField("Type a phrase in English...", text: $typedText)
                    .textFieldStyle(.roundedBorder)
                    .font(.subheadline)
                    .padding(.horizontal, 40)

                if !typedText.trimmingCharacters(in: .whitespaces).isEmpty {
                    Button(action: translateTypedText) {
                        Text("Translate")
                            .font(.subheadline)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 24)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .cornerRadius(8)
                    }
                    .disabled(!usage.canTranslate)
                }
            }
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
    }

    private func checkLimitAndStart() {
        if usage.canTranslate {
            startListening()
        } else {
            showingPaywall = true
        }
    }

    private var listeningView: some View {
        VStack(spacing: 20) {
            PulsingCircle()
                .frame(width: 120, height: 120)

            Text("Listening...")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(speechService.transcribedText.isEmpty ? "Say something in English" : speechService.transcribedText)
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding()
                .frame(minHeight: 100)

            Button(action: stopListeningAndTranslate) {
                Text("Done Speaking")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }

    private var translatingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(2)

            Text("Translating...")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
    }

    private var resultView: some View {
        VStack(spacing: 24) {
            // English
            VStack(spacing: 4) {
                Text("English")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(englishText)
                    .font(.title3)
                    .multilineTextAlignment(.center)
            }

            Divider()

            // Pronunciation (only for languages with pronunciation guide)
            if language.hasPronunciationGuide, let pronunciation = translationResult?.pronunciation, !pronunciation.isEmpty {
                VStack(spacing: 4) {
                    Text("Pronunciation")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(pronunciation)
                        .font(.title2)
                        .multilineTextAlignment(.center)
                }
            }

            // Target language text
            VStack(spacing: 4) {
                Text(language.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(translationResult?.targetText ?? "")
                    .font(.largeTitle)
                    .multilineTextAlignment(.center)
            }

            // Literal Translation
            if let literal = translationResult?.literalTranslation, !literal.isEmpty {
                VStack(spacing: 4) {
                    Text("Literal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(literal)
                        .font(.body)
                        .italic()
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            // Speaker button
            Button(action: speakTranslation) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title)
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.1)))
            }

            Spacer().frame(height: 20)

            // Action buttons
            HStack(spacing: 20) {
                Button(action: retry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: saveAndDismiss) {
                    Label("Save", systemImage: "checkmark")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            if settings.autoPlayAudio {
                speakTranslation()
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.red)

            Text("Something went wrong")
                .font(.title2)

            Text(errorMessage ?? "Unknown error")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 20) {
                Button(action: retry) {
                    Label("Retry", systemImage: "arrow.clockwise")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button(action: { dismiss() }) {
                    Label("Cancel", systemImage: "xmark")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Actions

    private func translateTypedText() {
        let trimmed = typedText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        englishText = trimmed
        currentState = .translating

        Task {
            do {
                let result = try await TranslationService.shared.translate(
                    englishText,
                    formality: settings.formality,
                    targetLanguage: settings.currentLanguageCode
                )
                translationResult = result
                currentState = .result
            } catch {
                errorMessage = error.localizedDescription
                currentState = .error
            }
        }
    }

    private func startListening() {
        Task {
            let permitted = await speechService.requestPermissions()
            if permitted {
                speechService.startListening()
                currentState = .listening
            } else {
                errorMessage = speechService.errorMessage ?? "Permission denied"
                currentState = .error
            }
        }
    }

    private func stopListeningAndTranslate() {
        englishText = speechService.transcribedText
        speechService.stopListening()

        guard !englishText.isEmpty else {
            errorMessage = "No speech detected. Please try again."
            currentState = .error
            return
        }

        currentState = .translating

        Task {
            do {
                let result = try await TranslationService.shared.translate(
                    englishText,
                    formality: settings.formality,
                    targetLanguage: settings.currentLanguageCode
                )
                translationResult = result
                currentState = .result
            } catch {
                errorMessage = error.localizedDescription
                currentState = .error
            }
        }
    }

    private func speakTranslation() {
        if let text = translationResult?.targetText {
            TTSService.shared.speak(text, language: language)
        }
    }

    private func retry() {
        if currentState == .result || (currentState == .error && !englishText.isEmpty) {
            currentState = .translating
            Task {
                do {
                    let result = try await TranslationService.shared.translate(
                        englishText,
                        formality: settings.formality,
                        targetLanguage: settings.currentLanguageCode
                    )
                    translationResult = result
                    currentState = .result
                } catch {
                    errorMessage = error.localizedDescription
                    currentState = .error
                }
            }
        } else {
            englishText = ""
            translationResult = nil
            errorMessage = nil
            currentState = .idle
        }
    }

    private func saveAndDismiss() {
        guard let result = translationResult else { return }

        let phrase = Phrase(
            englishText: englishText,
            targetText: result.targetText,
            pronunciation: result.pronunciation,
            literalTranslation: result.literalTranslation,
            languageCode: settings.currentLanguageCode
        )

        modelContext.insert(phrase)
        usage.recordTranslation()
        dismiss()
    }
}

// MARK: - Pulsing Circle Animation

struct PulsingCircle: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.2))
                .scaleEffect(isAnimating ? 1.3 : 1.0)
                .opacity(isAnimating ? 0.0 : 0.5)

            Circle()
                .fill(Color.red.opacity(0.4))
                .scaleEffect(isAnimating ? 1.15 : 1.0)
                .opacity(isAnimating ? 0.2 : 0.6)

            Circle()
                .fill(Color.red)
                .scaleEffect(0.7)

            Image(systemName: "mic.fill")
                .foregroundColor(.white)
                .font(.system(size: 30))
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        NewPhraseView()
    }
    .modelContainer(for: Phrase.self, inMemory: true)
}
