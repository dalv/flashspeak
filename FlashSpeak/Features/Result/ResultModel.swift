import Foundation
import Observation

/// One translated phrase on the result card, before it is saved: playback,
/// another version, clarifications with a way back, flagging and saving.
///
/// With `editing`, it works on a saved phrase (the full card in Manage
/// cards): each new version is written to that phrase straight away, and
/// its schedule and review history are kept.
@MainActor
@Observable
final class ResultModel: Identifiable, Hashable {
    nonisolated static func == (lhs: ResultModel, rhs: ResultModel) -> Bool {
        lhs === rhs
    }

    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

    enum SaveState: Equatable {
        case unsaved
        case saving
        case saved
        case failed(String)
    }

    let english: String
    let source: PhraseSource
    let languageCode: String
    let register: Register
    /// Identifies this phrase for the per-phrase clarification limit.
    let sessionKey: String
    /// The saved phrase being changed, if any.
    let editing: Phrase?

    private(set) var current: TranslationResult
    /// Earlier versions, most recent last; "Back to previous version" pops one.
    private(set) var previousVersions: [TranslationResult] = []
    private(set) var clarifications: [Clarification] = []

    var speed: PlaybackSpeed
    private(set) var isPlaying = false
    /// Index into `current.gloss` of the word being spoken.
    private(set) var highlightedWord: Int?
    private(set) var isRetrying = false
    private(set) var retryError: String?
    private(set) var saveState: SaveState = .unsaved
    private(set) var flagged = false
    /// Whether this phrase, as translated now, is already in the set.
    private(set) var duplicate: DuplicateCheck = .none

    @ObservationIgnored private let dependencies: AppDependencies

    init(english: String, source: PhraseSource, translation: TranslationResult, dependencies: AppDependencies) {
        self.english = english
        self.source = source
        current = translation
        self.dependencies = dependencies
        languageCode = dependencies.settings.currentLanguageCode
        register = dependencies.settings.settings(for: languageCode).register
        speed = dependencies.settings.defaultSpeed
        sessionKey = UUID().uuidString
        editing = nil
        refreshDuplicateCheck()
    }

    /// Works on a saved phrase.
    init(editing phrase: Phrase, dependencies: AppDependencies) {
        english = phrase.englishText
        source = phrase.phraseSource
        languageCode = phrase.languageCode
        register = dependencies.settings.settings(for: phrase.languageCode).register
        speed = dependencies.settings.defaultSpeed
        sessionKey = phrase.stableID?.uuidString ?? UUID().uuidString
        editing = phrase
        current = TranslationResult(
            targetText: phrase.targetText,
            romanization: phrase.pronunciation.isEmpty ? nil : phrase.pronunciation,
            reading: phrase.reading,
            gloss: phrase.gloss,
            literal: phrase.literalTranslation,
            alternative: phrase.alternative,
            usageNote: phrase.usageNote,
            level: phrase.level,
            promptVersion: phrase.promptVersion ?? ""
        )
        clarifications = phrase.clarifications
        saveState = .saved
        self.dependencies = dependencies
        refreshDuplicateCheck()
    }

    /// Exact duplicates can't be saved; near ones ask "Save anyway".
    var canSave: Bool {
        if case .exact = duplicate { return false }
        return true
    }

    func refreshDuplicateCheck() {
        let existing = ((try? dependencies.phrases.phrases(in: languageCode, section: .all, sort: .newest)) ?? [])
            .filter { $0 !== editing }
        duplicate = DuplicateDetector(embeddings: dependencies.embeddings)
            .check(english: english, target: current.targetText, among: existing)
    }

    var levelLabel: String? {
        current.level.map { LevelScale.label(for: $0, languageCode: languageCode) }
    }

    var canGoBack: Bool {
        !previousVersions.isEmpty
    }

    var clarificationsRemaining: Int? {
        dependencies.usage.clarificationsRemaining(forPhrase: sessionKey)
    }

    // MARK: - Playback

    func playIfAutoPlay() {
        guard dependencies.settings.autoPlay else { return }
        play()
    }

    func play() {
        let speech = dependencies.speech
        if isPlaying {
            speech.stop()
            return
        }
        let text = current.targetText
        isPlaying = true
        Task {
            await speech.speak(text, role: .target(languageCode), speed: speed) { [weak self] range in
                self?.highlight(range, in: text)
            }
            isPlaying = false
            highlightedWord = nil
        }
    }

    func playWord(at index: Int) {
        guard current.gloss.indices.contains(index) else { return }
        let word = current.gloss[index].target
        highlightedWord = index
        Task {
            await dependencies.speech.speak(word, role: .target(languageCode), speed: .slow)
            if highlightedWord == index {
                highlightedWord = nil
            }
        }
    }

    private func highlight(_ range: Range<String.Index>, in text: String) {
        if let index = GlossHighlighter.index(of: range, in: text, gloss: current.gloss) {
            highlightedWord = index
        }
    }

    // MARK: - Versions

    /// "Try another version": translates again; the current one stays reachable.
    func retry() async {
        guard !isRetrying else { return }
        isRetrying = true
        retryError = nil
        defer { isRetrying = false }
        do {
            let next = try await dependencies.translation.translate(
                TranslationRequest(english: english, language: languageCode, register: register)
            )
            replaceCurrent(with: next)
        } catch {
            retryError = error.userMessage
        }
    }

    /// Uses a candidate from a clarification.
    func apply(_ candidate: TranslationResult, clarification: String) {
        clarifications.append(Clarification(text: clarification, previousTargetText: current.targetText, date: .now))
        replaceCurrent(with: candidate)
    }

    /// Records a clarification that kept the current translation.
    func recordKept(clarification: String) {
        clarifications.append(Clarification(text: clarification, previousTargetText: current.targetText, date: .now))
        persistEdit()
    }

    func backToPreviousVersion() {
        guard let previous = previousVersions.popLast() else { return }
        dependencies.speech.stop()
        current = previous
        refreshDuplicateCheck()
        highlightedWord = nil
        persistEdit()
    }

    private func replaceCurrent(with next: TranslationResult) {
        dependencies.speech.stop()
        previousVersions.append(current)
        current = next
        refreshDuplicateCheck()
        highlightedWord = nil
        persistEdit()
        playIfAutoPlay()
    }

    /// Writes the current version to the saved phrase being edited. The
    /// FSRS fields and reviews are left alone.
    private func persistEdit(now: Date = .now) {
        guard let phrase = editing else { return }
        phrase.targetText = current.targetText
        phrase.pronunciation = current.romanization ?? ""
        phrase.reading = current.reading
        phrase.gloss = current.gloss
        phrase.literalTranslation = current.literal
        phrase.alternative = current.alternative
        phrase.usageNote = current.usageNote
        phrase.level = current.level
        phrase.promptVersion = current.promptVersion
        phrase.clarifications = clarifications
        phrase.updatedAt = now
        do {
            try dependencies.phrases.save()
        } catch {
            saveState = .failed("Couldn't save the change. Try again.")
        }
    }

    /// The history sent with the next clarification, oldest first.
    var clarificationHistory: [ClarificationTurn] {
        clarifications.map { ClarificationTurn(clarification: $0.text, targetText: $0.previousTargetText) }
    }

    // MARK: - Flag and save

    func flag(note: String? = nil) async {
        let report = TranslationFlag(
            english: english, language: languageCode, targetText: current.targetText,
            promptVersion: current.promptVersion, clarifications: clarifications.map(\.text), note: note
        )
        try? await dependencies.translation.flag(report)
        flagged = true
    }

    func save() {
        guard editing == nil, saveState != .saved, canSave else { return }
        saveState = .saving
        dependencies.speech.stop()
        do {
            try dependencies.phrases.insert(makePhrase())
            saveState = .saved
        } catch {
            saveState = .failed("Couldn't save the phrase. Try again.")
        }
    }

    func makePhrase(now: Date = .now) -> Phrase {
        let phrase = Phrase(
            englishText: english,
            targetText: current.targetText,
            pronunciation: current.romanization ?? "",
            literalTranslation: current.literal,
            languageCode: languageCode
        )
        phrase.stableID = UUID()
        phrase.phraseSource = source
        phrase.reading = current.reading
        phrase.gloss = current.gloss
        phrase.alternative = current.alternative
        phrase.usageNote = current.usageNote
        phrase.level = current.level
        phrase.promptVersion = current.promptVersion
        phrase.embedding = dependencies.embeddings.embedding(for: english).map(EmbeddingCoding.encode)
        phrase.clarifications = clarifications
        phrase.createdAt = now
        phrase.updatedAt = now
        phrase.cardState = .new(due: now)
        return phrase
    }
}

extension Error {
    /// A message to show; translation errors have their own.
    var userMessage: String {
        (self as? TranslationError)?.userMessage ?? "Something went wrong. Try again."
    }
}
