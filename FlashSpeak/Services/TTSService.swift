import AVFoundation

class TTSService {
    static let shared = TTSService()

    private let synthesizer = AVSpeechSynthesizer()
    private var isWarmedUp = false

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    func warmUp(languageCode: String? = nil) {
        guard !isWarmedUp else { return }

        let ttsCode = languageCode
            ?? Language.find(byCode: SettingsManager.shared.currentLanguageCode)?.ttsCode
            ?? "zh-CN"

        DispatchQueue.global(qos: .background).async {
            let utterance = AVSpeechUtterance(string: " ")
            utterance.voice = AVSpeechSynthesisVoice(language: ttsCode)
            utterance.volume = 0.0

            self.synthesizer.speak(utterance)
            self.isWarmedUp = true
        }
    }

    func speak(_ text: String, language: Language? = nil) {
        configureAudioSession()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let ttsCode = language?.ttsCode
            ?? Language.find(byCode: SettingsManager.shared.currentLanguageCode)?.ttsCode
            ?? "zh-CN"

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: ttsCode)
        utterance.rate = 0.45
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
