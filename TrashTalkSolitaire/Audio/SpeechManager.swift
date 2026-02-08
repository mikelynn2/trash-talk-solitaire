import AVFoundation

@MainActor
final class SpeechManager: NSObject, ObservableObject {

    @Published var isMuted: Bool = false
    @Published var speechRate: Float = 0.44  // Slower grandma pace

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }

    func speak(_ text: String) {
        guard !isMuted else { return }

        // Cancel any in-progress speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .word)
        }

        let utterance = AVSpeechUtterance(string: text)
        
        // Grandma pacing - slower, more deliberate
        utterance.rate = 0.38  // Slower than default (0.5)
        utterance.pitchMultiplier = 0.95  // Slightly lower for older voice
        utterance.preUtteranceDelay = 0.2
        utterance.postUtteranceDelay = 0.3
        utterance.volume = 1.0

        // Find the best available British female voice
        // Premium/Enhanced voices sound MUCH better but must be downloaded
        // Settings > Accessibility > Spoken Content > Voices > English (UK)
        let selectedVoice = findBestBritishVoice()
        utterance.voice = selectedVoice
        
        // Log which voice we're using (for debugging)
        if let voice = selectedVoice {
            print("🎙️ Using voice: \(voice.name) (\(voice.quality.rawValue))")
        }

        synthesizer.speak(utterance)
    }
    
    private func findBestBritishVoice() -> AVSpeechSynthesisVoice? {
        let allVoices = AVSpeechSynthesisVoice.speechVoices()
        
        // Filter to British English voices
        let britishVoices = allVoices.filter { $0.language.starts(with: "en-GB") }
        
        // Sort by quality (premium > enhanced > default > compact)
        let sortedVoices = britishVoices.sorted { v1, v2 in
            v1.quality.rawValue > v2.quality.rawValue
        }
        
        // Prefer female voices (Kate, Serena, Stephanie, etc.)
        let femaleNames = ["Kate", "Serena", "Stephanie", "Fiona", "Moira"]
        
        // Try to find a high-quality female voice
        for voice in sortedVoices {
            if femaleNames.contains(where: { voice.name.contains($0) }) {
                return voice
            }
        }
        
        // Fall back to any British voice
        return sortedVoices.first ?? AVSpeechSynthesisVoice(language: "en-GB")
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
