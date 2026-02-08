import UIKit

final class HapticManager {
    static let shared = HapticManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        // Prepare generators for faster response
        prepareAll()
    }
    
    func prepareAll() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Game Actions
    
    /// Light tap when picking up a card
    func cardPickup() {
        lightGenerator.impactOccurred()
    }
    
    /// Selection feedback for card selection
    func cardSelect() {
        selectionGenerator.selectionChanged()
    }
    
    /// Medium impact for valid card placement
    func cardPlace() {
        mediumGenerator.impactOccurred()
    }
    
    /// Success notification for foundation placement
    func foundationPlace() {
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Error feedback for invalid move
    func invalidMove() {
        notificationGenerator.notificationOccurred(.error)
    }
    
    /// Heavy impact for winning the game
    func win() {
        // Triple burst for celebration
        heavyGenerator.impactOccurred()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.heavyGenerator.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.heavyGenerator.impactOccurred()
        }
    }
    
    /// Light tap for card flip
    func cardFlip() {
        lightGenerator.impactOccurred(intensity: 0.5)
    }
    
    /// Medium for undo action
    func undo() {
        mediumGenerator.impactOccurred(intensity: 0.7)
    }
    
    /// Light for drawing from stock
    func draw() {
        lightGenerator.impactOccurred(intensity: 0.6)
    }
    
    /// Warning for hint used
    func hint() {
        selectionGenerator.selectionChanged()
    }
}
