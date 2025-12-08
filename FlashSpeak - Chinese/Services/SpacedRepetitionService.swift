import Foundation

class SpacedRepetitionService {
    static let shared = SpacedRepetitionService()
    
    private init() {}
    
    enum Rating {
        case hard
        case easy
    }
    
    /// Updates a phrase's spaced repetition values based on user rating
    func updatePhrase(_ phrase: Phrase, rating: Rating) {
        let now = Date()
        phrase.lastReviewedAt = now
        
        switch rating {
        case .hard:
            // Reset repetitions, short interval, decrease ease factor
            phrase.repetitions = 0
            phrase.interval = 1.0 / 1440.0 // 1 minute in days (for same-session retry)
            phrase.easeFactor = max(1.3, phrase.easeFactor - 0.2)
            
        case .easy:
            phrase.repetitions += 1
            
            if phrase.repetitions == 1 {
                // First successful review
                phrase.interval = 1.0 // 1 day
            } else if phrase.repetitions == 2 {
                // Second successful review
                phrase.interval = 6.0 // 6 days
            } else {
                // Subsequent reviews: multiply by ease factor
                phrase.interval = phrase.interval * phrase.easeFactor
            }
            
            // Slightly increase ease factor on easy ratings
            phrase.easeFactor = min(3.0, phrase.easeFactor + 0.1)
        }
        
        // Calculate next review date
        phrase.nextReviewAt = now.addingTimeInterval(phrase.interval * 24 * 60 * 60)
    }
    
    /// Returns phrases that are due for review, ordered by most overdue first
    func getDuePhrases(from phrases: [Phrase]) -> [Phrase] {
        let now = Date()
        return phrases
            .filter { $0.nextReviewAt <= now }
            .sorted { $0.nextReviewAt < $1.nextReviewAt }
    }
    
    /// Returns the next review date from a list of phrases (for "nothing to review" screen)
    func getNextReviewDate(from phrases: [Phrase]) -> Date? {
        let now = Date()
        return phrases
            .filter { $0.nextReviewAt > now }
            .map { $0.nextReviewAt }
            .min()
    }
}
