import AVFoundation

class ChineseTTSService {
    static let shared = ChineseTTSService()
    
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
    
    /// Call this at app launch to pre-load the Chinese voice in the background
    func warmUp() {
        guard !isWarmedUp else { return }
        
        DispatchQueue.global(qos: .background).async {
            let utterance = AVSpeechUtterance(string: "你好")
            utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
            utterance.volume = 0.0 // Silent
            
            self.synthesizer.speak(utterance)
            self.isWarmedUp = true
        }
    }
    
    func speak(_ text: String) {
        configureAudioSession()
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
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
