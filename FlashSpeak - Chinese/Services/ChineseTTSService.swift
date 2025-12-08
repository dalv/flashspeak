import AVFoundation

class ChineseTTSService {
    static let shared = ChineseTTSService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    func speak(_ text: String) {
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        
        // Use Mandarin Chinese voice
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        
        // Adjust rate for clearer pronunciation (0.0 - 1.0, default is 0.5)
        utterance.rate = 0.45
        
        // Slight pause between phrases
        utterance.preUtteranceDelay = 0.1
        utterance.postUtteranceDelay = 0.1
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
}
