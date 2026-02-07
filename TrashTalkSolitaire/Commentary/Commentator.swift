import Foundation

enum CommentaryMood: String {
    case roast, praise, neutral, brilliant, terrible
}

struct MoveAnalysis {
    let mood: CommentaryMood
    let comment: String
}

final class Commentator {
    
    // MARK: - Throttling
    
    private var lastCommentTime: Date = .distantPast
    private var movesSinceLastComment: Int = 0
    private let minimumMovesBetweenComments = 2
    private let minimumSecondsBetweenComments: TimeInterval = 4.0
    
    // Probability of commenting even on notable moves (to avoid fatigue)
    private let praiseChance: Double = 0.6      // 60% chance to comment on good moves
    private let roastChance: Double = 0.7       // 70% chance to comment on bad moves
    private let brilliantChance: Double = 0.95  // 95% chance for brilliant moves
    private let terribleChance: Double = 0.95   // 95% chance for terrible moves

    // MARK: - Move Analysis

    func analyzeMove(
        cards: [Card],
        source: MoveSource,
        destination: MoveDestination,
        gameState: GameState
    ) -> MoveAnalysis? {
        let card = cards.first!

        // Determine mood and comment based on move type
        var mood: CommentaryMood = .neutral
        var comment: String = ""
        
        // Foundation move = always good
        if case .foundation = destination {
            if card.rank == .ace {
                mood = .praise
                comment = aceToFoundationComments.randomElement()!
            } else if card.rank == .king {
                mood = .brilliant
                comment = kingToFoundationComments.randomElement()!
            } else {
                mood = .praise
                comment = foundationComments.randomElement()!
            }
        }
        // King to empty tableau = good
        else if case .tableau(let destPile) = destination,
           card.rank == .king,
           gameState.tableau[destPile].isEmpty || destPileWasEmpty(destPile, gameState: gameState) {
            mood = .praise
            comment = kingToEmptyComments.randomElement()!
        }
        // Moving from foundation back to tableau = terrible
        else if case .foundation = source {
            mood = .terrible
            comment = foundationToTableauComments.randomElement()!
        }
        // Burying a card on a large pile = bad
        else if case .tableau(let destPile) = destination {
            if gameState.tableau[destPile].count > 5 {
                mood = .roast
                comment = buryComments.randomElement()!
            }
        }
        // Multi-card move (3+)
        else if cards.count >= 4 {
            mood = .praise
            comment = bigStackComments.randomElement()!
        }
        
        // Revealing face-down cards gets a comment sometimes
        if mood == .neutral, case .tableau(let srcPile, let idx) = source, idx > 0 {
            let cardBelow = gameState.tableau[srcPile][safe: idx - 1]
            if let cardBelow, !cardBelow.isFaceUp {
                mood = .praise
                comment = revealComments.randomElement()!
            }
        }
        
        // SKIP neutral moves entirely - no comment
        if mood == .neutral {
            movesSinceLastComment += 1
            return nil
        }
        
        // Apply probability check - don't comment on EVERY notable move
        let shouldComment: Bool
        switch mood {
        case .brilliant:
            shouldComment = Double.random(in: 0...1) < brilliantChance
        case .terrible:
            shouldComment = Double.random(in: 0...1) < terribleChance
        case .praise:
            shouldComment = Double.random(in: 0...1) < praiseChance
        case .roast:
            shouldComment = Double.random(in: 0...1) < roastChance
        case .neutral:
            shouldComment = false
        }
        
        guard shouldComment else {
            movesSinceLastComment += 1
            return nil
        }
        
        // Check cooldown - don't spam comments
        let timeSinceLastComment = Date().timeIntervalSince(lastCommentTime)
        guard movesSinceLastComment >= minimumMovesBetweenComments ||
              timeSinceLastComment >= minimumSecondsBetweenComments ||
              mood == .brilliant || mood == .terrible else {
            movesSinceLastComment += 1
            return nil
        }
        
        // We're commenting - reset tracking
        lastCommentTime = Date()
        movesSinceLastComment = 0
        
        return MoveAnalysis(mood: mood, comment: comment)
    }

    private func destPileWasEmpty(_ pile: Int, gameState: GameState) -> Bool {
        // After the move, the pile has only kings — check count
        let pileCards = gameState.tableau[pile]
        return pileCards.allSatisfy { $0.rank == .king } && pileCards.count <= 1
    }

    // MARK: - Win

    func winComment() -> String {
        winComments.randomElement()!
    }

    // MARK: - Commentary Banks

    private let aceToFoundationComments = [
        "An ace to the foundation. Even a broken clock is right twice a day.",
        "Ace up! Literally the easiest move in the game, but I'll allow it.",
        "Wow, you found the ace. Want a trophy?",
        "Foundation ace! The game basically did that one for you.",
        "An ace! Don't let it go to your head.",
    ]

    private let kingToFoundationComments = [
        "A KING to the foundation?! I'm actually impressed. Mark the calendar.",
        "Full suit complete! Okay, okay, I see you!",
        "King home! You might actually know what you're doing... nah.",
        "The king is home! Even I have to respect that one.",
    ]

    private let foundationComments = [
        "Finally! A move that doesn't make me question your life choices.",
        "Look at you, playing like you've actually seen cards before!",
        "Foundation move. Solid. Don't get used to this praise.",
        "Hey, a smart move! Who are you and what did you do with the player?",
        "Nice. See? Good things happen when you don't panic.",
        "Foundation bound! I'd clap but I don't have hands.",
        "A competent move? In THIS economy?",
        "That's the stuff. More of this, less of... everything else you do.",
    ]

    private let kingToEmptyComments = [
        "King to an empty column. Textbook. I'm proud. Kind of.",
        "Smart—filling that empty spot with a king. Was that on purpose?",
        "A king where a king should go. Revolutionary strategy.",
        "Empty column + King = the one move you CAN'T mess up. Well done.",
    ]

    private let revealComments = [
        "Ooh, revealing a hidden card. The suspense is killing me.",
        "Uncovering secrets! This is the most excitement I've had all day.",
        "New card revealed! Let's see if you know what to do with it.",
        "A face-down card flips! Christmas morning energy.",
        "Plot twist! A new card enters the chat.",
    ]

    private let buryComments = [
        "Oh, burying that card? Bold strategy, let's see how that works out...",
        "Sure, just pile more cards on. That's definitely how you win.",
        "Wow. Just... wow. My grandmother plays better and she's been dead for 10 years.",
        "That move was so bad, the cards are embarrassed for you.",
        "You're building a tower of regret right now.",
        "Ah yes, the classic 'make my life harder' strategy.",
        "I've seen better moves from a shuffling machine.",
        "That pile is getting dangerously close to a fire hazard.",
    ]

    private let foundationToTableauComments = [
        "TAKING A CARD OFF THE FOUNDATION? Are you having a stroke?",
        "Oh cool, we're going BACKWARDS now. Love that for us.",
        "Foundation to tableau. You know that's the wrong direction, right?",
        "I... what? Why would you... I need a minute.",
        "Removing from foundation. This is a cry for help, isn't it?",
    ]

    private let bigStackComments = [
        "Moving a whole stack! Big brain energy right there.",
        "Look at that cascade! Someone's been paying attention.",
        "A multi-card move! You're either a genius or very lucky.",
        "Stack transfer! I'd be impressed if I wasn't so suspicious.",
    ]

    private let neutralComments = [
        "Okay. That happened.",
        "A move was made. I'll reserve judgment.",
        "Sure, why not.",
        "Interesting choice...",
        "I mean, it's not WRONG...",
        "That's certainly one way to play.",
        "I've seen worse. Not much worse, but worse.",
        "Mid move. Mid player. Makes sense.",
    ]

    private let mildRoasts = [
        "Are you playing solitaire or just rearranging deck chairs on the Titanic?",
        "My CPU cycles are being wasted watching this.",
        "You play cards like you parallel park—terrified and badly.",
        "I've seen more strategy in a game of 52 pickup.",
        "Is this your first time? It's okay to admit it.",
        "You're playing this game like rent isn't due.",
        "Somewhere, a deck of cards is filing a restraining order against you.",
        "Bold move. Wrong, but bold.",
    ]

    private let winComments = [
        "YOU WON?! I mean... of course you won. I taught you everything you know.",
        "All 52 cards home! I'm not crying, you're crying.",
        "VICTORY! Against all odds—and I do mean ALL odds—you did it!",
        "Winner winner chicken dinner! I honestly didn't think you had it in you.",
        "The cards are home! Somebody call ESPN, we've got a champion!",
        "YOU ABSOLUTE LEGEND! Wait, was this on easy mode?",
        "I take back every mean thing I said. Most of them. Some of them. A few.",
    ]
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
