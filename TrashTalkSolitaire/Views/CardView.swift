import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var width: CGFloat = 48
    var height: CGFloat { width * 1.4 }
    
    @State private var flipped: Bool = false
    @State private var showFace: Bool = false
    
    private var isFaceCard: Bool {
        card.rank == .jack || card.rank == .queen || card.rank == .king
    }
    
    // Classic card colors
    private let cardBackground = Color(red: 0.98, green: 0.96, blue: 0.92) // Cream/ivory
    private let cardBorderOuter = Color(red: 0.75, green: 0.72, blue: 0.68)
    private let cardBorderInner = Color(red: 0.85, green: 0.82, blue: 0.78)

    var body: some View {
        ZStack {
            if showFace {
                faceUpCard
                    .rotation3DEffect(.degrees(flipped ? 0 : -90), axis: (x: 0, y: 1, z: 0))
            } else {
                faceDownCard
                    .rotation3DEffect(.degrees(flipped ? 90 : 0), axis: (x: 0, y: 1, z: 0))
            }
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.4), radius: 4, x: 2, y: 3)
        .onAppear {
            showFace = card.isFaceUp
            flipped = card.isFaceUp
        }
        .onChange(of: card.isFaceUp) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.15)) {
                    flipped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showFace = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.15)) {
                    flipped = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showFace = false
                }
            }
        }
    }

    private var faceUpCard: some View {
        ZStack {
            // Card base
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
            
            // Outer border
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(cardBorderOuter, lineWidth: 1)
            
            // Inner cream area with decorative border
            RoundedRectangle(cornerRadius: 4)
                .fill(cardBackground)
                .padding(2)
            
            // Decorative inner frame
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(cardBorderInner, lineWidth: 0.5)
                .padding(4)

            if isFaceCard {
                faceCardContent
            } else {
                numberCardContent
            }
        }
    }
    
    // MARK: - Number Cards (A, 2-10)
    
    private var numberCardContent: some View {
        let suitColor = card.color == .red ? Color(red: 0.8, green: 0.1, blue: 0.1) : Color.black
        
        return VStack(spacing: 0) {
            // Top left corner
            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: 0) {
                    Text(card.rank.display)
                        .font(.system(size: width * 0.28, weight: .bold, design: .serif))
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.22))
                }
                .foregroundColor(suitColor)
                Spacer()
            }
            .padding(.leading, 4)
            .padding(.top, 3)

            Spacer()

            // Center pip pattern
            centerPips(color: suitColor)
                .frame(maxWidth: width * 0.7, maxHeight: height * 0.5)

            Spacer()

            // Bottom right corner (inverted)
            HStack(alignment: .bottom) {
                Spacer()
                VStack(alignment: .center, spacing: 0) {
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.22))
                    Text(card.rank.display)
                        .font(.system(size: width * 0.28, weight: .bold, design: .serif))
                }
                .foregroundColor(suitColor)
                .rotationEffect(.degrees(180))
            }
            .padding(.trailing, 4)
            .padding(.bottom, 3)
        }
    }
    
    // Traditional pip layouts for each card value
    @ViewBuilder
    private func centerPips(color: Color) -> some View {
        let pipSize = width * 0.22
        let symbol = card.suit.symbol
        
        switch card.rank {
        case .ace:
            // Large center ace
            Text(symbol)
                .font(.system(size: width * 0.55))
                .foregroundColor(color)
            
        case .two:
            VStack {
                pip(symbol, size: pipSize, color: color)
                Spacer()
                pip(symbol, size: pipSize, color: color, inverted: true)
            }
            
        case .three:
            VStack {
                pip(symbol, size: pipSize, color: color)
                Spacer()
                pip(symbol, size: pipSize, color: color)
                Spacer()
                pip(symbol, size: pipSize, color: color, inverted: true)
            }
            
        case .four:
            VStack {
                HStack {
                    pip(symbol, size: pipSize, color: color)
                    Spacer()
                    pip(symbol, size: pipSize, color: color)
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize, color: color, inverted: true)
                }
            }
            
        case .five:
            VStack {
                HStack {
                    pip(symbol, size: pipSize, color: color)
                    Spacer()
                    pip(symbol, size: pipSize, color: color)
                }
                Spacer()
                pip(symbol, size: pipSize, color: color)
                Spacer()
                HStack {
                    pip(symbol, size: pipSize, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize, color: color, inverted: true)
                }
            }
            
        case .six:
            VStack {
                HStack {
                    pip(symbol, size: pipSize, color: color)
                    Spacer()
                    pip(symbol, size: pipSize, color: color)
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize, color: color)
                    Spacer()
                    pip(symbol, size: pipSize, color: color)
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize, color: color, inverted: true)
                }
            }
            
        case .seven:
            VStack(spacing: 0) {
                HStack {
                    pip(symbol, size: pipSize * 0.9, color: color)
                    Spacer()
                    pip(symbol, size: pipSize * 0.9, color: color)
                }
                Spacer()
                HStack {
                    Spacer()
                    pip(symbol, size: pipSize * 0.9, color: color)
                    Spacer()
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.9, color: color)
                    Spacer()
                    pip(symbol, size: pipSize * 0.9, color: color)
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.9, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize * 0.9, color: color, inverted: true)
                }
            }
            
        case .eight:
            VStack(spacing: 0) {
                HStack {
                    pip(symbol, size: pipSize * 0.85, color: color)
                    Spacer()
                    pip(symbol, size: pipSize * 0.85, color: color)
                }
                Spacer()
                HStack {
                    Spacer()
                    pip(symbol, size: pipSize * 0.85, color: color)
                    Spacer()
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.85, color: color)
                    Spacer()
                    pip(symbol, size: pipSize * 0.85, color: color)
                }
                Spacer()
                HStack {
                    Spacer()
                    pip(symbol, size: pipSize * 0.85, color: color, inverted: true)
                    Spacer()
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.85, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize * 0.85, color: color, inverted: true)
                }
            }
            
        case .nine:
            VStack(spacing: 0) {
                HStack {
                    pip(symbol, size: pipSize * 0.8, color: color)
                    Spacer()
                    pip(symbol, size: pipSize * 0.8, color: color)
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.8, color: color)
                    Spacer()
                    pip(symbol, size: pipSize * 0.8, color: color)
                }
                Spacer()
                pip(symbol, size: pipSize * 0.8, color: color)
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.8, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize * 0.8, color: color, inverted: true)
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.8, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize * 0.8, color: color, inverted: true)
                }
            }
            
        case .ten:
            VStack(spacing: 0) {
                HStack {
                    pip(symbol, size: pipSize * 0.75, color: color)
                    Spacer()
                    pip(symbol, size: pipSize * 0.75, color: color)
                }
                Spacer()
                HStack {
                    Spacer()
                    pip(symbol, size: pipSize * 0.75, color: color)
                    Spacer()
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.75, color: color)
                    Spacer()
                    pip(symbol, size: pipSize * 0.75, color: color)
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.75, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize * 0.75, color: color, inverted: true)
                }
                Spacer()
                HStack {
                    Spacer()
                    pip(symbol, size: pipSize * 0.75, color: color, inverted: true)
                    Spacer()
                }
                Spacer()
                HStack {
                    pip(symbol, size: pipSize * 0.75, color: color, inverted: true)
                    Spacer()
                    pip(symbol, size: pipSize * 0.75, color: color, inverted: true)
                }
            }
            
        default:
            EmptyView()
        }
    }
    
    private func pip(_ symbol: String, size: CGFloat, color: Color, inverted: Bool = false) -> some View {
        Text(symbol)
            .font(.system(size: size))
            .foregroundColor(color)
            .rotationEffect(.degrees(inverted ? 180 : 0))
    }
    
    // MARK: - Face Cards (J, Q, K)
    
    private var faceCardContent: some View {
        let suitColor = card.color == .red ? Color(red: 0.8, green: 0.1, blue: 0.1) : Color.black
        let goldAccent = Color(red: 0.85, green: 0.65, blue: 0.2)
        
        return ZStack {
            // Decorative background for face cards
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            card.color == .red ? Color.red.opacity(0.06) : Color.blue.opacity(0.04),
                            cardBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .padding(2)
            
            VStack(spacing: 0) {
                // Top left corner
                HStack(alignment: .top) {
                    VStack(alignment: .center, spacing: 0) {
                        Text(card.rank.display)
                            .font(.system(size: width * 0.24, weight: .bold, design: .serif))
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.18))
                    }
                    .foregroundColor(suitColor)
                    Spacer()
                }
                .padding(.leading, 4)
                .padding(.top, 3)

                Spacer()

                // Central figure
                ZStack {
                    // Ornate frame
                    RoundedRectangle(cornerRadius: 3)
                        .strokeBorder(
                            LinearGradient(
                                colors: [goldAccent.opacity(0.6), goldAccent.opacity(0.3)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: width * 0.65, height: height * 0.42)
                    
                    // Inner decorative area
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.5),
                                    card.color == .red ? Color.red.opacity(0.08) : Color.blue.opacity(0.06)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: width * 0.58, height: height * 0.36)
                    
                    faceCardSymbol(color: suitColor, gold: goldAccent)
                }

                Spacer()

                // Bottom right corner (inverted)
                HStack(alignment: .bottom) {
                    Spacer()
                    VStack(alignment: .center, spacing: 0) {
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.18))
                        Text(card.rank.display)
                            .font(.system(size: width * 0.24, weight: .bold, design: .serif))
                    }
                    .foregroundColor(suitColor)
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, 4)
                .padding(.bottom, 3)
            }
        }
    }
    
    @ViewBuilder
    private func faceCardSymbol(color: Color, gold: Color) -> some View {
        VStack(spacing: 1) {
            switch card.rank {
            case .king:
                // Crown for King
                Image(systemName: "crown.fill")
                    .font(.system(size: width * 0.26, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [gold, gold.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                Text("K")
                    .font(.system(size: width * 0.28, weight: .black, design: .serif))
                    .foregroundColor(color)
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.16))
                    .foregroundColor(color)
                    
            case .queen:
                // Tiara/sparkle for Queen
                Image(systemName: "sparkles")
                    .font(.system(size: width * 0.22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [gold, gold.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                Text("Q")
                    .font(.system(size: width * 0.28, weight: .black, design: .serif))
                    .foregroundColor(color)
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.16))
                    .foregroundColor(color)
                    
            case .jack:
                // Shield for Jack
                Image(systemName: "shield.fill")
                    .font(.system(size: width * 0.22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(colors: [gold, gold.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                    )
                Text("J")
                    .font(.system(size: width * 0.28, weight: .black, design: .serif))
                    .foregroundColor(color)
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.16))
                    .foregroundColor(color)
                    
            default:
                EmptyView()
            }
        }
    }

    private var faceDownCard: some View {
        ZStack {
            // Card base
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.12, green: 0.25, blue: 0.55))
            
            // Outer white border
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.white.opacity(0.6), lineWidth: 1.5)
            
            // Inner area with gradient
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.18, green: 0.35, blue: 0.65),
                            Color(red: 0.08, green: 0.18, blue: 0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(3)
            
            // Decorative inner border
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                .padding(5)
            
            // Diamond pattern grid
            GeometryReader { geo in
                let gridSize = min(geo.size.width, geo.size.height) * 0.15
                let cols = Int(geo.size.width / gridSize)
                let rows = Int(geo.size.height / gridSize)
                
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        if (row + col) % 2 == 0 {
                            Image(systemName: "suit.diamond.fill")
                                .font(.system(size: gridSize * 0.6))
                                .foregroundColor(.white.opacity(0.12))
                                .position(
                                    x: CGFloat(col) * gridSize + gridSize / 2 + 8,
                                    y: CGFloat(row) * gridSize + gridSize / 2 + 8
                                )
                        }
                    }
                }
            }
            .padding(8)
            .clipped()
            
            // Center ornament
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: width * 0.4, height: width * 0.4)
                
                Image(systemName: "suit.spade.fill")
                    .font(.system(size: width * 0.22))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
}

struct EmptyPileView: View {
    var label: String = ""
    var width: CGFloat = 48
    var height: CGFloat { width * 1.4 }
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isHighlighted ? Color.yellow : Color.white.opacity(0.25),
                    style: StrokeStyle(lineWidth: isHighlighted ? 2.5 : 1.5, dash: [6])
                )
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: width * 0.35, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(width: width, height: height)
    }
}
