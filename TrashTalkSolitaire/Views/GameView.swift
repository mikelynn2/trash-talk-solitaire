import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()
    @State private var showSettings = false
    @State private var dragCards: [Card] = []
    @State private var dragSource: MoveSource?
    @State private var dragOffset: CGSize = .zero
    @State private var cardFrames: [UUID: CGRect] = [:]

    private let cardWidth: CGFloat = 55
    private var cardHeight: CGFloat { cardWidth * 1.4 }
    private let tableauSpacing: CGFloat = 18

    var body: some View {
        GeometryReader { geo in
            let hPad: CGFloat = 8
            let colWidth = (geo.size.width - hPad * 2) / 7

            ZStack {
                // Green felt background
                Color(red: 0.05, green: 0.25, blue: 0.12)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Top bar
                    topBar
                        .padding(.horizontal, 12)
                        .padding(.top, 4)

                    // Commentary
                    CommentaryBubble(text: vm.commentary, mood: vm.commentaryMood)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .animation(.easeInOut(duration: 0.3), value: vm.commentary)

                    // Stock, Waste, and Foundations row
                    HStack(spacing: 0) {
                        // Stock
                        stockView
                            .frame(width: colWidth)

                        // Waste
                        wasteView
                            .frame(width: colWidth)

                        Spacer()
                            .frame(width: colWidth)

                        // 4 Foundation piles
                        ForEach(0..<4, id: \.self) { i in
                            foundationView(pile: i)
                                .frame(width: colWidth)
                        }
                    }
                    .padding(.horizontal, hPad)
                    .padding(.bottom, 8)

                    // Tableau
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<7, id: \.self) { pile in
                            tableauPileView(pile: pile, colWidth: colWidth)
                                .frame(width: colWidth)
                        }
                    }
                    .padding(.horizontal, hPad)

                    Spacer()
                }

                // Win overlay
                if vm.state.isWon {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)

                    WinOverlay(
                        moveCount: vm.state.moveCount,
                        time: vm.formattedTime,
                        onNewGame: { vm.deal() }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.5), value: vm.state.isWon)
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
        }
        .statusBarHidden(false)
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { vm.deal() }) {
                Label("New", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
            }

            Spacer()

            // Move counter
            HStack(spacing: 4) {
                Image(systemName: "hand.tap")
                    .font(.system(size: 11))
                Text("\(vm.state.moveCount)")
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(.white.opacity(0.8))

            Spacer()

            // Timer
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                Text(vm.formattedTime)
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
            }
            .foregroundColor(.white.opacity(0.8))

            Spacer()

            // Undo
            Button(action: { vm.undo() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(vm.canUndo ? .white : .white.opacity(0.3))
            }
            .disabled(!vm.canUndo)

            Spacer()

            // Auto-complete
            if vm.canAutoComplete {
                Button(action: { vm.autoComplete() }) {
                    Label("Auto", systemImage: "sparkles")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.yellow)
                }
            }

            // Settings
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }

    // MARK: - Stock

    private var stockView: some View {
        ZStack {
            if vm.state.stock.isEmpty {
                EmptyPileView(label: "↻", width: cardWidth)
                    .onTapGesture { vm.drawFromStock() }
            } else {
                CardView(card: Card(suit: .spades, rank: .ace), width: cardWidth)
                    .onTapGesture { vm.drawFromStock() }
            }
        }
    }

    // MARK: - Waste

    private var wasteView: some View {
        ZStack {
            if let card = vm.state.waste.last {
                let isSelected = isSourceSelected(.waste)
                CardView(card: card, isSelected: isSelected, width: cardWidth)
                    .onTapGesture { vm.tapCard(source: .waste) }
                    .onTapGesture(count: 2) { vm.doubleTapCard(source: .waste) }
                    .gesture(dragGesture(for: .waste, cards: [card]))
                    .zIndex(isBeingDragged(.waste) ? 100 : 0)
                    .offset(isBeingDragged(.waste) ? dragOffset : .zero)
            } else {
                EmptyPileView(width: cardWidth)
            }
        }
    }

    // MARK: - Foundation

    private func foundationView(pile: Int) -> some View {
        ZStack {
            let suitLabels = ["♣", "♦", "♥", "♠"]
            if let card = vm.state.foundations[pile].last {
                CardView(card: card, width: cardWidth)
                    .onTapGesture {
                        vm.tapCard(source: .foundation(pile: pile))
                    }
            } else {
                EmptyPileView(label: suitLabels[pile], width: cardWidth)
                    .onTapGesture {
                        vm.tapCard(source: .foundation(pile: pile))
                    }
            }
        }
    }

    // MARK: - Tableau

    private func tableauPileView(pile: Int, colWidth: CGFloat) -> some View {
        let cards = vm.state.tableau[pile]

        return ZStack(alignment: .top) {
            if cards.isEmpty {
                EmptyPileView(width: cardWidth)
                    .onTapGesture {
                        vm.tapCard(source: .tableau(pile: pile, cardIndex: 0))
                    }
            }

            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let source = MoveSource.tableau(pile: pile, cardIndex: index)
                let isSelected = isSourceSelected(source)
                let isDragging = isBeingDragged(source)
                let isPartOfDrag = isDraggedSubstack(pile: pile, cardIndex: index)

                CardView(card: card, isSelected: isSelected, width: cardWidth)
                    .offset(y: CGFloat(index) * tableauSpacing)
                    .zIndex(Double(index) + (isPartOfDrag ? 200 : 0))
                    .offset(isPartOfDrag ? dragOffset : .zero)
                    .opacity(isPartOfDrag && !isDragging ? 0.9 : 1.0)
                    .onTapGesture(count: 2) {
                        guard card.isFaceUp else { return }
                        vm.doubleTapCard(source: source)
                    }
                    .onTapGesture {
                        guard card.isFaceUp else { return }
                        vm.tapCard(source: source)
                    }
                    .gesture(card.isFaceUp ? dragGesture(for: source, cards: Array(cards[index...])) : nil)
            }
        }
        .frame(height: max(cardHeight, cardHeight + CGFloat(max(0, cards.count - 1)) * tableauSpacing))
    }

    // MARK: - Drag & Drop

    private func dragGesture(for source: MoveSource, cards: [Card]) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                if dragSource == nil {
                    dragSource = source
                    dragCards = cards
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                handleDrop(at: value.location)
                withAnimation(.spring(response: 0.3)) {
                    dragOffset = .zero
                }
                dragSource = nil
                dragCards = []
            }
    }

    private func handleDrop(at location: CGPoint) {
        guard let source = dragSource else { return }

        // Try dropping on each foundation
        for pile in 0..<4 {
            if let frame = foundationFrame(pile: pile, location: location) {
                if frame.contains(location) {
                    _ = vm.executeMove(from: source, to: .foundation(pile: pile))
                    vm.selectedSource = nil
                    return
                }
            }
        }

        // Try dropping on each tableau pile
        for pile in 0..<7 {
            if let frame = tableauFrame(pile: pile, location: location) {
                if frame.contains(location) {
                    _ = vm.executeMove(from: source, to: .tableau(pile: pile))
                    vm.selectedSource = nil
                    return
                }
            }
        }
    }

    // Simple hit-testing using screen geometry
    private func foundationFrame(pile: Int, location: CGPoint) -> CGRect? {
        let screenWidth = UIScreen.main.bounds.width
        let hPad: CGFloat = 8
        let colWidth = (screenWidth - hPad * 2) / 7
        let x = hPad + colWidth * CGFloat(3 + pile) + (colWidth - cardWidth) / 2
        let y: CGFloat = 120 // approximate
        return CGRect(x: x, y: y, width: cardWidth, height: cardHeight)
    }

    private func tableauFrame(pile: Int, location: CGPoint) -> CGRect? {
        let screenWidth = UIScreen.main.bounds.width
        let hPad: CGFloat = 8
        let colWidth = (screenWidth - hPad * 2) / 7
        let x = hPad + colWidth * CGFloat(pile) + (colWidth - cardWidth) / 2
        let y: CGFloat = 200 // approximate top of tableau
        let pileCount = vm.state.tableau[pile].count
        let height = cardHeight + CGFloat(max(0, pileCount - 1)) * tableauSpacing + 40
        return CGRect(x: x, y: y, width: cardWidth, height: height)
    }

    private func isSourceSelected(_ source: MoveSource) -> Bool {
        vm.selectedSource == source
    }

    private func isBeingDragged(_ source: MoveSource) -> Bool {
        dragSource == source
    }

    private func isDraggedSubstack(pile: Int, cardIndex: Int) -> Bool {
        guard case .tableau(let dragPile, let dragIndex) = dragSource else { return false }
        return pile == dragPile && cardIndex >= dragIndex
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Mute toggle
                Toggle(isOn: Binding(
                    get: { vm.speaker.isMuted },
                    set: { _ in vm.speaker.toggleMute() }
                )) {
                    Label("Mute Commentary", systemImage: vm.speaker.isMuted ? "speaker.slash" : "speaker.wave.2")
                }

                // Speech rate
                VStack(alignment: .leading) {
                    Text("Speech Rate")
                        .font(.headline)
                    Slider(
                        value: Binding(
                            get: { vm.speaker.speechRate },
                            set: { vm.speaker.speechRate = $0 }
                        ),
                        in: 0.3...0.7,
                        step: 0.05
                    )
                    HStack {
                        Text("Slow")
                            .font(.caption)
                        Spacer()
                        Text("Fast")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showSettings = false }
                }
            }
        }
    }
}

// MARK: - Win Overlay

struct WinOverlay: View {
    let moveCount: Int
    let time: String
    let onNewGame: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("🏆")
                .font(.system(size: 80))

            Text("YOU WIN!")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundColor(.yellow)

            VStack(spacing: 8) {
                Text("Moves: \(moveCount)")
                Text("Time: \(time)")
            }
            .font(.system(size: 18, weight: .medium))
            .foregroundColor(.white.opacity(0.8))

            Button(action: onNewGame) {
                Text("New Game")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.85))
        )
    }
}
