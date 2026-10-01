import AVFoundation

/// `VoiceCatalog` on Apple's installed voices: male for English, female for
/// the target language; Premium, then Enhanced, then default quality.
@MainActor
final class AppleVoiceCatalog: VoiceCatalog {
    private var cache: [VoiceRole: AVSpeechSynthesisVoice] = [:]

    func voice(for role: VoiceRole) -> AVSpeechSynthesisVoice? {
        if let cached = cache[role] {
            return cached
        }
        let chosen = Self.best(
            among: AVSpeechSynthesisVoice.speechVoices(),
            locale: Self.locale(for: role),
            gender: role == .english ? .male : .female
        )
        cache[role] = chosen
        return chosen
    }

    func hasHighQualityVoice(for languageCode: String) -> Bool {
        let locale = Self.locale(for: .target(languageCode))
        return AVSpeechSynthesisVoice.speechVoices().contains {
            $0.language == locale && $0.quality != .default
        }
    }

    /// Prefers the exact locale and the gender, then quality.
    static func best(
        among voices: [AVSpeechSynthesisVoice],
        locale: String,
        gender: AVSpeechSynthesisVoiceGender
    ) -> AVSpeechSynthesisVoice? {
        let prefix = String(locale.prefix(2))
        let candidates = voices.filter { $0.language.hasPrefix(prefix) }
        return candidates.max { score($0, locale: locale, gender: gender) < score($1, locale: locale, gender: gender) }
    }

    private static func score(_ voice: AVSpeechSynthesisVoice, locale: String, gender: AVSpeechSynthesisVoiceGender) -> Int {
        var score = 0
        if voice.language == locale {
            score += 100
        }
        if voice.gender == gender {
            score += 50
        }
        switch voice.quality {
        case .premium: score += 20
        case .enhanced: score += 10
        default: break
        }
        // Novelty voices (Bells, Bubbles…) aren't for learning.
        if voice.voiceTraits.contains(.isNoveltyVoice) {
            score -= 1000
        }
        return score
    }

    static func locale(for role: VoiceRole) -> String {
        switch role {
        case .english:
            return "en-US"
        case let .target(code):
            return Language.find(byCode: code)?.ttsCode ?? code
        }
    }
}
