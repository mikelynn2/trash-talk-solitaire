import Foundation

struct GameState {
    var tableau: [[Card]]       // 7 piles
    var foundations: [[Card]]   // 4 piles (one per suit, but indexed 0-3)
    var stock: [Card]           // draw pile
    var waste: [Card]           // flipped from stock
    var moveCount: Int
    var elapsedSeconds: Int
    var isWon: Bool

    static func empty() -> GameState {
        GameState(
            tableau: Array(repeating: [], count: 7),
            foundations: Array(repeating: [], count: 4),
            stock: [],
            waste: [],
            moveCount: 0,
            elapsedSeconds: 0,
            isWon: false
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
