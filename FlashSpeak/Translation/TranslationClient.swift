/// Translation, clarification and suggestions, through the Worker.
protocol TranslationClient: Sendable {
    func translate(_ request: TranslationRequest) async throws(TranslationError) -> TranslationResult
    func clarify(_ request: ClarificationRequest) async throws(TranslationError) -> ClarificationResult
    func suggest(_ request: SuggestionRequest) async throws(TranslationError) -> [SuggestedPhrase]
    func flag(_ report: TranslationFlag) async throws(TranslationError)
}
