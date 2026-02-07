import AVFoundation

@MainActor
final class SpeechManager: NSObject, ObservableObject {

    @Published var isMuted: Bool = false
    @Published var speechRate: Float = 0.44  // Slower grandma pace

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
    }

    func speak(_ text: String) {
        guard !isMuted else { return }

        // Cancel any in-progress speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = speechRate
        utterance.pitchMultiplier = 1.15  // Slightly higher, grandmother-ish
        utterance.preUtteranceDelay = 0.3
        utterance.postUtteranceDelay = 0.2
        utterance.volume = 0.9

        // British grandmother voice - try premium voices first
        // Kate and Serena are British female voices
        let britishVoiceIDs = [
            "com.apple.voice.premium.en-GB.Kate",      // Premium Kate (best)
            "com.apple.voice.enhanced.en-GB.Kate",     // Enhanced Kate
            "com.apple.ttsbundle.Kate-premium",        // Alt premium
            "com.apple.voice.premium.en-GB.Serena",    // Premium Serena
            "com.apple.voice.enhanced.en-GB.Serena",   // Enhanced Serena
            "com.apple.ttsbundle.Serena-premium",      // Alt premium
            "com.apple.voice.compact.en-GB.Kate",      // Compact Kate
            "com.apple.voice.compact.en-GB.Serena"     // Compact Serena
        ]
        
        var selectedVoice: AVSpeechSynthesisVoice?
        
        // Try each British voice in preference order
        for voiceID in britishVoiceIDs {
            if let voice = AVSpeechSynthesisVoice(identifier: voiceID) {
                selectedVoice = voice
                break
            }
        }
        
        // Fallback: find any British English female voice
        if selectedVoice == nil {
            let allVoices = AVSpeechSynthesisVoice.speechVoices()
            selectedVoice = allVoices.first { voice in
                voice.language.starts(with: "en-GB")
            }
        }
        
        // Last resort: any British voice
        if selectedVoice == nil {
            selectedVoice = AVSpeechSynthesisVoice(language: "en-GB")
        }
        
        utterance.voice = selectedVoice

        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    func toggleMute() {
        isMuted.toggle()
        if isMuted {
            stopSpeaking()
        }
    }
}
