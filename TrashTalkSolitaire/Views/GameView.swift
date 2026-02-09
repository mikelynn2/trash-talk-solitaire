import SwiftUI

struct GameView: View {
    @StateObject private var vm = GameViewModel()
    @State private var showSettings = false
    @State private var showAchievements = false
    @State private var showDebugTest = false
    @State private var dragCards: [Card] = []
    @State private var dragSource: MoveSource?
    @State private var dragOffset: CGSize = .zero
    @State private var dragStartLocation: CGPoint = .zero
    @State private var cardFrames: [UUID: CGRect] = [:]

    private let cardWidth: CGFloat = 50
    private var cardHeight: CGFloat { cardWidth * 1.4 }
    private let tableauSpacing: CGFloat = 18

    var body: some View {
        GeometryReader { geo in
            let hPad: CGFloat = 4
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

                        // Waste (with Draw 3 fan)
                        wasteView
                            .frame(width: colWidth + (vm.state.drawThreeMode ? 20 : 0), alignment: .center)

                        Spacer()
                            .frame(width: colWidth - (vm.state.drawThreeMode ? 20 : 0))

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
                    
                    // Vegas cumulative earnings (bottom bar)
                    if vm.state.vegasMode {
                        VegasBankrollView(amount: vm.stats.vegasCumulative)
                    }
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
                        vegasScore: vm.state.vegasMode ? vm.state.vegasScore : nil,
                        onNewGame: { vm.deal() }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Achievement unlock toast
                if let achievement = vm.stats.newlyUnlockedAchievement {
                    AchievementToast(achievement: achievement)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(2000)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: vm.state.isWon)
            .animation(.spring(), value: vm.stats.newlyUnlockedAchievement != nil)
            .sheet(isPresented: $showSettings) {
                settingsSheet
            }
            .sheet(isPresented: $showAchievements) {
                achievementsSheet
            }
            .alert("No Moves Available", isPresented: $vm.showNoMovesAlert) {
                Button("New Game") {
                    vm.deal()
                }
                Button("Keep Trying", role: .cancel) { }
            } message: {
                Text("There are no more valid moves. Would you like to start a new game?")
            }
            .alert("🚨 Card Count Error", isPresented: $vm.showCardCountError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(vm.cardCountErrorMessage)
            }
            .sheet(isPresented: $showDebugTest) {
                debugTestSheet
            }
        }
        .statusBarHidden(false)
    }
    
    // MARK: - Debug Test Sheet
    
    private var debugTestSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Card Count Bug Test")
                    .font(.title2.bold())
                
                Text("This will play \(100) games automatically and check for missing cards after every move.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if vm.isAutoPlayRunning {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                }
                
                ScrollView {
                    Text(vm.autoPlayLog)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(height: 300)
                .background(Color.black.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Button(action: {
                    vm.runAutoPlayTest(games: 100, movesPerGame: 200)
                }) {
                    Text(vm.isAutoPlayRunning ? "Running..." : "Run 100 Game Test")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(vm.isAutoPlayRunning ? Color.gray : Color.blue)
                        .cornerRadius(10)
                }
                .disabled(vm.isAutoPlayRunning)
                .padding(.horizontal)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showDebugTest = false }
                }
            }
        }
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

            // Vegas score OR move counter
            if vm.state.vegasMode {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(vm.state.vegasScore >= 0 ? .green : .red)
                    Text(vm.formattedVegasScore)
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                        .foregroundColor(vm.state.vegasScore >= 0 ? .green : .red)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 11))
                    Text("\(vm.state.moveCount)")
                        .font(.system(size: 13, weight: .semibold, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.8))
            }

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

            // Hint
            Button(action: { vm.showHint() }) {
                Image(systemName: "lightbulb")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.yellow.opacity(0.9))
            }

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
            
            // Draw mode toggle badge
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { vm.toggleDrawThreeMode() }) {
                        Text(vm.state.drawThreeMode ? "×3" : "×1")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 16)
                            .background(
                                Capsule()
                                    .fill(vm.state.drawThreeMode ? Color.orange : Color.blue)
                            )
                    }
                    .offset(x: 4, y: 4)
                }
            }
            .frame(width: cardWidth, height: cardWidth * 1.4)
        }
    }

    // MARK: - Waste (with Draw 3 fan)

    private var wasteView: some View {
        ZStack {
            if vm.state.drawThreeMode {
                // Draw 3: Show up to 3 fanned cards
                let visibleCount = min(3, vm.state.waste.count)
                let startIndex = max(0, vm.state.waste.count - 3)
                
                ForEach(0..<visibleCount, id: \.self) { i in
                    let cardIndex = startIndex + i
                    let card = vm.state.waste[cardIndex]
                    let isTopCard = i == visibleCount - 1
                    let isSelected = isTopCard && isSourceSelected(.waste)
                    let isHinted = isTopCard && isHintSource(.waste)
                    
                    CardView(card: card, isSelected: isSelected, isHinted: isHinted, width: cardWidth)
                        .offset(x: CGFloat(i) * 12)
                        .zIndex(Double(i))
                        .allowsHitTesting(isTopCard)
                        .onTapGesture {
                            if isTopCard { vm.tapCard(source: .waste) }
                        }
                        .onTapGesture(count: 2) {
                            if isTopCard { vm.doubleTapCard(source: .waste) }
                        }
                        .gesture(isTopCard ? dragGesture(for: .waste, cards: [card]) : nil)
                        .opacity(isTopCard && isBeingDragged(.waste) ? 0.0 : 1.0)
                }
            } else {
                // Draw 1: Single card
                if let card = vm.state.waste.last {
                    let isSelected = isSourceSelected(.waste)
                    let isHinted = isHintSource(.waste)
                    CardView(card: card, isSelected: isSelected, isHinted: isHinted, width: cardWidth)
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
        }
        .frame(width: vm.state.drawThreeMode ? cardWidth + 24 : cardWidth, alignment: .leading)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: vm.state.waste.count)
    }

    // MARK: - Foundation

    private func foundationView(pile: Int) -> some View {
        ZStack {
            let suitLabels = ["♣", "♦", "♥", "♠"]
            let isHintDest = isHintedFoundationPile(pile)
            
            if let card = vm.state.foundations[pile].last {
                CardView(card: card, isHinted: isHintDest, width: cardWidth)
                    .transition(.scale.combined(with: .opacity))
                    .onTapGesture {
                        vm.tapCard(source: .foundation(pile: pile))
                    }
            } else {
                EmptyPileView(label: suitLabels[pile], width: cardWidth, isHinted: isHintDest)
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
        let isHintDest = isHintedTableauPile(pile)

        return ZStack(alignment: .top) {
            if cards.isEmpty {
                EmptyPileView(width: cardWidth, isHinted: isHintDest)
                    .onTapGesture {
                        vm.tapCard(source: .tableau(pile: pile, cardIndex: 0))
                    }
            }

            ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                let source = MoveSource.tableau(pile: pile, cardIndex: index)
                let isSelected = isSourceSelected(source)
                let isPartOfDrag = isDraggedSubstack(pile: pile, cardIndex: index)
                let isHinted = isHintSource(source)
                // Also highlight top card of destination pile
                let isDestHinted = isHintDest && index == cards.count - 1

                CardView(card: card, isSelected: isSelected, isHinted: isHinted || isDestHinted, width: cardWidth)
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
    }

    // MARK: - Drag & Drop

    private func dragGesture(for source: MoveSource, cards: [Card]) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                if dragSource == nil {
                    dragSource = source
                    dragCards = cards
                    dragStartLocation = value.startLocation
                    HapticManager.shared.cardPickup()
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
                        HapticManager.shared.cardPlace()
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
                    HapticManager.shared.cardPlace()
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
            HapticManager.shared.cardPlace()
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
    
    // MARK: - Hint Helpers
    
    private func isHintSource(_ source: MoveSource) -> Bool {
        vm.hintSource == source
    }
    
    private func isHintDestination(_ destination: MoveDestination) -> Bool {
        vm.hintDestination == destination
    }
    
    private func isHintedTableauPile(_ pile: Int) -> Bool {
        if case .tableau(let hintPile) = vm.hintDestination {
            return hintPile == pile
        }
        return false
    }
    
    private func isHintedFoundationPile(_ pile: Int) -> Bool {
        if case .foundation(let hintPile) = vm.hintDestination {
            return hintPile == pile
        }
        return false
    }

    // MARK: - Settings Sheet

    private var settingsSheet: some View {
        NavigationView {
            List {
                // MARK: Game Mode
                Section("Game Mode") {
                    Toggle(isOn: Binding(
                        get: { vm.state.drawThreeMode },
                        set: { _ in vm.toggleDrawThreeMode() }
                    )) {
                        Label("Draw 3", systemImage: "square.3.layers.3d")
                    }
                    
                    Toggle(isOn: Binding(
                        get: { vm.state.vegasMode },
                        set: { _ in vm.toggleVegasMode() }
                    )) {
                        Label("Vegas Scoring", systemImage: "dollarsign.circle")
                    }
                    
                    if vm.state.vegasMode {
                        HStack {
                            Text("Cumulative Earnings")
                            Spacer()
                            Text(vm.stats.formattedVegasCumulative)
                                .foregroundColor(vm.stats.vegasCumulative >= 0 ? .green : .red)
                                .fontWeight(.semibold)
                        }
                    }
                }
                
                // MARK: Difficulty
                Section("Difficulty") {
                    Picker("Deal Difficulty", selection: Binding(
                        get: { vm.currentDifficulty },
                        set: { vm.setDifficulty($0) }
                    )) {
                        ForEach(DeckDifficulty.allCases, id: \.self) { difficulty in
                            Text(difficulty.rawValue).tag(difficulty)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(vm.currentDifficulty.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // MARK: Audio Settings
                Section("Audio") {
                    Toggle(isOn: Binding(
                        get: { vm.speaker.isMuted },
                        set: { _ in vm.speaker.toggleMute() }
                    )) {
                        Label("Mute Commentary", systemImage: vm.speaker.isMuted ? "speaker.slash" : "speaker.wave.2")
                    }

                    VStack(alignment: .leading) {
                        Text("Speech Rate")
                            .font(.subheadline)
                        Slider(
                            value: Binding(
                                get: { vm.speaker.speechRate },
                                set: { vm.speaker.speechRate = $0 }
                            ),
                            in: 0.3...0.7,
                            step: 0.05
                        )
                        HStack {
                            Text("Slow").font(.caption)
                            Spacer()
                            Text("Fast").font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // MARK: Stats
                Section("Statistics") {
                    statsRow(icon: "gamecontroller.fill", color: .blue, label: "Games Played", value: "\(vm.stats.gamesPlayed)")
                    statsRow(icon: "trophy.fill", color: .yellow, label: "Games Won", value: "\(vm.stats.gamesWon)")
                    statsRow(icon: "percent", color: .green, label: "Win Rate", value: String(format: "%.0f%%", vm.stats.winPercentage))
                    statsRow(icon: "bolt.fill", color: .orange, label: "Best Time", value: vm.stats.formattedBestTime)
                    statsRow(icon: "flame.fill", color: .red, label: "Current Streak", value: "\(vm.stats.currentStreak)")
                    statsRow(icon: "star.fill", color: .purple, label: "Longest Streak", value: "\(vm.stats.longestStreak)")

                    Button(role: .destructive) {
                        vm.stats.resetStats()
                    } label: {
                        Label("Reset Stats", systemImage: "trash")
                    }
                }
                
                // MARK: Achievements
                Section("Achievements") {
                    let unlockedCount = vm.stats.unlockedAchievements.count
                    let totalCount = Achievement.allCases.count
                    
                    Button {
                        showSettings = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showAchievements = true
                        }
                    } label: {
                        HStack {
                            Label("View Achievements", systemImage: "medal")
                            Spacer()
                            Text("\(unlockedCount)/\(totalCount)")
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: Debug (remove before App Store)
                #if DEBUG
                Section("Developer") {
                    Button {
                        showSettings = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showDebugTest = true
                        }
                    } label: {
                        Label("Run Card Count Test", systemImage: "ladybug")
                    }
                    
                    Text("Current card count: \(vm.totalCardCount())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                #endif
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showSettings = false }
                }
            }
        }
    }
    
    // MARK: - Achievements Sheet
    
    private var achievementsSheet: some View {
        NavigationView {
            List {
                ForEach(Achievement.allCases) { achievement in
                    let isUnlocked = vm.stats.isUnlocked(achievement)
                    
                    HStack(spacing: 16) {
                        // Icon
                        Image(systemName: achievement.icon)
                            .font(.system(size: 28))
                            .foregroundColor(isUnlocked ? achievementColor(achievement) : .gray)
                            .frame(width: 40)
                        
                        // Text
                        VStack(alignment: .leading, spacing: 4) {
                            Text(achievement.name)
                                .font(.headline)
                                .foregroundColor(isUnlocked ? .primary : .secondary)
                            Text(achievement.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Unlock indicator
                        if isUnlocked {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        } else {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray.opacity(0.5))
                                .font(.title3)
                        }
                    }
                    .padding(.vertical, 8)
                    .opacity(isUnlocked ? 1.0 : 0.6)
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showAchievements = false }
                }
            }
        }
    }
    
    private func achievementColor(_ achievement: Achievement) -> Color {
        switch achievement.color {
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "purple": return .purple
        case "red": return .red
        case "blue": return .blue
        case "cyan": return .cyan
        case "pink": return .pink
        default: return .gray
        }
    }

    private func statsRow(icon: String, color: Color, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Achievement Toast

struct AchievementToast: View {
    let achievement: Achievement
    
    var body: some View {
        VStack {
            HStack(spacing: 16) {
                Image(systemName: achievement.icon)
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Achievement Unlocked!")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text(achievement.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
                
                Spacer()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.yellow.opacity(0.5), lineWidth: 2)
                    )
            )
            .padding(.horizontal)
            .padding(.top, 50)
            
            Spacer()
        }
    }
}

// MARK: - Win Overlay

struct WinOverlay: View {
    let moveCount: Int
    let time: String
    let vegasScore: Int?
    let onNewGame: () -> Void
    
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var trophyScale: CGFloat = 0.0
    @State private var titleOffset: CGFloat = -200
    @State private var pulseGlow = false
    @State private var showCards = false
    @State private var backgroundOpacity: Double = 0
    @State private var starRotation: Double = 0
    
    private let winMessages = [
        "Well, I'll be... You actually did it! 👏",
        "Against all odds, you've won. I'm genuinely shocked.",
        "Brilliant! Even a broken clock is right twice a day.",
        "You've won! Don't let it go to your head, dear.",
        "Spectacular! I may have underestimated you.",
        "Victory! I'd applaud but my hands are cards.",
    ]
    
    var body: some View {
        ZStack {
            // Full screen animated background
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.0, blue: 0.2),
                    Color(red: 0.0, green: 0.1, blue: 0.3),
                    Color(red: 0.1, green: 0.0, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            .opacity(backgroundOpacity)
            
            // Animated stars/sparkles background
            ForEach(0..<20, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 10...30)))
                    .foregroundColor(.yellow.opacity(Double.random(in: 0.3...0.7)))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .rotationEffect(.degrees(starRotation + Double(i * 18)))
                    .opacity(showContent ? 1 : 0)
            }
            
            // Confetti explosions
            if showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
            }
            
            // Cascading cards in background
            if showCards {
                CascadingCardsView()
                    .ignoresSafeArea()
            }
            
            // Main content
            VStack(spacing: 24) {
                Spacer()
                
                // Trophy with glow
                ZStack {
                    // Glow effect
                    Text("🏆")
                        .font(.system(size: 120))
                        .blur(radius: pulseGlow ? 30 : 20)
                        .opacity(0.6)
                    
                    Text("🏆")
                        .font(.system(size: 120))
                        .shadow(color: .yellow, radius: pulseGlow ? 20 : 10)
                }
                .scaleEffect(trophyScale)
                
                // Animated title
                Text("YOU WIN!")
                    .font(.system(size: 52, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .orange, radius: 15)
                    .shadow(color: .red.opacity(0.5), radius: 25)
                    .offset(y: titleOffset)
                
                // Snarky message
                Text(winMessages.randomElement()!)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .opacity(showContent ? 1 : 0)
                
                Spacer().frame(height: 20)
                
                // Stats with icons
                HStack(spacing: vegasScore != nil ? 30 : 40) {
                    VStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.cyan)
                        Text("\(moveCount)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("MOVES")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    VStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                        Text(time)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("TIME")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // Vegas score
                    if let score = vegasScore {
                        VStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(score >= 0 ? .green : .red)
                            Text(score >= 0 ? "+$\(score)" : "-$\(abs(score))")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(score >= 0 ? .green : .red)
                            Text("PROFIT")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
                .foregroundColor(.white)
                .opacity(showContent ? 1 : 0)
                
                Spacer()
                
                // Play again button
                Button(action: onNewGame) {
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 20, weight: .bold))
                        Text("Play Again")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 48)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: .yellow.opacity(0.6), radius: 15)
                }
                .scaleEffect(showContent ? 1 : 0.5)
                .opacity(showContent ? 1 : 0)
                
                Spacer().frame(height: 60)
            }
        }
        .onAppear {
            // Sequence the animations
            withAnimation(.easeOut(duration: 0.4)) {
                backgroundOpacity = 1
            }
            
            withAnimation(.spring(response: 0.7, dampingFraction: 0.5).delay(0.2)) {
                trophyScale = 1.0
            }
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                titleOffset = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showContent = true
                }
                showConfetti = true
                showCards = true
            }
            
            // Continuous glow animation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseGlow = true
            }
            
            // Star rotation
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                starRotation = 360
            }
        }
    }
}

// Cascading cards background effect
struct CascadingCardsView: View {
    @State private var cards: [CascadeCard] = []
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                
                for card in cards {
                    let age = now - card.createdAt
                    guard age < card.lifetime else { continue }
                    
                    let y = card.startY + (age * card.speed)
                    let x = card.startX + sin(age * 2) * 30
                    let rotation = age * card.rotationSpeed
                    let opacity = min(1.0, age * 2) * (1.0 - (age / card.lifetime) * 0.5)
                    
                    guard y < size.height + 100 else { continue }
                    
                    context.opacity = opacity * 0.4
                    context.translateBy(x: x, y: y)
                    context.rotate(by: .degrees(rotation))
                    
                    // Draw card shape
                    let rect = CGRect(x: -15, y: -21, width: 30, height: 42)
                    let path = Path(roundedRect: rect, cornerRadius: 4)
                    context.fill(path, with: .color(.white))
                    context.stroke(path, with: .color(.gray.opacity(0.5)), lineWidth: 1)
                    
                    // Draw suit symbol
                    let suits = ["♠", "♥", "♦", "♣"]
                    let colors: [Color] = [.black, .red, .red, .black]
                    let idx = card.suitIndex % 4
                    
                    context.rotate(by: .degrees(-rotation))
                    context.translateBy(x: -x, y: -y)
                }
            }
        }
        .onAppear {
            createCards()
        }
    }
    
    private func createCards() {
        let screenWidth = UIScreen.main.bounds.width
        
        for i in 0..<30 {
            cards.append(CascadeCard(
                startX: CGFloat.random(in: 20...(screenWidth - 20)),
                startY: CGFloat.random(in: -200...(-50)),
                speed: CGFloat.random(in: 60...150),
                rotationSpeed: Double.random(in: -100...100),
                lifetime: Double.random(in: 5...8),
                suitIndex: i,
                createdAt: Date().timeIntervalSinceReferenceDate + Double.random(in: 0...2)
            ))
        }
    }
}

struct CascadeCard {
    let startX: CGFloat
    let startY: CGFloat
    let speed: CGFloat
    let rotationSpeed: Double
    let lifetime: Double
    let suitIndex: Int
    let createdAt: TimeInterval
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

// MARK: - Vegas Bankroll View

struct VegasBankrollView: View {
    let amount: Int
    @State private var isAnimating = false
    @State private var shimmerOffset: CGFloat = -200
    
    private var isWinning: Bool { amount > 0 }
    private var isHot: Bool { amount >= 100 }
    private var isOnFire: Bool { amount >= 500 }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon with animation
            ZStack {
                if isOnFire {
                    // Fire effect for big winners
                    Image(systemName: "flame.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                        .opacity(isAnimating ? 0.5 : 1)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                }
                
                Image(systemName: isWinning ? "dollarsign.circle.fill" : "dollarsign.circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isWinning ? .yellow : .gray)
                    .shadow(color: isWinning ? .yellow.opacity(0.5) : .clear, radius: isAnimating ? 8 : 4)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("LIFETIME BANKROLL")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.5)
                    .foregroundColor(.white.opacity(0.5))
                
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(amount >= 0 ? "+$" : "-$")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(isWinning ? .green : .red)
                    
                    Text("\(abs(amount))")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(isWinning ? .green : .red)
                        .shadow(color: isWinning ? .green.opacity(0.3) : .red.opacity(0.3), radius: 4)
                    
                    if isHot {
                        Text(" 🔥")
                            .font(.system(size: 18))
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                    }
                }
            }
            
            Spacer()
            
            // Status badge
            if isOnFire {
                Text("ON FIRE!")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                    )
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
            } else if isHot {
                Text("HOT")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.green))
            } else if amount < -100 {
                Text("COLD")
                    .font(.system(size: 10, weight: .black))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.blue))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            ZStack {
                // Base gradient
                LinearGradient(
                    colors: isWinning 
                        ? [Color.green.opacity(0.2), Color.black.opacity(0.4)]
                        : [Color.red.opacity(0.15), Color.black.opacity(0.4)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                
                // Shimmer effect for winners
                if isWinning {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.clear, .white.opacity(0.1), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .offset(x: shimmerOffset)
                }
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
            if isWinning {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    shimmerOffset = 400
                }
            }
        }
    }
}
