#!/usr/bin/env swift

// Minimal reproduction of deck creation logic

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

struct Card {
    let suit: Suit
    let rank: Rank
    var isFaceUp: Bool = false
    var display: String { "\(rank.display)\(suit.symbol)" }
}

func fullDeck() -> [Card] {
    Suit.allCases.flatMap { suit in
        Rank.allCases.map { rank in
            Card(suit: suit, rank: rank)
        }
    }
}

func shuffleDeckMedium() -> [Card] {
    var deck = fullDeck()
    deck.shuffle()
    return deck
}

func shuffleDeckEasy() -> [Card] {
    var deck = fullDeck()
    deck.shuffle()
    let lowCards = deck.filter { $0.rank.rawValue <= 4 }
    let highCards = deck.filter { $0.rank.rawValue > 4 }
    deck = highCards.shuffled() + lowCards.shuffled()
    for _ in 0..<10 {
        let i = Int.random(in: 0..<deck.count)
        let j = Int.random(in: 0..<deck.count)
        deck.swapAt(i, j)
    }
    return deck
}

func deal(deck: inout [Card]) -> [[Card]] {
    var tableau: [[Card]] = Array(repeating: [], count: 7)
    for col in 0..<7 {
        for row in 0...(col) {
            var card = deck.removeLast()
            card.isFaceUp = (row == col)
            tableau[col].append(card)
        }
    }
    return tableau
}

func validate(deck: [Card], tableau: [[Card]]) -> Bool {
    let allCards = deck + tableau.flatMap { $0 }
    
    // Check count
    if allCards.count != 52 {
        print("❌ Total cards: \(allCards.count) (expected 52)")
        return false
    }
    
    // Check for 6♣ specifically
    let sixClubs = allCards.filter { $0.rank == .six && $0.suit == .clubs }
    if sixClubs.isEmpty {
        print("❌ 6♣ MISSING!")
        return false
    }
    
    // Check all 52 unique cards exist
    for suit in Suit.allCases {
        for rank in Rank.allCases {
            let found = allCards.filter { $0.suit == suit && $0.rank == rank }
            if found.isEmpty {
                print("❌ Missing: \(rank.display)\(suit.symbol)")
                return false
            }
            if found.count > 1 {
                print("❌ Duplicate: \(rank.display)\(suit.symbol) x\(found.count)")
                return false
            }
        }
    }
    
    return true
}

// Run 1000 tests
print("Testing deck creation and deal...")
var failures = 0

for i in 1...1000 {
    var deck = shuffleDeckMedium()
    let tableau = deal(deck: &deck)
    
    if !validate(deck: deck, tableau: tableau) {
        failures += 1
        print("  Failed on iteration \(i)")
    }
}

print("\n✅ Medium shuffle: \(1000 - failures)/1000 passed")

failures = 0
for i in 1...1000 {
    var deck = shuffleDeckEasy()
    let tableau = deal(deck: &deck)
    
    if !validate(deck: deck, tableau: tableau) {
        failures += 1
        print("  Failed on iteration \(i)")
    }
}

print("✅ Easy shuffle: \(1000 - failures)/1000 passed")

print("\nDeck creation logic verified!")
