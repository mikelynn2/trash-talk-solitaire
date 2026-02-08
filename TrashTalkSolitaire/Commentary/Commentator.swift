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
    private let minimumMovesBetweenComments = 5
    private let minimumSecondsBetweenComments: TimeInterval = 10.0
    
    // Track game state for situational comments
    private var undoCount: Int = 0
    private var hintCount: Int = 0
    private var gameStartTime: Date = Date()
    
    // Track used comments to avoid repeats within a session
    private var usedComments: Set<String> = []
    
    // Hard limit: 2-4 comments per hand
    private var commentsThisGame: Int = 0
    private var maxCommentsThisGame: Int = 3  // Set randomly each game
    
    // Probability of commenting even on notable moves (to avoid fatigue)
    private let praiseChance: Double = 0.50     // Higher chance since we have hard limit now
    private let roastChance: Double = 0.50
    private let brilliantChance: Double = 0.70
    private let terribleChance: Double = 0.70

    // MARK: - Game State Tracking
    
    func resetForNewGame() {
        undoCount = 0
        hintCount = 0
        gameStartTime = Date()
        usedComments.removeAll()
        commentsThisGame = 0
        maxCommentsThisGame = Int.random(in: 2...4)  // 2-4 comments per hand
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
        
        // Hard limit: 2-4 comments per hand
        guard commentsThisGame < maxCommentsThisGame else {
            return nil
        }
        
        // We're commenting - update tracking
        lastCommentTime = Date()
        movesSinceLastComment = 0
        commentsThisGame += 1
        
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
            return "Three consecutive victories, sir. Most adequate."
        case 5:
            return "Five in succession. I confess myself... not entirely unimpressed."
        case 10:
            return "Ten victories. I shall inform the household staff. 🏆"
        default:
            return nil
        }
    }

    // MARK: - Commentary Banks (British Butler Voice)

    private let aceToFoundationComments = [
        "The ace finds its place, sir. As even you could manage.",
        "Ace to foundation. The most elementary of moves, yet here we are celebrating.",
        "An ace placed correctly. Shall I fetch a medal?",
        "Foundation ace. The cards practically placed themselves.",
        "An ace, sir. One does hope this sets a precedent.",
        "Ace secured. Even a child could manage as much.",
        "The ace is home. I shall try to contain my astonishment.",
        "Ace to foundation. Textbook, if the textbook were written for beginners.",
    ]

    private let kingToFoundationComments = [
        "A king to the foundation. I confess, sir, I did not anticipate competence.",
        "The suit is complete. I shall alert the press.",
        "King home at last. Even I must acknowledge this achievement.",
        "A full suit, sir. Most... unexpected.",
        "The king rests upon his throne. Well played, I suppose.",
        "Complete. I find myself nearly impressed.",
    ]

    private let foundationComments = [
        "A foundation move. One begins to see glimmers of potential.",
        "Well placed, sir. Do try to remember this feeling.",
        "Foundation. Adequate. One might even say 'competent.'",
        "A sensible move. How refreshingly out of character.",
        "To the foundation. Perhaps there is hope for you yet.",
        "Card secured. I shan't grow accustomed to this level of play.",
        "Foundation bound. The ancestors would be... less disappointed.",
        "A proper move, sir. More of this, if you please.",
        "Well executed. I shall make a note in the ledger.",
        "Foundation. You continue to surprise, sir. Not always pleasantly, but still.",
        "Quite right. That is precisely where it belongs.",
        "Progress, sir. Slow, meandering progress, but progress nonetheless.",
    ]

    private let kingToEmptyComments = [
        "King to the empty column. Even you couldn't misplace a king.",
        "The king takes his throne. A move so obvious, even you found it.",
        "King to vacancy. Correct, sir. Savour the novelty.",
        "A king where a king belongs. Revolutionary thinking.",
        "The empty column accepts its king. How terribly conventional of you.",
        "King placed. One does appreciate adherence to basic principles.",
    ]

    private let revealComments = [
        "A hidden card reveals itself. The suspense was... manageable.",
        "The card turns. Let us see what you make of it.",
        "Revealed, sir. I trust you have a plan. Any plan.",
        "A new card emerges. The plot, as they say, thickens.",
        "Uncovered. One hopes you shan't waste this opportunity.",
        "The mystery resolves. Now, do try not to bury it immediately.",
        "A card brought to light. How illuminating.",
        "Revealed. The possibilities expand. Your execution, less so.",
    ]

    private let buryComments = [
        "Burying a card, sir? A bold strategy. Bold, and inadvisable.",
        "That card had potential, sir. Had.",
        "I have served many masters, sir. None have buried cards with such enthusiasm.",
        "One observes you building a monument to poor decisions.",
        "That move, sir, would make a fish weep.",
        "Ah yes, the 'create problems for future self' approach.",
        "I have seen better moves from gentlemen three bottles deep in port.",
        "That pile grows ever more... regrettable.",
        "Burying treasure, sir? No. Burying opportunities.",
        "That card shall not see daylight again in this lifetime.",
        "A curious choice. 'Curious' being charitable.",
        "Sir. That card had a family.",
    ]

    private let foundationToTableauComments = [
        "Removing from the foundation, sir? Are you quite well?",
        "Backwards, sir. We appear to be going backwards.",
        "From foundation to tableau. Unconventional. Also incorrect.",
        "I... shall require a moment to process this decision.",
        "Retreating from progress. A metaphor, perhaps?",
        "The cards go UP, sir. It is rather the point.",
        "Un-winning, sir. A novel approach to solitaire.",
    ]

    private let bigStackComments = [
        "A cascade, sir. Someone has been paying attention.",
        "Multiple cards in motion. One detects a hint of strategy.",
        "A substantial move. Either brilliance or luck. I suspect the latter.",
        "The stack transfers. I shall endeavour to look impressed.",
        "Cards in formation. Most orderly of you.",
        "A considerable relocation. Well managed, I suppose.",
    ]

    private let winComments = [
        "Victory, sir. I shall admit to a modicum of surprise.",
        "All cards home. Against considerable odds, you've done it.",
        "Complete. I withdraw several of my previous observations.",
        "You've won, sir. I shall have the champagne brought round.",
        "The game is yours. Savour it. Such moments may be rare.",
        "Triumph. I confess myself... not entirely disappointed.",
        "Finished, and successfully. The household shall be informed.",
        "Victory is yours, sir. I shall update my assessment accordingly.",
        "All fifty-two, home safe. Well played, sir. Genuinely.",
        "Won. I shall try not to appear astonished.",
    ]
    
    private let fastWinComments = [
        "Swiftly done, sir. I barely had time to form criticisms.",
        "Speed and precision. Are you quite certain you're the usual player?",
        "Rapid victory. Most efficient.",
        "Under three minutes, sir. I am genuinely impressed.",
        "Lightning pace. Perhaps I have underestimated you.",
    ]
    
    private let slowWinComments = [
        "At last, sir. I was beginning to gather dust.",
        "Victory achieved. Eventually. Very eventually.",
        "A win, sir. The scenic route, but a win nonetheless.",
        "Complete. I had begun to draft my memoirs in the interim.",
        "Finished. Patience, they say, is a virtue. You've tested mine thoroughly.",
    ]
    
    private let undoWinComments = [
        "Won, sir. With considerable assistance from the undo function.",
        "Victory through revision. Many, many revisions.",
        "Complete. The undo button has earned its keep today.",
        "You've won, sir. By the most circuitous path imaginable.",
    ]
    
    private let hintWinComments = [
        "Victory, sir. Though 'collaborative effort' might be more accurate.",
        "Won, with guidance. Substantial guidance.",
        "Complete. I trust you recognise my contribution.",
        "Finished. 'Team effort' shall be the official record.",
    ]
    
    private let hintComments = [
        "Very well, sir. Observe.",
        "A hint, as requested. Do try to internalise it.",
        "If I may direct your attention... there.",
        "Assistance rendered, sir. Again.",
        "The move you seek is here. Obviously.",
        "As you wish. Behold.",
    ]
    
    private let firstHintComments = [
        "Already, sir? Very well. Here.",
        "A hint so soon? No matter. Look here.",
        "Requiring assistance already. How very expected.",
        "The first of what I anticipate shall be many. There you are.",
    ]
    
    private let manyHintsComments = [
        "Another hint, sir? At this point, shall I simply play for you?",
        "Hints do not accumulate into skill, sir.",
        "I appear to be doing the thinking for both of us.",
        "One more hint. I'm keeping count, naturally.",
        "Sir, at this juncture, the victory shall be mine by proxy.",
    ]
    
    private let undoComments = [
        "Reconsidering, sir? Wise, given the circumstances.",
        "The undo. A gentleman's admission of error.",
        "Taking it back. Even you recognised that mistake.",
        "Reversed, sir. A prudent retreat.",
        "The move undone. Progress through regression.",
    ]
    
    private let manyUndoComments = [
        "Sir, the undo button is not a strategy.",
        "We appear to be playing in reverse.",
        "So many undos. Are we making progress or merely oscillating?",
        "The undo count grows concerning, sir.",
        "At this rate, we shall arrive back at the initial deal.",
    ]
}

// MARK: - Safe Array Access

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
