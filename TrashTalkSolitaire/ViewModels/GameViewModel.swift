import SwiftUI
import Combine

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: - Published State

    @Published var state: GameState = .empty()
    @Published var commentary: String = "Deal the cards. Let's see what you've got."
    @Published var commentaryMood: CommentaryMood = .neutral
    @Published var selectedSource: MoveSource?

    // MARK: - Dependencies

    let commentator = Commentator()
    let speaker = SpeechManager()
    let sounds = SoundManager.shared

    // MARK: - Private

    private var undoStack: [Move] = []
    private var timer: AnyCancellable?

    // MARK: - Init

    init() {
        deal()
    }

    // MARK: - Deal

    func deal() {
        undoStack.removeAll()
        selectedSource = nil
        var deck = Card.fullDeck().shuffled()
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
            isWon: false
        )

        startTimer()
        setCommentary("Fresh deck. Try not to embarrass yourself.", mood: .neutral)
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

    // MARK: - Stock / Waste

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
            var card = state.stock.removeLast()
            card.isFaceUp = true
            state.waste.append(card)
            sounds.playDraw()
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
        }

        // Place cards at destination
        switch destination {
        case .tableau(let destPile):
            state.tableau[destPile].append(contentsOf: cards)
            sounds.playCardPlace()
        case .foundation(let destPile):
            state.foundations[destPile].append(contentsOf: cards)
            sounds.playFoundation()
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
        return true
    }

    // MARK: - Undo

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
        }

        // Put cards back at source
        switch move.source {
        case .waste:
            state.waste = move.previousWaste
        case .tableau(let pile, let cardIndex):
            state.tableau[pile].insert(contentsOf: move.cards, at: cardIndex)
        case .foundation(let pile):
            state.foundations[pile].append(contentsOf: move.cards)
        }

        state.moveCount = max(0, state.moveCount - 1)
        setCommentary("Taking it back? Even YOU know that was bad.", mood: .roast)
    }

    var canUndo: Bool { !undoStack.isEmpty }

    // MARK: - Win Detection

    private func checkWin() {
        let totalInFoundation = state.foundations.reduce(0) { $0 + $1.count }
        if totalInFoundation == 52 {
            state.isWon = true
            timer?.cancel()
            sounds.playWin()
            setCommentary(commentator.winComment(), mood: .praise)
        }
    }

    // MARK: - Auto-Complete

    func autoComplete() {
        guard canAutoComplete else { return }

        // Move all remaining face-up tableau/waste cards to foundations
        var madeMove = true
        while madeMove {
            madeMove = false

            // Try waste
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

            // Try tableau
            for pile in 0..<7 {
                guard let card = state.tableau[pile].last else { continue }
                for i in 0..<4 {
                    if card.canStackOnFoundation(state.foundations[i].last) &&
                       (state.foundations[i].isEmpty || state.foundations[i].last?.suit == card.suit) {
                        let idx = state.tableau[pile].count - 1
                        if executeMove(from: .tableau(pile: pile, cardIndex: idx), to: .foundation(pile: i)) {
                            madeMove = true
                            break
                        }
                    }
                }
                if madeMove { break }
            }
        }
    }

    var canAutoComplete: Bool {
        // All cards must be face-up and stock/waste empty (or all face-up)
        let allFaceUp = state.tableau.allSatisfy { pile in
            pile.allSatisfy { $0.isFaceUp }
        }
        return allFaceUp && state.stock.isEmpty
    }

    // MARK: - Commentary

    private func setCommentary(_ text: String, mood: CommentaryMood) {
        withAnimation(.easeInOut(duration: 0.3)) {
            commentary = text
            commentaryMood = mood
        }
        speaker.speak(text)
    }

    // MARK: - Formatted Time

    var formattedTime: String {
        let m = state.elapsedSeconds / 60
        let s = state.elapsedSeconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
