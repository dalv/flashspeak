import Foundation
import Observation

/// A flashcard session: due cards, then today's new cards, rated Hard or
/// Easy (decision 0005). Each rating updates the card's FSRS state and
/// appends a `ReviewLog`.
@MainActor
@Observable
final class FlashcardsModel {
    private(set) var queue: [Phrase] = []
    private(set) var position = 0
    private(set) var isFlipped = false
    private(set) var reviewedCount = 0
    private(set) var isPlaying = false
    private(set) var highlightedWord: Int?
    private(set) var sections: [PhraseSection] = [.all]
    private(set) var errorMessage: String?

    var section: PhraseSection = .all {
        didSet {
            guard section != oldValue else { return }
            load()
        }
    }

    @ObservationIgnored let dependencies: AppDependencies
    @ObservationIgnored private var playback: Task<Void, Never>?

    /// A card rated Hard comes back in this session if it is due within this window.
    static let requeueWindow: TimeInterval = 15 * 60

    init(dependencies: AppDependencies, section: PhraseSection = .all) {
        self.dependencies = dependencies
        self.section = section
    }

    var languageCode: String {
        dependencies.settings.currentLanguageCode
    }

    var isReversed: Bool {
        get { dependencies.settings.reverseFlashcards }
        set {
            dependencies.settings.reverseFlashcards = newValue
            isFlipped = false
            if newValue {
                playFront()
            }
        }
    }

    var current: Phrase? {
        queue.indices.contains(position) ? queue[position] : nil
    }

    var remaining: Int {
        max(queue.count - position, 0)
    }

    var isFinished: Bool {
        current == nil
    }

    // MARK: - Loading

    func load(now: Date = .now) {
        stopPlayback()
        let code = languageCode
        sections = PhraseSection.reviewable(in: code, phrases: dependencies.phrases)
        if !sections.contains(section) {
            section = .all
        }
        do {
            let introduced = try dependencies.reviews.newCardsIntroduced(
                in: code,
                since: Calendar.current.startOfDay(for: now)
            )
            let limit = dependencies.settings.settings(for: code).dailyNewCardLimit
            queue = try dependencies.phrases.due(
                in: code,
                section: section,
                now: now,
                newLimit: max(limit - introduced, 0)
            )
            errorMessage = nil
        } catch {
            queue = []
            errorMessage = "Couldn't load your cards."
        }
        position = 0
        isFlipped = false
        if isReversed {
            playFront()
        }
    }

    /// When the next card in this section is due, for "All caught up".
    func nextDue(after now: Date = .now) -> Date? {
        let phrases = (try? dependencies.phrases.phrases(in: languageCode, section: section, sort: .newest)) ?? []
        return phrases
            .filter { !$0.hiddenFromReview && $0.fsrsState != nil && $0.fsrsState != CardState.Phase.new.rawValue }
            .map(\.nextReviewAt)
            .filter { $0 > now }
            .min()
    }

    // MARK: - Reviewing

    func flip() {
        guard current != nil, !isFlipped else { return }
        isFlipped = true
        if dependencies.settings.autoPlay {
            play()
        }
    }

    /// What each rating button says, e.g. "Again soon" or "In 4 days".
    func intervalText(for rating: ReviewRating, now: Date = .now) -> String {
        guard let current else { return "" }
        let next = dependencies.scheduler.next(current.cardState, rating: rating, now: now)
        return ReviewIntervalText.text(from: now, to: next.due)
    }

    func rate(_ rating: ReviewRating, now: Date = .now) {
        guard let phrase = current, isFlipped else { return }
        stopPlayback()
        let scheduler = dependencies.scheduler
        let next = scheduler.next(phrase.cardState, rating: rating, now: now)
        phrase.cardState = next
        phrase.schedulerVersion = scheduler.version
        phrase.updatedAt = now
        do {
            try dependencies.reviews.append(
                ReviewLog(phrase: phrase, rating: rating, mode: .flashcard, after: next, schedulerVersion: scheduler.version, at: now)
            )
        } catch {
            errorMessage = "Couldn't save that review."
        }
        reviewedCount += 1
        if next.due.timeIntervalSince(now) <= Self.requeueWindow {
            queue.append(phrase)
        }
        position += 1
        isFlipped = false
        if isReversed {
            playFront()
        }
    }

    // MARK: - Audio

    func play() {
        guard let phrase = current else { return }
        if isPlaying {
            stopPlayback()
            return
        }
        speak(phrase.targetText, speed: dependencies.settings.defaultSpeed, highlightingIn: phrase)
    }

    func playWordByWord() {
        guard let phrase = current else { return }
        stopPlayback()
        speak(phrase.targetText, speed: .wordByWord, highlightingIn: phrase)
    }

    func playWord(at index: Int) {
        guard let phrase = current, phrase.gloss.indices.contains(index) else { return }
        stopPlayback()
        let word = phrase.gloss[index].target
        highlightedWord = index
        playback = Task {
            await dependencies.speech.speak(word, role: .target(phrase.languageCode), speed: .slow)
            if highlightedWord == index {
                highlightedWord = nil
            }
        }
    }

    /// In reverse mode the front is listening only, so it plays on arrival.
    private func playFront() {
        guard let phrase = current else { return }
        stopPlayback()
        speak(phrase.targetText, speed: dependencies.settings.defaultSpeed, highlightingIn: nil)
    }

    func stopPlayback() {
        playback?.cancel()
        playback = nil
        dependencies.speech.stop()
        isPlaying = false
        highlightedWord = nil
    }

    private func speak(_ text: String, speed: PlaybackSpeed, highlightingIn phrase: Phrase?) {
        isPlaying = true
        let gloss = phrase?.gloss ?? []
        playback = Task {
            await dependencies.speech.speak(text, role: .target(languageCode), speed: speed) { [weak self] range in
                self?.highlightedWord = GlossHighlighter.index(of: range, in: text, gloss: gloss)
            }
            guard !Task.isCancelled else { return }
            isPlaying = false
            highlightedWord = nil
        }
    }
}
