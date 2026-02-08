import Foundation

enum DeckDifficulty: String, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    
    var description: String {
        switch self {
        case .easy: return "Aces & low cards more accessible"
        case .medium: return "Pure random shuffle"
        case .hard: return "Aces buried, colors clumped"
        }
    }
}

struct GameState {
    var tableau: [[Card]]       // 7 piles
    var foundations: [[Card]]   // 4 piles (one per suit, but indexed 0-3)
    var stock: [Card]           // draw pile
    var waste: [Card]           // flipped from waste
    var moveCount: Int
    var elapsedSeconds: Int
    var isWon: Bool
    
    // Draw 3 mode
    var drawThreeMode: Bool = false
    
    // Vegas scoring
    var vegasMode: Bool = false
    var vegasScore: Int = -52  // Start at -$52
    
    // Difficulty
    var difficulty: DeckDifficulty = .medium

    static func empty() -> GameState {
        GameState(
            tableau: Array(repeating: [], count: 7),
            foundations: Array(repeating: [], count: 4),
            stock: [],
            waste: [],
            moveCount: 0,
            elapsedSeconds: 0,
            isWon: false,
            drawThreeMode: UserDefaults.standard.bool(forKey: "drawThreeMode"),
            vegasMode: UserDefaults.standard.bool(forKey: "vegasMode"),
            vegasScore: -52
        )
    }
}

enum MoveSource: Equatable {
    case tableau(pile: Int, cardIndex: Int)
    case waste
    case foundation(pile: Int)
}

enum MoveDestination: Equatable {
    case tableau(pile: Int)
    case foundation(pile: Int)
}

struct Move {
    let source: MoveSource
    let destination: MoveDestination
    let cards: [Card]
    let flippedCard: Bool  // did this move cause a face-down card to flip?
    let previousWaste: [Card]
    let previousStock: [Card]
}
