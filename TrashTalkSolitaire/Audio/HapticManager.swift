import UIKit

@MainActor
final class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare generators for lower latency
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Card Actions
    
    /// Light tap when picking up a card
    func cardPickup() {
        lightGenerator.impactOccurred()
    }
    
    /// Medium feedback when placing a card
    func cardPlace() {
        mediumGenerator.impactOccurred()
    }
    
    /// Success feedback when card goes to foundation
    func cardToFoundation() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Error feedback for invalid move
    func invalidMove() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - Game Actions
    
    /// Selection feedback for hint
    func hint() {
        selectionGenerator.selectionChanged()
    }
    
    /// Light feedback for undo
    func undo() {
        lightGenerator.impactOccurred()
    }
    
    /// Heavy feedback for win
    func win() {
        heavyGenerator.impactOccurred()
        
        // Double tap for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.heavyGenerator.impactOccurred()
        }
    }
    
    /// Warning feedback (e.g., about to lose progress)
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }
    
    // MARK: - Achievement
    
    /// Special feedback for achievement unlock
    func achievementUnlock() {
        notificationGenerator.notificationOccurred(.success)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.mediumGenerator.impactOccurred()
        }
    }
}
