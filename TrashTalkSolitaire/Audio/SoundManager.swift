import AVFoundation
import UIKit

final class SoundManager {
    static let shared = SoundManager()
    
    private var isMuted = false
    
    // Use system sounds for lightweight, instant playback
    private let cardPlaceID: SystemSoundID = 1104  // Soft tap
    private let cardFlipID: SystemSoundID = 1306   // Subtle tick
    private let foundationID: SystemSoundID = 1057 // Gentle positive
    private let invalidID: SystemSoundID = 1053    // Soft thud
    private let winID: SystemSoundID = 1025        // Celebration
    private let drawID: SystemSoundID = 1105       // Card draw
    
    private init() {}
    
    func toggleMute() {
        isMuted.toggle()
    }
    
    var muted: Bool {
        get { isMuted }
        set { isMuted = newValue }
    }
    
    func playCardPlace() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(cardPlaceID)
    }
    
    func playCardFlip() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(cardFlipID)
    }
    
    func playFoundation() {
        guard !isMuted else { return }
        // Gentle haptic + sound for foundation
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        AudioServicesPlaySystemSound(foundationID)
    }
    
    func playInvalid() {
        guard !isMuted else { return }
        // Light haptic for invalid move
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    func playDraw() {
        guard !isMuted else { return }
        AudioServicesPlaySystemSound(drawID)
    }
    
    func playWin() {
        guard !isMuted else { return }
        // Big haptic + sound
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        AudioServicesPlaySystemSound(winID)
    }
}
