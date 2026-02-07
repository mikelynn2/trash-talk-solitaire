import Foundation

enum Suit: Int, CaseIterable, Codable, Sendable {
    case clubs, diamonds, hearts, spades

    var symbol: String {
        switch self {
        case .clubs: return "♣"
        case .diamonds: return "♦"
        case .hearts: return "♥"
        case .spades: return "♠"
        }
    }

    var color: CardColor {
        switch self {
        case .clubs, .spades: return .black
        case .diamonds, .hearts: return .red
        }
    }
}

enum CardColor: Sendable {
    case red, black

    var opposite: CardColor {
        self == .red ? .black : .red
    }
}

enum Rank: Int, CaseIterable, Codable, Sendable {
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

struct Card: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let suit: Suit
    let rank: Rank
    var isFaceUp: Bool

    init(suit: Suit, rank: Rank, isFaceUp: Bool = false) {
        self.id = UUID()
        self.suit = suit
        self.rank = rank
        self.isFaceUp = isFaceUp
    }

    var color: CardColor { suit.color }
    var display: String { "\(rank.display)\(suit.symbol)" }

    /// Can this card be placed on top of `other` in a tableau pile?
    func canStackOnTableau(_ other: Card) -> Bool {
        other.isFaceUp && color != other.color && rank.rawValue == other.rank.rawValue - 1
    }

    /// Can this card be placed on top of `other` in a foundation pile?
    func canStackOnFoundation(_ other: Card?) -> Bool {
        if let other = other {
            return suit == other.suit && rank.rawValue == other.rank.rawValue + 1
        }
        return rank == .ace
    }

    static func fullDeck() -> [Card] {
        Suit.allCases.flatMap { suit in
            Rank.allCases.map { rank in
                Card(suit: suit, rank: rank)
            }
        }
    }
}
