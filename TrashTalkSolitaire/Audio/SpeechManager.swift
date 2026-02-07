import AVFoundation

@MainActor
final class SpeechManager: NSObject, ObservableObject {

    @Published var isMuted: Bool = false
    @Published var speechRate: Float = 0.52  // 0.0–1.0

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
        utterance.pitchMultiplier = 1.1
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.1

        // Use a fun voice if available
        if let voice = AVSpeechSynthesisVoice(identifier: "com.apple.speech.synthesis.voice.Fred") {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

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
