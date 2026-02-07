import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()
    @State private var showSettings = false
    @State private var dragCards: [Card] = []
    @State private var dragSource: MoveSource?
    @State private var dragOffset: CGSize = .zero
    @State private var dragStartLocation: CGPoint = .zero
    @State private var cardFrames: [UUID: CGRect] = [:]

    private let cardWidth: CGFloat = 58
    private var cardHeight: CGFloat { cardWidth * 1.35 }
    private let tableauSpacing: CGFloat = 22

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
                        .padding(.top, 6)
                        .padding(.bottom, 28)
                        .animation(.easeInOut(duration: 0.3), value: vm.commentary)

                    // Stock, Waste, and Foundations row
                    HStack(spacing: 0) {
                        // Stock
                        stockView
                            .frame(width: colWidth, alignment: .center)

                        // Waste
                        wasteView
                            .frame(width: colWidth, alignment: .center)

                        Spacer()
                            .frame(width: colWidth)

                        // 4 Foundation piles
                        ForEach(0..<4, id: \.self) { i in
                            foundationView(pile: i)
                                .frame(width: colWidth, alignment: .center)
                        }
                    }
                    .padding(.horizontal, hPad)
                    .padding(.bottom, 20)

                    // Tableau
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<7, id: \.self) { pile in
                            tableauPileView(pile: pile, colWidth: colWidth)
                                .frame(width: colWidth, alignment: .center)
                        }
                    }
                    .padding(.horizontal, hPad)

                    Spacer()
                }

                // Dragged cards overlay (renders on top of everything)
                if !dragCards.isEmpty {
                    draggedCardsOverlay
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
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .onTapGesture { vm.tapCard(source: .waste) }
                    .onTapGesture(count: 2) { vm.doubleTapCard(source: .waste) }
                    .gesture(dragGesture(for: .waste, cards: [card]))
                    .opacity(isBeingDragged(.waste) ? 0.0 : 1.0)
            } else {
                EmptyPileView(width: cardWidth)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.state.waste.count)
    }

    // MARK: - Foundation

    private func foundationView(pile: Int) -> some View {
        ZStack {
            let suitLabels = ["♣", "♦", "♥", "♠"]
            if let card = vm.state.foundations[pile].last {
                CardView(card: card, width: cardWidth)
                    .transition(.scale.combined(with: .opacity))
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
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.state.foundations[pile].count)
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
                let isPartOfDrag = isDraggedSubstack(pile: pile, cardIndex: index)

                CardView(card: card, isSelected: isSelected, width: cardWidth)
                    .offset(y: CGFloat(index) * tableauSpacing)
                    .zIndex(Double(index))
                    .opacity(isPartOfDrag ? 0.0 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: index)
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
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: cards.count)
        .frame(height: max(cardHeight, cardHeight + CGFloat(max(0, cards.count - 1)) * tableauSpacing))
    }

    // MARK: - Drag & Drop

    private func dragGesture(for source: MoveSource, cards: [Card]) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                if dragSource == nil {
                    dragSource = source
                    dragCards = cards
                    dragStartLocation = value.startLocation
                }
                dragOffset = value.translation
            }
            .onEnded { value in
                // Check for flick gesture (fast swipe)
                let velocity = CGSize(
                    width: value.predictedEndLocation.x - value.location.x,
                    height: value.predictedEndLocation.y - value.location.y
                )
                let speed = hypot(velocity.width, velocity.height)
                
                if speed > 100 {
                    // It's a flick! Try to auto-move based on direction
                    handleFlick(velocity: velocity, from: source)
                } else {
                    // Normal drop
                    handleDrop(at: value.location)
                }
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    dragOffset = .zero
                }
                dragSource = nil
                dragCards = []
                dragStartLocation = .zero
            }
    }
    
    private func handleFlick(velocity: CGSize, from source: MoveSource) {
        // Flick up = try foundation first
        if velocity.height < -50 && dragCards.count == 1 {
            if let card = dragCards.first {
                for pile in 0..<4 {
                    if canDropOnFoundation(pile: pile) {
                        _ = vm.executeMove(from: source, to: .foundation(pile: pile))
                        vm.selectedSource = nil
                        return
                    }
                }
            }
        }
        
        // Flick left/right = find tableau pile in that direction
        if abs(velocity.width) > abs(velocity.height) {
            let currentX = dragStartLocation.x
            let screenWidth = UIScreen.main.bounds.width
            let colWidth = screenWidth / 7
            let currentPile = Int(currentX / colWidth)
            
            // Determine target pile based on flick direction
            let targetPiles: [Int]
            if velocity.width > 0 {
                // Flicking right
                targetPiles = Array((currentPile + 1)..<7)
            } else {
                // Flicking left
                targetPiles = Array((0..<currentPile).reversed())
            }
            
            for pile in targetPiles {
                if canDropOnTableau(pile: pile) {
                    _ = vm.executeMove(from: source, to: .tableau(pile: pile))
                    vm.selectedSource = nil
                    return
                }
            }
        }
        
        // Fallback to normal drop detection
        let endLocation = CGPoint(
            x: dragStartLocation.x + dragOffset.width + velocity.width * 0.3,
            y: dragStartLocation.y + dragOffset.height + velocity.height * 0.3
        )
        handleDrop(at: endLocation)
    }

    // MARK: - Dragged Cards Overlay

    private var draggedCardsOverlay: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(dragCards.enumerated()), id: \.element.id) { index, card in
                CardView(card: card, width: cardWidth)
                    .offset(y: CGFloat(index) * tableauSpacing)
            }
        }
        .position(
            x: dragStartLocation.x + dragOffset.width,
            y: dragStartLocation.y + dragOffset.height + CGFloat(dragCards.count - 1) * tableauSpacing / 2
        )
        .zIndex(1000)
    }

    private func handleDrop(at location: CGPoint) {
        guard let source = dragSource else { return }
        
        // Find the closest valid target (by distance to center)
        var bestTarget: MoveDestination?
        var bestDistance: CGFloat = .infinity
        
        // Check foundations (only for single cards)
        if dragCards.count == 1 {
            for pile in 0..<4 {
                let center = foundationCenter(pile: pile)
                let distance = hypot(location.x - center.x, location.y - center.y)
                if distance < bestDistance && distance < 150 { // Max 150pt away
                    // Check if move would be valid
                    if canDropOnFoundation(pile: pile) {
                        bestDistance = distance
                        bestTarget = .foundation(pile: pile)
                    }
                }
            }
        }
        
        // Check tableau piles
        for pile in 0..<7 {
            let center = tableauDropCenter(pile: pile)
            let distance = hypot(location.x - center.x, location.y - center.y)
            if distance < bestDistance && distance < 150 { // Max 150pt away
                // Check if move would be valid
                if canDropOnTableau(pile: pile) {
                    bestDistance = distance
                    bestTarget = .tableau(pile: pile)
                }
            }
        }
        
        // Execute the best valid move found
        if let target = bestTarget {
            _ = vm.executeMove(from: source, to: target)
            vm.selectedSource = nil
        }
    }
    
    private func canDropOnFoundation(pile: Int) -> Bool {
        guard let card = dragCards.first, dragCards.count == 1 else { return false }
        let topCard = vm.state.foundations[pile].last
        return card.canStackOnFoundation(topCard) &&
               (vm.state.foundations[pile].isEmpty || topCard?.suit == card.suit)
    }
    
    private func canDropOnTableau(pile: Int) -> Bool {
        guard let card = dragCards.first else { return false }
        if vm.state.tableau[pile].isEmpty {
            return card.rank == .king
        }
        if let topCard = vm.state.tableau[pile].last {
            return card.canStackOnTableau(topCard)
        }
        return false
    }
    
    private func foundationCenter(pile: Int) -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        let hPad: CGFloat = 8
        let colWidth = (screenWidth - hPad * 2) / 7
        let x = hPad + colWidth * CGFloat(3 + pile) + colWidth / 2
        let y: CGFloat = 170
        return CGPoint(x: x, y: y)
    }
    
    private func tableauDropCenter(pile: Int) -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        let hPad: CGFloat = 8
        let colWidth = (screenWidth - hPad * 2) / 7
        let x = hPad + colWidth * CGFloat(pile) + colWidth / 2
        let pileCount = vm.state.tableau[pile].count
        // Target the bottom of the pile (where you'd drop)
        let y: CGFloat = 265 + CGFloat(max(0, pileCount - 1)) * tableauSpacing + cardHeight / 2
        return CGPoint(x: x, y: y)
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
    
    @State private var showConfetti = false
    @State private var trophyScale: CGFloat = 0.1
    @State private var trophyRotation: Double = -30
    
    var body: some View {
        ZStack {
            // Confetti layer
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 20) {
                Text("🏆")
                    .font(.system(size: 100))
                    .scaleEffect(trophyScale)
                    .rotationEffect(.degrees(trophyRotation))

                Text("YOU WIN!")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 10)

                VStack(spacing: 8) {
                    Text("Moves: \(moveCount)")
                    Text("Time: \(time)")
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))

                Button(action: onNewGame) {
                    Text("Play Again")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(Color.yellow)
                        .cornerRadius(12)
                        .shadow(color: .yellow.opacity(0.5), radius: 8)
                }
                .padding(.top, 10)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.black.opacity(0.9))
                    .shadow(color: .yellow.opacity(0.3), radius: 20)
            )
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                trophyScale = 1.2
                trophyRotation = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.3)) {
                    trophyScale = 1.0
                }
            }
            showConfetti = true
        }
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                for particle in particles {
                    let age = now - particle.createdAt
                    guard age < particle.lifetime else { continue }
                    
                    let progress = age / particle.lifetime
                    let y = particle.startY + (age * particle.speed) + (age * age * 200) // gravity
                    let x = particle.startX + sin(age * particle.wobbleSpeed) * particle.wobbleAmount
                    let rotation = age * particle.rotationSpeed
                    let opacity = 1.0 - (progress * 0.5)
                    
                    guard y < size.height + 50 else { continue }
                    
                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: .degrees(rotation))
                    
                    let rect = CGRect(x: -particle.size/2, y: -particle.size/2, width: particle.size, height: particle.size * 0.6)
                    context.fill(Path(rect), with: .color(particle.color))
                    
                    context.rotate(by: .degrees(-rotation))
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .onAppear {
            createParticles()
        }
    }
    
    private func createParticles() {
        let colors: [Color] = [.red, .yellow, .green, .blue, .purple, .orange, .pink, .cyan]
        let screenWidth = UIScreen.main.bounds.width
        
        for _ in 0..<150 {
            particles.append(ConfettiParticle(
                startX: CGFloat.random(in: 0...screenWidth),
                startY: CGFloat.random(in: -100...(-20)),
                speed: CGFloat.random(in: 80...200),
                size: CGFloat.random(in: 8...16),
                color: colors.randomElement()!,
                lifetime: Double.random(in: 3...5),
                wobbleSpeed: Double.random(in: 2...6),
                wobbleAmount: CGFloat.random(in: 20...60),
                rotationSpeed: Double.random(in: 100...400),
                createdAt: Date().timeIntervalSinceReferenceDate + Double.random(in: 0...0.8)
            ))
        }
    }
}

struct ConfettiParticle {
    let startX: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let size: CGFloat
    let color: Color
    let lifetime: Double
    let wobbleSpeed: Double
    let wobbleAmount: CGFloat
    let rotationSpeed: Double
    let createdAt: TimeInterval
}
