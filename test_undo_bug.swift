#!/usr/bin/env swift

// Test for the undo-after-draw bug
// Bug: Move from waste, draw more cards, undo = drawn cards disappear

import Foundation

enum Suit: Int, CaseIterable {
    case clubs, diamonds, hearts, spades
    var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }
    var isRed: Bool { self == .hearts || self == .diamonds }
}

enum Rank: Int, CaseIterable {
    case ace = 1, two, three, four, five, six, seven
    case eight, nine, ten, jack, queen, king
    var display: String {
        switch self {
        case .ace: return "A"
        case .jack: return "J"
        case .queen: return "Q"
        case .king: return "K"
        default: return "\(rawValue)"
        }
    }
}

struct Card: Equatable, CustomStringConvertible {
    let suit: Suit
    let rank: Rank
    var isFaceUp: Bool = false
    var description: String { "\(rank.display)\(suit.symbol)" }
}

struct Move {
    let cards: [Card]
    let fromWaste: Bool
    let previousWaste: [Card]  // BUG: This captures waste state at move time
}

class GameState {
    var stock: [Card] = []
    var waste: [Card] = []
    var tableau: [[Card]] = []
    var undoStack: [Move] = []
    
    var totalCards: Int {
        stock.count + waste.count + tableau.reduce(0) { $0 + $1.count }
    }
    
    init() {
        // Simple setup for testing
        var deck = Suit.allCases.flatMap { suit in
            Rank.allCases.map { Card(suit: suit, rank: $0) }
        }
        deck.shuffle()
        
        // Put half in stock, rest in tableau
        stock = Array(deck.prefix(26))
        tableau = [Array(deck.suffix(26))]
    }
    
    func draw() {
        guard !stock.isEmpty else { return }
        var card = stock.removeLast()
        card.isFaceUp = true
        waste.append(card)
    }
    
    func moveFromWaste() -> Bool {
        guard let card = waste.last else { return false }
        
        // Save move for undo (BUG: saves entire previousWaste)
        let move = Move(
            cards: [card],
            fromWaste: true,
            previousWaste: waste  // This is the bug - captures current waste
        )
        undoStack.append(move)
        
        waste.removeLast()
        tableau[0].append(card)
        return true
    }
    
    func undoBuggy() {
        guard let move = undoStack.popLast() else { return }
        
        // Remove from tableau
        tableau[0].removeLast(move.cards.count)
        
        // BUG: This replaces entire waste, losing any cards drawn after the move
        if move.fromWaste {
            waste = move.previousWaste
        }
    }
    
    func undoFixed() {
        guard let move = undoStack.popLast() else { return }
        
        // Remove from tableau
        tableau[0].removeLast(move.cards.count)
        
        // FIXED: Just add the card back, don't replace entire waste
        if move.fromWaste {
            waste.append(contentsOf: move.cards)
        }
    }
}

print("🧪 Testing Undo-After-Draw Bug")
print("=" * 50)

// Test 1: Reproduce the bug
print("\nTest 1: Reproduce the bug (old behavior)")
print("-" * 40)

var game = GameState()
let initialCount = game.totalCards
print("Initial card count: \(initialCount)")

game.draw()
print("After draw: waste = \(game.waste), total = \(game.totalCards)")

let movedCard = game.waste.last!
game.moveFromWaste()
print("After move from waste: waste = \(game.waste), total = \(game.totalCards)")

game.draw()
game.draw()
let drawnCards = game.waste
print("After drawing 2 more: waste = \(game.waste), total = \(game.totalCards)")

// Now undo with the buggy behavior
game.undoBuggy()
print("After BUGGY undo: waste = \(game.waste), total = \(game.totalCards)")

if game.totalCards != initialCount {
    print("❌ BUG CONFIRMED: Lost \(initialCount - game.totalCards) cards!")
    print("   The drawn cards (\(drawnCards)) were lost when waste was replaced")
} else {
    print("✓ No cards lost (unexpected)")
}

// Test 2: Verify the fix
print("\n")
print("Test 2: Verify the fix (new behavior)")
print("-" * 40)

game = GameState()
print("Initial card count: \(game.totalCards)")

game.draw()
print("After draw: waste = \(game.waste), total = \(game.totalCards)")

game.moveFromWaste()
print("After move from waste: waste = \(game.waste), total = \(game.totalCards)")

game.draw()
game.draw()
print("After drawing 2 more: waste = \(game.waste), total = \(game.totalCards)")

// Now undo with the fixed behavior
game.undoFixed()
print("After FIXED undo: waste = \(game.waste), total = \(game.totalCards)")

if game.totalCards == initialCount {
    print("✅ FIX VERIFIED: All \(initialCount) cards accounted for!")
} else {
    print("❌ Still have issues: expected \(initialCount), got \(game.totalCards)")
}

print("\n" + "=" * 50)
print("CONCLUSION: The undo function was replacing the entire")
print("waste pile with the saved state, losing any cards that")
print("were drawn after the original move.")

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}
