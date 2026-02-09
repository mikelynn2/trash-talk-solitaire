#!/usr/bin/env swift

import Foundation

// Full game simulation to test for card loss bugs

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
    
    static func fullDeck() -> [Card] {
        Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in
                Card(suit: suit, rank: rank)
            }
        }
    }
}

struct GameState {
    var stock: [Card] = []
    var waste: [Card] = []
    var tableau: [[Card]] = Array(repeating: [], count: 7)
    var foundations: [[Card]] = Array(repeating: [], count: 4)
    var drawThreeMode: Bool = false
    
    var totalCards: Int {
        stock.count + waste.count + 
        tableau.reduce(0) { $0 + $1.count } +
        foundations.reduce(0) { $0 + $1.count }
    }
    
    mutating func deal() {
        var deck = Card.fullDeck()
        deck.shuffle()
        
        stock = []
        waste = []
        tableau = Array(repeating: [], count: 7)
        foundations = Array(repeating: [], count: 4)
        
        // Deal to tableau
        for col in 0..<7 {
            for row in 0...col {
                var card = deck.removeLast()
                card.isFaceUp = (row == col)
                tableau[col].append(card)
            }
        }
        
        // Remaining cards go to stock (face down)
        stock = deck.map { var c = $0; c.isFaceUp = false; return c }
    }
    
    mutating func draw() {
        if stock.isEmpty {
            // Recycle waste to stock
            stock = waste.reversed().map { var c = $0; c.isFaceUp = false; return c }
            waste = []
        } else {
            let count = drawThreeMode ? min(3, stock.count) : 1
            for _ in 0..<count {
                var card = stock.removeLast()
                card.isFaceUp = true
                waste.append(card)
            }
        }
    }
    
    func canMoveToFoundation(card: Card, pile: Int) -> Bool {
        let foundation = foundations[pile]
        if foundation.isEmpty {
            return card.rank == .ace
        }
        guard let top = foundation.last else { return false }
        return card.suit == top.suit && card.rank.rawValue == top.rank.rawValue + 1
    }
    
    func canMoveToTableau(card: Card, pile: Int) -> Bool {
        let tablePile = tableau[pile]
        if tablePile.isEmpty {
            return card.rank == .king
        }
        guard let top = tablePile.last, top.isFaceUp else { return false }
        let oppositeColor = card.suit.isRed != top.suit.isRed
        return oppositeColor && card.rank.rawValue == top.rank.rawValue - 1
    }
    
    mutating func moveFromWaste(toFoundation pile: Int) -> Bool {
        guard let card = waste.last, canMoveToFoundation(card: card, pile: pile) else { return false }
        waste.removeLast()
        foundations[pile].append(card)
        return true
    }
    
    mutating func moveFromWaste(toTableau pile: Int) -> Bool {
        guard let card = waste.last, canMoveToTableau(card: card, pile: pile) else { return false }
        var moved = waste.removeLast()
        moved.isFaceUp = true
        tableau[pile].append(moved)
        return true
    }
    
    mutating func moveFromTableau(srcPile: Int, cardIndex: Int, toFoundation destPile: Int) -> Bool {
        guard cardIndex == tableau[srcPile].count - 1 else { return false }  // Only top card
        guard let card = tableau[srcPile].last, canMoveToFoundation(card: card, pile: destPile) else { return false }
        tableau[srcPile].removeLast()
        foundations[destPile].append(card)
        // Flip next card if needed
        if !tableau[srcPile].isEmpty && !tableau[srcPile].last!.isFaceUp {
            tableau[srcPile][tableau[srcPile].count - 1].isFaceUp = true
        }
        return true
    }
    
    mutating func moveFromTableau(srcPile: Int, cardIndex: Int, toTableau destPile: Int) -> Bool {
        guard cardIndex < tableau[srcPile].count else { return false }
        let card = tableau[srcPile][cardIndex]
        guard canMoveToTableau(card: card, pile: destPile) else { return false }
        
        // Move cards
        let cards = Array(tableau[srcPile][cardIndex...])
        tableau[srcPile].removeSubrange(cardIndex...)
        tableau[destPile].append(contentsOf: cards)
        
        // Flip next card if needed
        if !tableau[srcPile].isEmpty && !tableau[srcPile].last!.isFaceUp {
            tableau[srcPile][tableau[srcPile].count - 1].isFaceUp = true
        }
        return true
    }
    
    func findAllMoves() -> [(action: String, execute: (inout GameState) -> Bool)] {
        var moves: [(String, (inout GameState) -> Bool)] = []
        
        // From waste
        if waste.last != nil {
            for f in 0..<4 {
                if canMoveToFoundation(card: waste.last!, pile: f) {
                    moves.append(("waste->foundation\(f)", { $0.moveFromWaste(toFoundation: f) }))
                }
            }
            for t in 0..<7 {
                if canMoveToTableau(card: waste.last!, pile: t) {
                    moves.append(("waste->tableau\(t)", { $0.moveFromWaste(toTableau: t) }))
                }
            }
        }
        
        // From tableau
        for src in 0..<7 {
            guard !tableau[src].isEmpty else { continue }
            guard let faceUpStart = tableau[src].firstIndex(where: { $0.isFaceUp }) else { continue }
            
            // Top card to foundation
            if let topCard = tableau[src].last {
                for f in 0..<4 {
                    if canMoveToFoundation(card: topCard, pile: f) {
                        let srcPile = src
                        let cardIdx = tableau[src].count - 1
                        moves.append(("tableau\(src)->foundation\(f)", { $0.moveFromTableau(srcPile: srcPile, cardIndex: cardIdx, toFoundation: f) }))
                    }
                }
            }
            
            // Stack to other tableau
            for cardIdx in faceUpStart..<tableau[src].count {
                let card = tableau[src][cardIdx]
                for dest in 0..<7 where dest != src {
                    if canMoveToTableau(card: card, pile: dest) {
                        let srcPile = src
                        let idx = cardIdx
                        moves.append(("tableau\(src)[\(cardIdx)]->tableau\(dest)", { $0.moveFromTableau(srcPile: srcPile, cardIndex: idx, toTableau: dest) }))
                    }
                }
            }
        }
        
        return moves
    }
    
    func validateCards() -> (valid: Bool, missing: [String], duplicates: [String]) {
        let allCards = stock + waste + tableau.flatMap { $0 } + foundations.flatMap { $0 }
        var missing: [String] = []
        var duplicates: [String] = []
        
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let found = allCards.filter { $0.suit == suit && $0.rank == rank }
                if found.isEmpty {
                    missing.append("\(rank.display)\(suit.symbol)")
                } else if found.count > 1 {
                    duplicates.append("\(rank.display)\(suit.symbol) x\(found.count)")
                }
            }
        }
        
        return (missing.isEmpty && duplicates.isEmpty, missing, duplicates)
    }
}

// Run simulation
print("🃏 Trash Talk Solitaire - Card Count Bug Test")
print("=" * 50)

var gamesWithErrors = 0
var totalMoves = 0
let numGames = 500
let maxMovesPerGame = 300

for gameNum in 1...numGames {
    var game = GameState()
    game.deal()
    
    // Validate after deal
    let (valid, missing, dups) = game.validateCards()
    if !valid {
        print("❌ Game \(gameNum): Error at deal!")
        print("   Missing: \(missing)")
        print("   Duplicates: \(dups)")
        gamesWithErrors += 1
        continue
    }
    
    // Play random moves
    var movesMade = 0
    var lastMoveDescription = ""
    
    for _ in 1...maxMovesPerGame {
        // 40% chance to draw if stock or waste available
        if (!game.stock.isEmpty || !game.waste.isEmpty) && Double.random(in: 0...1) < 0.4 {
            game.draw()
            lastMoveDescription = "draw"
            movesMade += 1
        } else {
            let moves = game.findAllMoves()
            if moves.isEmpty {
                if !game.stock.isEmpty || !game.waste.isEmpty {
                    game.draw()
                    lastMoveDescription = "draw (no moves)"
                    movesMade += 1
                } else {
                    break  // Game over
                }
            } else {
                let (desc, action) = moves.randomElement()!
                _ = action(&game)
                lastMoveDescription = desc
                movesMade += 1
            }
        }
        
        // Validate after each move
        let (valid, missing, dups) = game.validateCards()
        if !valid {
            print("❌ Game \(gameNum), Move \(movesMade): Card count error after '\(lastMoveDescription)'")
            print("   Missing: \(missing)")
            print("   Duplicates: \(dups)")
            print("   Stock: \(game.stock.count), Waste: \(game.waste.count)")
            print("   Tableau: \(game.tableau.map { $0.count })")
            print("   Foundations: \(game.foundations.map { $0.count })")
            gamesWithErrors += 1
            break
        }
        
        // Check for win
        if game.foundations.allSatisfy({ $0.count == 13 }) {
            break
        }
        
        totalMoves += 1
    }
    
    // Progress
    if gameNum % 100 == 0 {
        print("Progress: \(gameNum)/\(numGames) games...")
    }
}

print("\n" + "=" * 50)
print("TEST COMPLETE")
print("=" * 50)
print("Games played: \(numGames)")
print("Total moves: \(totalMoves)")
print("Games with errors: \(gamesWithErrors)")

if gamesWithErrors == 0 {
    print("✅ ALL TESTS PASSED - No card loss bugs detected!")
} else {
    print("❌ ERRORS FOUND - \(gamesWithErrors) games had card count issues")
}

extension String {
    static func *(lhs: String, rhs: Int) -> String {
        String(repeating: lhs, count: rhs)
    }
}
