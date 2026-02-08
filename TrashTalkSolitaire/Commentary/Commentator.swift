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
    
    // Track game state for situational comments
    private var undoCount: Int = 0
    private var hintCount: Int = 0
    private var gameStartTime: Date = Date()
    
    // Track used comments to avoid repeats within a session
    private var usedComments: Set<String> = []
    
    // Probability of commenting even on notable moves (to avoid fatigue)
    private let praiseChance: Double = 0.6      // 60% chance to comment on good moves
    private let roastChance: Double = 0.7       // 70% chance to comment on bad moves
    private let brilliantChance: Double = 0.95  // 95% chance for brilliant moves
    private let terribleChance: Double = 0.95   // 95% chance for terrible moves

    // MARK: - Game State Tracking
    
    func resetForNewGame() {
        undoCount = 0
        hintCount = 0
        gameStartTime = Date()
        usedComments.removeAll()
    }
    
    /// Pick a random comment that hasn't been used this session
    private func pickUnused(from comments: [String]) -> String {
        // Find comments we haven't used yet
        let available = comments.filter { !usedComments.contains($0) }
        
        // If all have been used, reset and use any
        let chosen: String
        if available.isEmpty {
            chosen = comments.randomElement()!
        } else {
            chosen = available.randomElement()!
        }
        
        usedComments.insert(chosen)
        return chosen
    }
    
    func recordUndo() {
        undoCount += 1
    }
    
    func recordHint() {
        hintCount += 1
    }

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
                comment = pickUnused(from: aceToFoundationComments)
            } else if card.rank == .king {
                mood = .brilliant
                comment = pickUnused(from: kingToFoundationComments)
            } else {
                mood = .praise
                comment = pickUnused(from: foundationComments)
            }
        }
        // King to empty tableau = good
        else if case .tableau(let destPile) = destination,
           card.rank == .king,
           gameState.tableau[destPile].isEmpty || destPileWasEmpty(destPile, gameState: gameState) {
            mood = .praise
            comment = pickUnused(from: kingToEmptyComments)
        }
        // Moving from foundation back to tableau = terrible
        else if case .foundation = source {
            mood = .terrible
            comment = pickUnused(from: foundationToTableauComments)
        }
        // Burying a card on a large pile = bad
        else if case .tableau(let destPile) = destination {
            if gameState.tableau[destPile].count > 5 {
                mood = .roast
                comment = pickUnused(from: buryComments)
            }
        }
        // Multi-card move (3+)
        else if cards.count >= 4 {
            mood = .praise
            comment = pickUnused(from: bigStackComments)
        }
        
        // Revealing face-down cards gets a comment sometimes
        if mood == .neutral, case .tableau(let srcPile, let idx) = source, idx > 0 {
            let cardBelow = gameState.tableau[srcPile][safe: idx - 1]
            if let cardBelow, !cardBelow.isFaceUp {
                mood = .praise
                comment = pickUnused(from: revealComments)
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
        let pileCards = gameState.tableau[pile]
        return pileCards.allSatisfy { $0.rank == .king } && pileCards.count <= 1
    }

    // MARK: - Win Comments
    
    func winComment() -> String {
        let gameTime = Date().timeIntervalSince(gameStartTime)
        
        // Fast win (under 3 minutes)
        if gameTime < 180 {
            return pickUnused(from: fastWinComments)
        }
        
        // Slow win (over 10 minutes)
        if gameTime > 600 {
            return pickUnused(from: slowWinComments)
        }
        
        // Won with lots of undos
        if undoCount > 10 {
            return pickUnused(from: undoWinComments)
        }
        
        // Won with lots of hints
        if hintCount > 5 {
            return pickUnused(from: hintWinComments)
        }
        
        return pickUnused(from: winComments)
    }
    
    // MARK: - Hint Comments
    
    func hintComment() -> String {
        if hintCount == 0 {
            return pickUnused(from: firstHintComments)
        } else if hintCount > 5 {
            return pickUnused(from: manyHintsComments)
        } else {
            return pickUnused(from: hintComments)
        }
    }
    
    // MARK: - Undo Comments
    
    func undoComment() -> String {
        if undoCount > 10 {
            return pickUnused(from: manyUndoComments)
        }
        return pickUnused(from: undoComments)
    }
    
    // MARK: - Streak Comments
    
    func streakComment(streak: Int) -> String? {
        switch streak {
        case 3:
            return "Three wins in a row! Don't let it go to your head."
        case 5:
            return "FIVE game streak! Okay, I'm officially impressed."
        case 10:
            return "TEN wins?! Who ARE you?! 🏆"
        default:
            return nil
        }
    }

    // MARK: - Commentary Banks (80+ lines total)

    private let aceToFoundationComments = [
        "An ace to the foundation. Even a broken clock is right twice a day.",
        "Ace up! Literally the easiest move in the game, but I'll allow it.",
        "Wow, you found the ace. Want a trophy?",
        "Foundation ace! The game basically did that one for you.",
        "An ace! Don't let it go to your head.",
        "Ace to foundation. Groundbreaking stuff here.",
        "Oh look, you can count to one. Ace placed.",
        "The ace found its home. How touching.",
    ]

    private let kingToFoundationComments = [
        "A KING to the foundation?! I'm actually impressed. Mark the calendar.",
        "Full suit complete! Okay, okay, I see you!",
        "King home! You might actually know what you're doing... nah.",
        "The king is home! Even I have to respect that one.",
        "KING TO FOUNDATION! The prophecy is fulfilled!",
        "A complete suit! I'm not crying, YOU'RE crying!",
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
        "Card to foundation! Your parents would be proud. Maybe.",
        "Lovely move, dear. Even I couldn't have done it better.",
        "Right then! That's proper card playing, that is.",
        "Foundation! You're learning! Slowly, but learning.",
    ]

    private let kingToEmptyComments = [
        "King to an empty column. Textbook. I'm proud. Kind of.",
        "Smart—filling that empty spot with a king. Was that on purpose?",
        "A king where a king should go. Revolutionary strategy.",
        "Empty column + King = the one move you CAN'T mess up. Well done.",
        "King to empty space! Someone read the rules!",
        "That's a proper king placement. I'm almost impressed.",
    ]

    private let revealComments = [
        "Ooh, revealing a hidden card. The suspense is killing me.",
        "Uncovering secrets! This is the most excitement I've had all day.",
        "New card revealed! Let's see if you know what to do with it.",
        "A face-down card flips! Christmas morning energy.",
        "Plot twist! A new card enters the chat.",
        "Mystery card revealed! The plot thickens.",
        "Another card sees the light! How poetic.",
        "Flip! New possibilities emerge.",
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
        "Burying cards like they're treasure. Spoiler: they're not.",
        "That poor card. Trapped forever under your mountain of mistakes.",
        "You just made that card's life significantly worse.",
        "Oh dear. That card had dreams, you know.",
    ]

    private let foundationToTableauComments = [
        "TAKING A CARD OFF THE FOUNDATION? Are you having a stroke?",
        "Oh cool, we're going BACKWARDS now. Love that for us.",
        "Foundation to tableau. You know that's the wrong direction, right?",
        "I... what? Why would you... I need a minute.",
        "Removing from foundation. This is a cry for help, isn't it?",
        "BACKWARDS?! The cards go UP, not down!",
        "Un-progressing. Bold. Stupid, but bold.",
    ]

    private let bigStackComments = [
        "Moving a whole stack! Big brain energy right there.",
        "Look at that cascade! Someone's been paying attention.",
        "A multi-card move! You're either a genius or very lucky.",
        "Stack transfer! I'd be impressed if I wasn't so suspicious.",
        "Big stack energy! That's what I'm talking about!",
        "Ooh, look at you moving MULTIPLE cards. Show off.",
    ]

    private let winComments = [
        "YOU WON?! I mean... of course you won. I taught you everything you know.",
        "All 52 cards home! I'm not crying, you're crying.",
        "VICTORY! Against all odds—and I do mean ALL odds—you did it!",
        "Winner winner chicken dinner! I honestly didn't think you had it in you.",
        "The cards are home! Somebody call ESPN, we've got a champion!",
        "YOU ABSOLUTE LEGEND! Wait, was this on easy mode?",
        "I take back every mean thing I said. Most of them. Some of them. A few.",
        "WINNER! And they said you'd never amount to anything!",
        "All cards home! Quick, buy a lottery ticket!",
        "Victory is yours! Frame this moment, it may never happen again.",
    ]
    
    private let fastWinComments = [
        "Speed demon! That was faster than I can insult you!",
        "Lightning quick! Are you some kind of card wizard?",
        "BLITZ WIN! I barely had time to mock you!",
        "That was... actually impressive. Under 3 minutes! 🔥",
        "Speedrun complete! Somebody's been practicing!",
    ]
    
    private let slowWinComments = [
        "FINALLY! I was starting to grow moss over here.",
        "A win's a win, but... did you stop for lunch midway?",
        "Victory! Only took you... *checks watch* ...forever.",
        "You won! The cards were starting to fade from age.",
        "Marathon complete! Persistence beats skill, apparently.",
    ]
    
    private let undoWinComments = [
        "You won! With LIBERAL use of the undo button, but still!",
        "Victory through trial and error. Mostly error.",
        "All those undos paid off! Barely.",
        "You undid your way to victory! Questionable, but valid.",
    ]
    
    private let hintWinComments = [
        "You won! With my help. LOTS of my help.",
        "Victory! I basically held your hand the whole way.",
        "Winner! Though 'assisted win' might be more accurate.",
        "You did it! By which I mean WE did it. Mostly me.",
    ]
    
    private let hintComments = [
        "Oh, fine... try THAT one.",
        "Here's a hint: look where I'm pointing, genius.",
        "Since you asked nicely... there.",
        "A hint? Already? *sigh* Fine, look here.",
        "Needing help already? Classic.",
        "Look. There. You're welcome.",
    ]
    
    private let firstHintComments = [
        "Oh, already need help? Here you go, dear.",
        "First hint of the game? No shame... well, SOME shame.",
        "Let me help you get started, you poor thing.",
        "Giving you a freebie. Don't get used to it.",
    ]
    
    private let manyHintsComments = [
        "ANOTHER hint?! Just let ME play at this point!",
        "You know hints don't count as skill, right?",
        "I'm basically playing this game FOR you now.",
        "Hint machine going BRRR. Have you tried thinking?",
        "At this point I should get credit for the win.",
    ]
    
    private let undoComments = [
        "Taking it back? Even YOU know that was bad.",
        "Undo! Erasing your mistakes, one at a time.",
        "Second thoughts? Good, you needed them.",
        "Undoing that disaster. Wise choice.",
        "Ctrl+Z in card form. I respect it.",
    ]
    
    private let manyUndoComments = [
        "SO many undos! This game is more undo than do!",
        "You've undone so much, we're practically back at the start.",
        "The undo button is filing for overtime pay.",
        "At this point you're not playing, you're rewinding.",
        "Undo count: yes. Just... yes.",
    ]
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
