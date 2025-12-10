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
    @State private var translationResult: TranslationService.TranslationResult?
    @State private var errorMessage: String?
    
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
            
            // Show remaining translations for free users
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
            // Animated listening indicator
            PulsingCircle()
                .frame(width: 120, height: 120)
            
            Text("Listening...")
                .font(.title2)
                .foregroundStyle(.secondary)
            
            // Live transcription
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
            
            // Pinyin
            VStack(spacing: 4) {
                Text("Pinyin")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(translationResult?.pinyin ?? "")
                    .font(.title2)
                    .multilineTextAlignment(.center)
            }
            
            // Hanzi
            VStack(spacing: 4) {
                Text("汉字")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(translationResult?.hanzi ?? "")
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
            Button(action: speakChinese) {
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
                speakChinese()
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
        // Save the transcribed text BEFORE stopping
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
                let result = try await TranslationService.shared.translate(englishText, formality: settings.formality)
                translationResult = result
                currentState = .result
            } catch {
                errorMessage = error.localizedDescription
                currentState = .error
            }
        }
    }
    
    private func speakChinese() {
        if let hanzi = translationResult?.hanzi {
            ChineseTTSService.shared.speak(hanzi)
        }
    }
    
    private func retry() {
        // Keep the same English text, just re-translate
        if currentState == .result || (currentState == .error && !englishText.isEmpty) {
            currentState = .translating
            Task {
                do {
                    let result = try await TranslationService.shared.translate(englishText, formality: settings.formality)
                    translationResult = result
                    currentState = .result
                } catch {
                    errorMessage = error.localizedDescription
                    currentState = .error
                }
            }
        } else {
            // Start over completely
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
            hanzi: result.hanzi,
            pinyin: result.pinyin,
            literalTranslation: result.literalTranslation
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
