import Foundation
import Observation

/// Suggested phrases for one situation: request a batch at the set's level,
/// drop anything already in the set, play them in sequence, save the ticked ones.
@MainActor
@Observable
final class SuggestModel: Identifiable, Hashable {
    nonisolated static func == (lhs: SuggestModel, rhs: SuggestModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    struct Item: Identifiable, Equatable {
        let id = UUID()
        let english: String
        let translation: TranslationResult
        var isIncluded = true
    }

    static let batchSize = 5

    let category: String
    let languageCode: String
    let level: Int
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    /// Index into `items` of the phrase playing now.
    private(set) var playingIndex: Int?
    var showsPaywall = false

    @ObservationIgnored private let dependencies: AppDependencies
    @ObservationIgnored private var playTask: Task<Void, Never>?

    init(category: String, dependencies: AppDependencies) {
        self.category = category
        self.dependencies = dependencies
        languageCode = dependencies.settings.currentLanguageCode
        level = Self.setLevel(dependencies: dependencies, languageCode: languageCode)
    }

    static func setLevel(dependencies: AppDependencies, languageCode: String) -> Int {
        let phrases = (try? dependencies.phrases.phrases(in: languageCode, section: .userPhrases, sort: .newest)) ?? []
        return SetLevel.current(
            levels: phrases.map(\.level),
            override: dependencies.settings.settings(for: languageCode).levelOverride
        )
    }

    var includedCount: Int {
        items.filter(\.isIncluded).count
    }

    var isPlaying: Bool {
        playingIndex != nil
    }

    // MARK: - Loading

    /// Loads a batch of five. A batch counts as one free translation.
    func loadBatch() async {
        guard !isLoading else { return }
        if dependencies.usage.translationsRemainingToday == 0 {
            showsPaywall = true
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let firstNew = items.count
        do {
            var fresh = try await request(count: Self.batchSize)
            // Replace anything filtered out, once.
            if fresh.count < Self.batchSize {
                fresh += try await request(count: Self.batchSize - fresh.count, alsoExcluding: fresh.map(\.english))
            }
            dependencies.usage.recordTranslation()
            items += fresh.prefix(Self.batchSize)
            if items.count > firstNew {
                playAll(from: firstNew)
            }
        } catch .limitReached {
            showsPaywall = true
        } catch {
            errorMessage = error.userMessage
        }
    }

    private func request(count: Int, alsoExcluding extra: [String] = []) async throws(TranslationError) -> [Item] {
        let existing = (try? dependencies.phrases.phrases(in: languageCode, section: .all, sort: .newest)) ?? []
        let settings = dependencies.settings.settings(for: languageCode)
        let suggestions = try await dependencies.translation.suggest(SuggestionRequest(
            language: languageCode,
            category: category,
            level: level,
            register: settings.register,
            existing: existing.map(\.englishText) + items.map(\.english) + extra,
            count: count
        ))
        let detector = DuplicateDetector(embeddings: dependencies.embeddings)
        let shown = items.map { ExactDuplicateMatcher.Candidate(english: $0.english, target: $0.translation.targetText) }
            + extra.map { ExactDuplicateMatcher.Candidate(english: $0, target: "") }
        return suggestions
            .filter { detector.check(english: $0.english, target: $0.translation.targetText, among: existing) == .none }
            .filter { ExactDuplicateMatcher.firstMatch(english: $0.english, target: $0.translation.targetText, in: shown) == nil }
            .map { Item(english: $0.english, translation: $0.translation) }
    }

    // MARK: - Selection

    func toggle(_ id: Item.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isIncluded.toggle()
    }

    // MARK: - Playback

    /// Plays the phrases from `start` in sequence at slow speed.
    func playAll(from start: Int = 0) {
        stopPlayback()
        let speech = dependencies.speech
        let language = languageCode
        let texts = items.map(\.translation.targetText)
        playTask = Task { [weak self] in
            for index in start ..< texts.count {
                guard !Task.isCancelled else { break }
                self?.playingIndex = index
                await speech.speak(texts[index], role: .target(language), speed: .slow)
                try? await Task.sleep(for: .milliseconds(400))
            }
            if !Task.isCancelled {
                self?.playingIndex = nil
            }
        }
    }

    func play(_ id: Item.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        if playingIndex == index {
            stopPlayback()
            return
        }
        stopPlayback()
        let speech = dependencies.speech
        let text = items[index].translation.targetText
        let language = languageCode
        playingIndex = index
        playTask = Task { [weak self] in
            await speech.speak(text, role: .target(language), speed: .slow)
            if !Task.isCancelled {
                self?.playingIndex = nil
            }
        }
    }

    func togglePlayAll() {
        isPlaying ? stopPlayback() : playAll()
    }

    func stopPlayback() {
        playTask?.cancel()
        playTask = nil
        dependencies.speech.stop()
        playingIndex = nil
    }

    // MARK: - Saving

    /// Saves the ticked phrases as user phrases. Returns how many were saved.
    @discardableResult
    func save(now: Date = .now) -> Int {
        stopPlayback()
        var saved = 0
        for (offset, item) in items.enumerated() where item.isIncluded {
            let result = ResultModel(english: item.english, source: .suggested, translation: item.translation, dependencies: dependencies)
            // Keep the list order as creation order.
            let phrase = result.makePhrase(now: now.addingTimeInterval(Double(offset) / 1000))
            if (try? dependencies.phrases.insert(phrase)) != nil {
                saved += 1
            }
        }
        return saved
    }
}
