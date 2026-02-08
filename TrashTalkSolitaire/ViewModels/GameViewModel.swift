import SwiftUI
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published State

    @Published var state: GameState = .empty()
    @Published var commentary: String = "Deal the cards. Let's see what you've got."
    @Published var commentaryMood: CommentaryMood = .neutral
    @Published var selectedSource: MoveSource?
    @Published var hintSource: MoveSource?
    @Published var hintDestination: MoveDestination?
    @Published var isAutoCompleting: Bool = false
    @Published var flyingCard: Card?
    @Published var flyingCardPosition: CGPoint = .zero
    @Published var showNoMovesAlert: Bool = false

    // MARK: - Dependencies

    let commentator = Commentator()
    let speaker = SpeechManager()
    let sounds = SoundManager.shared
    let stats = StatsManager.shared

    // MARK: - Private

    private var undoStack: [Move] = []
    private var undoCount: Int = 0
    private var hintCount: Int = 0
    private var timer: AnyCancellable?
    private var hasRecordedGameEnd = false
    private var gameStarted = false

    // MARK: - Init

    init() {
        deal()
    }

    // MARK: - Deal

    func deal() {
        // Record loss for previous game if it was in progress
        if gameStarted && !hasRecordedGameEnd {
            stats.recordLoss()
        }
        undoStack.removeAll()
        undoCount = 0
        hintCount = 0
        selectedSource = nil
        hasRecordedGameEnd = false
        gameStarted = true
        commentator.resetForNewGame()
        
        let difficulty = DeckDifficulty(rawValue: UserDefaults.standard.string(forKey: "deckDifficulty") ?? "Medium") ?? .medium
        var deck = shuffleDeck(difficulty: difficulty)
        var tableau: [[Card]] = Array(repeating: [], count: 7)

        for col in 0..<7 {
            for row in 0...(col) {
                var card = deck.removeLast()
                card.isFaceUp = (row == col)
                tableau[col].append(card)
            }
        }

        state = GameState(
            tableau: tableau,
            foundations: Array(repeating: [], count: 4),
            stock: deck,
            waste: [],
            moveCount: 0,
            elapsedSeconds: 0,
            isWon: false,
            drawThreeMode: UserDefaults.standard.bool(forKey: "drawThreeMode"),
            vegasMode: UserDefaults.standard.bool(forKey: "vegasMode"),
            vegasScore: UserDefaults.standard.bool(forKey: "vegasMode") ? -52 : 0
        )

        startTimer()
        setCommentary("Fresh deck. Try not to embarrass yourself.", mood: .neutral)
        validateCardCount()
    }
    
    // MARK: - Difficulty-Based Shuffle
    
    private func shuffleDeck(difficulty: DeckDifficulty) -> [Card] {
        var deck = Card.fullDeck()
        
        switch difficulty {
        case .easy:
            // Bias aces and low cards toward the end (more accessible positions)
            deck.shuffle()
            let lowCards = deck.filter { $0.rank.rawValue <= 4 }  // A, 2, 3, 4
            let highCards = deck.filter { $0.rank.rawValue > 4 }
            // Put high cards first (will be buried), low cards after (more accessible)
            deck = highCards.shuffled() + lowCards.shuffled()
            // Add some randomness so it's not too predictable
            for _ in 0..<10 {
                let i = Int.random(in: 0..<deck.count)
                let j = Int.random(in: 0..<deck.count)
                deck.swapAt(i, j)
            }
            
        case .medium:
            // Pure random
            deck.shuffle()
            
        case .hard:
            // Bury aces deep, clump colors together
            deck.shuffle()
            let aces = deck.filter { $0.rank == .ace }
            let nonAces = deck.filter { $0.rank != .ace }
            // Sort non-aces to clump colors (makes alternating harder)
            let sortedNonAces = nonAces.sorted { (card1, card2) -> Bool in
                if card1.color == card2.color {
                    return Bool.random()
                }
                // Group reds together, blacks together
                return card1.color == .red && card2.color == .black
            }
            // Put aces at the front (will be dealt to tableau first = buried deep)
            deck = aces.shuffled() + sortedNonAces
            // Light shuffle to not be too obvious
            for _ in 0..<5 {
                let i = Int.random(in: 4..<deck.count)  // Don't move aces
                let j = Int.random(in: 4..<deck.count)
                deck.swapAt(i, j)
            }
        }
        
        return deck
    }

    // MARK: - Timer

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, !self.state.isWon else { return }
                self.state.elapsedSeconds += 1
            }
    }

    // MARK: - Stock / Waste (Draw 1 or Draw 3)

    func drawFromStock() {
        guard !state.isWon else { return }

        if state.stock.isEmpty {
            // Recycle waste back to stock
            if state.waste.isEmpty { return }
            state.stock = state.waste.reversed().map { card in
                var c = card
                c.isFaceUp = false
                return c
            }
            state.waste = []
            sounds.playCardFlip()
            setCommentary("Recycling the waste pile again? Groundhog Day vibes.", mood: .neutral)
        } else {
            // Draw 1 or 3 cards depending on mode
            let drawCount = state.drawThreeMode ? min(3, state.stock.count) : 1
            
            for _ in 0..<drawCount {
                guard !state.stock.isEmpty else { break }
                var card = state.stock.removeLast()
                card.isFaceUp = true
                state.waste.append(card)
            }
            sounds.playDraw()
        }
        validateCardCount()
        
        // Check for no moves when stock is exhausted
        if state.stock.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.checkForNoMoves()
            }
        }
    }

    // MARK: - Tap-to-Move

    func tapCard(source: MoveSource) {
        guard !state.isWon else { return }

        if let selected = selectedSource {
            // Second tap — try to move
            if selected == source {
                // Tapped same card — try auto-foundation
                if tryAutoFoundation(from: source) {
                    selectedSource = nil
                    return
                }
                selectedSource = nil
                return
            }

            // Try to move selected to this destination
            if let dest = destinationFromTap(source) {
                if executeMove(from: selected, to: dest) {
                    selectedSource = nil
                    return
                }
            }
            // Failed — select the new card instead
            selectedSource = source
        } else {
            // First tap — select this card
            selectedSource = source
        }
    }

    func doubleTapCard(source: MoveSource) {
        guard !state.isWon else { return }
        selectedSource = nil
        _ = tryAutoFoundation(from: source)
    }

    private func destinationFromTap(_ source: MoveSource) -> MoveDestination? {
        switch source {
        case .tableau(let pile, _):
            return .tableau(pile: pile)
        case .foundation(let pile):
            return .foundation(pile: pile)
        case .waste:
            return nil
        }
    }

    private func tryAutoFoundation(from source: MoveSource) -> Bool {
        guard let card = topCardForSource(source) else { return false }

        for i in 0..<4 {
            let top = state.foundations[i].last
            if card.canStackOnFoundation(top) {
                if state.foundations[i].isEmpty || state.foundations[i].last?.suit == card.suit {
                    return executeMove(from: source, to: .foundation(pile: i))
                }
            }
        }
        return false
    }

    private func topCardForSource(_ source: MoveSource) -> Card? {
        switch source {
        case .waste:
            return state.waste.last
        case .tableau(let pile, let idx):
            guard pile < state.tableau.count, idx < state.tableau[pile].count else { return nil }
            return state.tableau[pile][idx]
        case .foundation(let pile):
            return state.foundations[pile].last
        }
    }

    // MARK: - Move Execution

    func executeMove(from source: MoveSource, to destination: MoveDestination) -> Bool {
        let cards: [Card]
        var flippedCard = false

        switch source {
        case .waste:
            guard let card = state.waste.last else { return false }
            cards = [card]
        case .tableau(let pile, let cardIndex):
            guard pile < state.tableau.count,
                  cardIndex < state.tableau[pile].count else { return false }
            cards = Array(state.tableau[pile][cardIndex...])
        case .foundation(let pile):
            guard let card = state.foundations[pile].last else { return false }
            cards = [card]
        }

        guard let firstCard = cards.first else { return false }

        // Validate destination
        switch destination {
        case .tableau(let destPile):
            if let topCard = state.tableau[destPile].last {
                guard firstCard.canStackOnTableau(topCard) else { return false }
            } else {
                guard firstCard.rank == .king else { return false }
            }
        case .foundation(let destPile):
            guard cards.count == 1 else { return false }
            let top = state.foundations[destPile].last
            guard firstCard.canStackOnFoundation(top) else { return false }
            if let top = top {
                guard firstCard.suit == top.suit else { return false }
            }
        }

        // Save state for undo
        let move = Move(
            source: source,
            destination: destination,
            cards: cards,
            flippedCard: false, // updated below
            previousWaste: state.waste,
            previousStock: state.stock
        )

        // Remove cards from source
        switch source {
        case .waste:
            state.waste.removeLast()
        case .tableau(let pile, let cardIndex):
            state.tableau[pile].removeSubrange(cardIndex...)
        case .foundation(let pile):
            state.foundations[pile].removeLast()
            // Vegas: lose $5 for removing from foundation
            if state.vegasMode {
                state.vegasScore -= 5
            }
        }

        // Place cards at destination
        switch destination {
        case .tableau(let destPile):
            state.tableau[destPile].append(contentsOf: cards)
            sounds.playCardPlace()
        case .foundation(let destPile):
            state.foundations[destPile].append(contentsOf: cards)
            sounds.playFoundation()
            // Vegas: earn $5 for each card to foundation
            if state.vegasMode {
                state.vegasScore += 5
            }
        }

        // Auto-flip newly exposed card
        if case .tableau(let pile, _) = source {
            if let last = state.tableau[pile].last, !last.isFaceUp {
                state.tableau[pile][state.tableau[pile].count - 1].isFaceUp = true
                flippedCard = true
            }
        }

        let finalMove = Move(
            source: source,
            destination: destination,
            cards: cards,
            flippedCard: flippedCard,
            previousWaste: move.previousWaste,
            previousStock: move.previousStock
        )
        undoStack.append(finalMove)
        state.moveCount += 1

        // Analyze and comment (only if commentator has something to say)
        if let analysis = commentator.analyzeMove(
            cards: cards,
            source: source,
            destination: destination,
            gameState: state
        ) {
            setCommentary(analysis.comment, mood: analysis.mood)
        }

        checkWin()
        validateCardCount()
        return true
    }

    // MARK: - Undo (with escalating snark)

    func undo() {
        guard let move = undoStack.popLast() else {
            setCommentary("Nothing to undo. Your mistakes are permanent.", mood: .roast)
            return
        }

        selectedSource = nil

        // Un-flip card if needed
        if move.flippedCard {
            if case .tableau(let pile, _) = move.source {
                if !state.tableau[pile].isEmpty {
                    state.tableau[pile][state.tableau[pile].count - 1].isFaceUp = false
                }
            }
        }

        // Remove cards from destination
        switch move.destination {
        case .tableau(let pile):
            let count = move.cards.count
            state.tableau[pile].removeLast(count)
        case .foundation(let pile):
            state.foundations[pile].removeLast(move.cards.count)
            // Vegas: undo foundation means we reverse the +$5
            if state.vegasMode {
                state.vegasScore -= 5
            }
        }

        // Put cards back at source
        switch move.source {
        case .waste:
            state.waste = move.previousWaste
        case .tableau(let pile, let cardIndex):
            state.tableau[pile].insert(contentsOf: move.cards, at: cardIndex)
        case .foundation(let pile):
            state.foundations[pile].append(contentsOf: move.cards)
            // Vegas: undo from foundation means we reverse the -$5
            if state.vegasMode {
                state.vegasScore += 5
            }
        }

        state.moveCount = max(0, state.moveCount - 1)
        undoCount += 1
        commentator.recordUndo()
        
        // Escalating undo snark
        let undoComment: String
        if undoCount <= 2 {
            undoComment = "Changed your mind, dear?"
        } else if undoCount <= 5 {
            undoComment = ["Again? Commitment issues?", "Make up your mind!", "Indecisive much?"].randomElement()!
        } else if undoCount <= 10 {
            undoComment = ["At this point, just start over...", "The undo button is getting worn out!", "This is more undo than do."].randomElement()!
        } else {
            undoComment = ["I've lost count of your undos. Impressive, in a sad way.", "You've undone so much, we're practically back at the start.", "The undo button is filing for overtime pay."].randomElement()!
        }
        setCommentary(undoComment, mood: .roast)
        validateCardCount()
    }

    var canUndo: Bool { !undoStack.isEmpty }

    // MARK: - Win Detection

    private func checkWin() {
        let totalInFoundation = state.foundations.reduce(0) { $0 + $1.count }
        if totalInFoundation == 52 {
            state.isWon = true
            timer?.cancel()
            sounds.playWin()
            HapticManager.shared.win()
            if !hasRecordedGameEnd {
                hasRecordedGameEnd = true
                stats.recordWin(
                    time: state.elapsedSeconds,
                    undoCount: undoCount,
                    hintCount: hintCount,
                    vegasScore: state.vegasMode ? state.vegasScore : 0
                )
            }
            setCommentary(commentator.winComment(), mood: .praise)
        }
    }
    
    // MARK: - Card Count Validation (Debug)
    
    func totalCardCount() -> Int {
        let stockCount = state.stock.count
        let wasteCount = state.waste.count
        let tableauCount = state.tableau.reduce(0) { $0 + $1.count }
        let foundationCount = state.foundations.reduce(0) { $0 + $1.count }
        return stockCount + wasteCount + tableauCount + foundationCount
    }
    
    func validateCardCount() {
        let count = totalCardCount()
        if count != 52 {
            print("⚠️ CARD COUNT ERROR: \(count) cards (should be 52)")
            print("  Stock: \(state.stock.count)")
            print("  Waste: \(state.waste.count)")
            print("  Tableau: \(state.tableau.map { $0.count })")
            print("  Foundations: \(state.foundations.map { $0.count })")
        }
    }

    // MARK: - Auto-Complete (Animated)

    func autoComplete() {
        guard canAutoComplete, !isAutoCompleting else { return }
        
        isAutoCompleting = true
        setCommentary("Let me finish this for you...", mood: .neutral)
        
        // Perform auto-complete with animation delays
        autoCompleteStep()
    }
    
    private func autoCompleteStep() {
        guard !state.isWon else {
            isAutoCompleting = false
            return
        }
        
        var madeMove = false
        
        // Try waste first
        if let card = state.waste.last {
            for i in 0..<4 {
                if card.canStackOnFoundation(state.foundations[i].last) &&
                   (state.foundations[i].isEmpty || state.foundations[i].last?.suit == card.suit) {
                    _ = executeMove(from: .waste, to: .foundation(pile: i))
                    madeMove = true
                    break
                }
            }
        }
        
        // Try tableau if waste didn't work
        if !madeMove {
            outerLoop: for pile in 0..<7 {
                guard let card = state.tableau[pile].last else { continue }
                for i in 0..<4 {
                    if card.canStackOnFoundation(state.foundations[i].last) &&
                       (state.foundations[i].isEmpty || state.foundations[i].last?.suit == card.suit) {
                        let idx = state.tableau[pile].count - 1
                        if executeMove(from: .tableau(pile: pile, cardIndex: idx), to: .foundation(pile: i)) {
                            madeMove = true
                            break outerLoop
                        }
                    }
                }
            }
        }
        
        if madeMove && !state.isWon {
            // Schedule next step with animation delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.autoCompleteStep()
            }
        } else {
            isAutoCompleting = false
        }
    }

    var canAutoComplete: Bool {
        guard !isAutoCompleting else { return false }
        // All cards must be face-up and stock/waste empty (or all face-up)
        let allFaceUp = state.tableau.allSatisfy { pile in
            pile.allSatisfy { $0.isFaceUp }
        }
        return allFaceUp && state.stock.isEmpty
    }

    // MARK: - No Moves Detection
    
    func hasAnyValidMoves() -> Bool {
        // Can draw from stock?
        if !state.stock.isEmpty || !state.waste.isEmpty {
            // Stock not exhausted - might have moves after drawing
            // Only check for true "stuck" when stock is empty AND waste has been cycled
            if !state.stock.isEmpty { return true }
        }
        
        // Check if any hint exists (reuse hint logic)
        if findHint() != nil { return true }
        
        // If stock is empty but waste has cards, we could recycle
        if state.stock.isEmpty && !state.waste.isEmpty { return true }
        
        return false
    }
    
    func checkForNoMoves() {
        // Only check when stock is empty (player has seen all cards)
        guard state.stock.isEmpty else { return }
        
        // Don't check if game is won
        guard !state.isWon else { return }
        
        // Check if any moves exist
        if !hasAnyValidMoves() && state.waste.isEmpty {
            showNoMovesAlert = true
            setCommentary("No more moves available, sir. A regrettable conclusion.", mood: .roast)
        }
    }
    
    // MARK: - Hints
    
    func showHint() {
        guard !state.isWon else { return }
        
        // Clear any existing hint
        hintSource = nil
        hintDestination = nil
        
        if let (source, destination) = findHint() {
            hintSource = source
            hintDestination = destination
            hintCount += 1
            commentator.recordHint()
            HapticManager.shared.hint()
            setCommentary(commentator.hintComment(), mood: .neutral)
            
            // Clear hint after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.clearHint()
            }
        } else {
            setCommentary("No moves available. Try drawing from the stock.", mood: .roast)
        }
    }
    
    func clearHint() {
        withAnimation {
            hintSource = nil
            hintDestination = nil
        }
    }
    
    private func findHint() -> (MoveSource, MoveDestination)? {
        // Priority 1: Foundation moves from waste
        if let card = state.waste.last {
            for i in 0..<4 {
                if card.canStackOnFoundation(state.foundations[i].last) &&
                   (state.foundations[i].isEmpty || state.foundations[i].last?.suit == card.suit) {
                    return (.waste, .foundation(pile: i))
                }
            }
        }
        
        // Priority 2: Foundation moves from tableau
        for pile in 0..<7 {
            guard let card = state.tableau[pile].last, card.isFaceUp else { continue }
            for i in 0..<4 {
                if card.canStackOnFoundation(state.foundations[i].last) &&
                   (state.foundations[i].isEmpty || state.foundations[i].last?.suit == card.suit) {
                    let idx = state.tableau[pile].count - 1
                    return (.tableau(pile: pile, cardIndex: idx), .foundation(pile: i))
                }
            }
        }
        
        // Priority 3: King to empty column
        for pile in 0..<7 {
            for (idx, card) in state.tableau[pile].enumerated() {
                guard card.isFaceUp, card.rank == .king, idx > 0 else { continue }
                // Find an empty column
                for destPile in 0..<7 {
                    if state.tableau[destPile].isEmpty {
                        return (.tableau(pile: pile, cardIndex: idx), .tableau(pile: destPile))
                    }
                }
            }
        }
        
        // Priority 4: Tableau to tableau moves that reveal a card
        for pile in 0..<7 {
            for (idx, card) in state.tableau[pile].enumerated() {
                guard card.isFaceUp else { continue }
                // Check if moving this would reveal a face-down card
                let wouldReveal = idx > 0 && !state.tableau[pile][idx - 1].isFaceUp
                
                for destPile in 0..<7 where destPile != pile {
                    if let topCard = state.tableau[destPile].last {
                        if card.canStackOnTableau(topCard) && wouldReveal {
                            return (.tableau(pile: pile, cardIndex: idx), .tableau(pile: destPile))
                        }
                    }
                }
            }
        }
        
        // Priority 5: Waste to tableau
        if let card = state.waste.last {
            for destPile in 0..<7 {
                if let topCard = state.tableau[destPile].last {
                    if card.canStackOnTableau(topCard) {
                        return (.waste, .tableau(pile: destPile))
                    }
                } else if card.rank == .king {
                    return (.waste, .tableau(pile: destPile))
                }
            }
        }
        
        // Priority 6: Any valid tableau move
        for pile in 0..<7 {
            for (idx, card) in state.tableau[pile].enumerated() {
                guard card.isFaceUp else { continue }
                for destPile in 0..<7 where destPile != pile {
                    if let topCard = state.tableau[destPile].last {
                        if card.canStackOnTableau(topCard) {
                            return (.tableau(pile: pile, cardIndex: idx), .tableau(pile: destPile))
                        }
                    }
                }
            }
        }
        
        return nil
    }

    // MARK: - Commentary

    private func setCommentary(_ text: String, mood: CommentaryMood) {
        withAnimation(.easeInOut(duration: 0.3)) {
            commentary = text
            commentaryMood = mood
        }
        speaker.speak(text)
    }

    // MARK: - Settings
    
    func toggleDrawThreeMode() {
        state.drawThreeMode.toggle()
        UserDefaults.standard.set(state.drawThreeMode, forKey: "drawThreeMode")
        if state.drawThreeMode {
            setCommentary("Draw three, sir. A bolder approach.", mood: .neutral)
        } else {
            setCommentary("Draw one. A more... cautious strategy.", mood: .neutral)
        }
    }
    
    func toggleVegasMode() {
        state.vegasMode.toggle()
        UserDefaults.standard.set(state.vegasMode, forKey: "vegasMode")
        if state.vegasMode {
            state.vegasScore = -52
            setCommentary("Vegas mode! Don't gamble what you can't afford to lose.", mood: .neutral)
        } else {
            state.vegasScore = 0
            setCommentary("Leaving Vegas. Probably wise.", mood: .neutral)
        }
    }
    
    func setDifficulty(_ difficulty: DeckDifficulty) {
        state.difficulty = difficulty
        UserDefaults.standard.set(difficulty.rawValue, forKey: "deckDifficulty")
        switch difficulty {
        case .easy:
            setCommentary("Easy mode. No judgment, sir. Well, perhaps a little.", mood: .neutral)
        case .medium:
            setCommentary("Standard difficulty. As fate intended.", mood: .neutral)
        case .hard:
            setCommentary("Hard mode. I admire your optimism, sir.", mood: .neutral)
        }
    }
    
    var currentDifficulty: DeckDifficulty {
        DeckDifficulty(rawValue: UserDefaults.standard.string(forKey: "deckDifficulty") ?? "Medium") ?? .medium
    }

    // MARK: - Formatted Time

    var formattedTime: String {
        let m = state.elapsedSeconds / 60
        let s = state.elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
    
    var formattedVegasScore: String {
        if state.vegasScore >= 0 {
            return "+$\(state.vegasScore)"
        } else {
            return "-$\(abs(state.vegasScore))"
        }
    }
}
