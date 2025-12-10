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
    
    enum ViewState {
            case loading
            case showEnglish
            case showPinyin
            case revealingHanzi
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
            case .showPinyin:
                pinyinView
            case .revealingHanzi:
                hanziRevealView
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
            
            Button(action: revealPinyin) {
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
    
    private var pinyinView: some View {
        VStack(spacing: 30) {
            Text(currentPhrase?.englishText ?? "")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
            
            Text(currentPhrase?.pinyin ?? "")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()
            
            // Literal translation
            if let literal = currentPhrase?.literalTranslation, !literal.isEmpty {
                Text(literal)
                    .font(.body)
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: speakChinese) {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.title)
                    .padding()
                    .background(Circle().fill(Color.blue.opacity(0.1)))
            }
            
            Spacer().frame(height: 40)
            
            Button(action: startHanziReveal) {
                Text("Tap for hanzi")
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
                speakChinese()
            }
        }
    }

    private var hanziRevealView: some View {
            let hanzi = currentPhrase?.hanzi ?? ""
            let characters = Array(hanzi)
            let totalCharacters = characters.count
            let allRevealed = revealedCharacterCount >= totalCharacters
            
            return VStack(spacing: 30) {
                Text(currentPhrase?.englishText ?? "")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Text(currentPhrase?.pinyin ?? "")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                
                Button(action: speakChinese) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title2)
                        .padding(8)
                        .background(Circle().fill(Color.blue.opacity(0.1)))
                }
                
                Divider()
                
                // Hanzi with partial reveal
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
                    // Show rating buttons immediately
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

    private var emptyView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            
            Text("All caught up!")
                .font(.title)
            
            if let nextDate = SpacedRepetitionService.shared.getNextReviewDate(from: allPhrases) {
                Text("Next review: \(nextDate.formatted(.relative(presentation: .named)))")
                    .font(.body)
                    .foregroundStyle(.secondary)
            } else if allPhrases.isEmpty {
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
        duePhrases = SpacedRepetitionService.shared.getDuePhrases(from: allPhrases)
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
    
    private func revealPinyin() {
        currentState = .showPinyin
    }
    
    private func startHanziReveal() {
        revealedCharacterCount = 0
        currentState = .revealingHanzi
    }
    
    private func revealNextCharacter() {
        let totalCharacters = currentPhrase?.hanzi.count ?? 0
        if revealedCharacterCount < totalCharacters {
            revealedCharacterCount += 1
        }
    }
    
    private func speakChinese() {
        if let hanzi = currentPhrase?.hanzi {
            ChineseTTSService.shared.speak(hanzi)
        }
    }
    
    private func ratePhrase(_ rating: SpacedRepetitionService.Rating) {
        guard let phrase = currentPhrase else { return }
        
        // Update the phrase with new SR values
        SpacedRepetitionService.shared.updatePhrase(phrase, rating: rating)
        
        // Remove from due list and load next
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
