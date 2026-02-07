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
    
    private var suitColor: Color {
        card.color == .red ? Color(red: 0.85, green: 0.15, blue: 0.15) : Color.black
    }

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
            RoundedRectangle(cornerRadius: 5)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
        )
        .shadow(color: .black.opacity(0.35), radius: 3, x: 1, y: 2)
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
            // Clean white card
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white)
            
            // Subtle border
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)

            if isFaceCard {
                faceCardContent
            } else {
                numberCardContent
            }
        }
    }
    
    // MARK: - Number Cards (A, 2-10)
    
    private var numberCardContent: some View {
        VStack(spacing: 0) {
            // Top left corner
            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: -2) {
                    Text(card.rank.display)
                        .font(.system(size: width * 0.32, weight: .bold, design: .rounded))
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.28))
                }
                .foregroundColor(suitColor)
                Spacer()
            }
            .padding(.leading, 4)
            .padding(.top, 3)

            Spacer()

            // Large center suit
            Text(card.suit.symbol)
                .font(.system(size: width * 0.65))
                .foregroundColor(suitColor)

            Spacer()

            // Bottom right corner (inverted)
            HStack(alignment: .bottom) {
                Spacer()
                VStack(alignment: .center, spacing: -2) {
                    Text(card.rank.display)
                        .font(.system(size: width * 0.32, weight: .bold, design: .rounded))
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.28))
                }
                .foregroundColor(suitColor)
                .rotationEffect(.degrees(180))
            }
            .padding(.trailing, 4)
            .padding(.bottom, 3)
        }
    }
    
    // MARK: - Face Cards (J, Q, K)
    
    private var faceCardContent: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top left corner
                HStack(alignment: .top) {
                    VStack(alignment: .center, spacing: -2) {
                        Text(card.rank.display)
                            .font(.system(size: width * 0.28, weight: .bold, design: .rounded))
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.22))
                    }
                    .foregroundColor(suitColor)
                    Spacer()
                }
                .padding(.leading, 4)
                .padding(.top, 3)

                Spacer()

                // Center illustration area
                faceCardIllustration
                    .frame(width: width * 0.75, height: height * 0.55)

                Spacer()

                // Bottom right corner (inverted)
                HStack(alignment: .bottom) {
                    Spacer()
                    VStack(alignment: .center, spacing: -2) {
                        Text(card.rank.display)
                            .font(.system(size: width * 0.28, weight: .bold, design: .rounded))
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.22))
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
    private var faceCardIllustration: some View {
        // Classic-style face card with mirrored top/bottom
        GeometryReader { geo in
            let illustrationColor = card.color == .red ? 
                Color(red: 0.7, green: 0.15, blue: 0.15) : 
                Color(red: 0.15, green: 0.15, blue: 0.4)
            let accentColor = Color(red: 0.85, green: 0.7, blue: 0.3) // Gold
            
            VStack(spacing: 0) {
                // Top half
                ZStack {
                    // Body/robe area
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [illustrationColor, illustrationColor.opacity(0.7)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(spacing: 1) {
                        // Crown/hat
                        switch card.rank {
                        case .king:
                            Image(systemName: "crown.fill")
                                .font(.system(size: geo.size.width * 0.35, weight: .bold))
                                .foregroundColor(accentColor)
                        case .queen:
                            Image(systemName: "crown.fill")
                                .font(.system(size: geo.size.width * 0.3, weight: .bold))
                                .foregroundColor(accentColor)
                        case .jack:
                            // Cap/hat for jack
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: geo.size.width * 0.28, weight: .bold))
                                .foregroundColor(accentColor)
                        default:
                            EmptyView()
                        }
                        
                        // Face
                        Circle()
                            .fill(Color(red: 0.95, green: 0.85, blue: 0.75))
                            .frame(width: geo.size.width * 0.38, height: geo.size.width * 0.38)
                            .overlay(
                                VStack(spacing: 1) {
                                    // Eyes
                                    HStack(spacing: geo.size.width * 0.08) {
                                        Circle().fill(Color.black).frame(width: 3, height: 3)
                                        Circle().fill(Color.black).frame(width: 3, height: 3)
                                    }
                                    // Mouth
                                    Capsule()
                                        .fill(Color(red: 0.8, green: 0.4, blue: 0.4))
                                        .frame(width: 6, height: 2)
                                        .offset(y: 2)
                                }
                            )
                        
                        // Suit symbol on chest
                        Text(card.suit.symbol)
                            .font(.system(size: geo.size.width * 0.25))
                            .foregroundColor(suitColor)
                    }
                    .offset(y: -geo.size.height * 0.02)
                }
                .frame(height: geo.size.height / 2)
                .clipped()
                
                // Dividing line
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 1.5)
                
                // Bottom half (mirrored)
                ZStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [illustrationColor.opacity(0.7), illustrationColor],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    
                    VStack(spacing: 1) {
                        Text(card.suit.symbol)
                            .font(.system(size: geo.size.width * 0.25))
                            .foregroundColor(suitColor)
                        
                        Circle()
                            .fill(Color(red: 0.95, green: 0.85, blue: 0.75))
                            .frame(width: geo.size.width * 0.38, height: geo.size.width * 0.38)
                            .overlay(
                                VStack(spacing: 1) {
                                    HStack(spacing: geo.size.width * 0.08) {
                                        Circle().fill(Color.black).frame(width: 3, height: 3)
                                        Circle().fill(Color.black).frame(width: 3, height: 3)
                                    }
                                    Capsule()
                                        .fill(Color(red: 0.8, green: 0.4, blue: 0.4))
                                        .frame(width: 6, height: 2)
                                        .offset(y: 2)
                                }
                            )
                        
                        switch card.rank {
                        case .king:
                            Image(systemName: "crown.fill")
                                .font(.system(size: geo.size.width * 0.35, weight: .bold))
                                .foregroundColor(accentColor)
                        case .queen:
                            Image(systemName: "crown.fill")
                                .font(.system(size: geo.size.width * 0.3, weight: .bold))
                                .foregroundColor(accentColor)
                        case .jack:
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: geo.size.width * 0.28, weight: .bold))
                                .foregroundColor(accentColor)
                        default:
                            EmptyView()
                        }
                    }
                    .rotationEffect(.degrees(180))
                    .offset(y: geo.size.height * 0.02)
                }
                .frame(height: geo.size.height / 2)
                .clipped()
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .overlay(
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(accentColor.opacity(0.5), lineWidth: 1)
            )
        }
    }

    private var faceDownCard: some View {
        ZStack {
            // Card base - blue
            RoundedRectangle(cornerRadius: 5)
                .fill(Color(red: 0.15, green: 0.25, blue: 0.6))
            
            // White border
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(Color.white, lineWidth: 2)
            
            // Inner pattern area
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(red: 0.12, green: 0.22, blue: 0.55))
                .padding(4)
            
            // Geometric diamond pattern
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 8
                    let size: CGFloat = 6
                    
                    for x in stride(from: spacing, to: geo.size.width - spacing, by: spacing) {
                        for y in stride(from: spacing, to: geo.size.height - spacing, by: spacing) {
                            // Diamond shape
                            path.move(to: CGPoint(x: x, y: y - size/2))
                            path.addLine(to: CGPoint(x: x + size/2, y: y))
                            path.addLine(to: CGPoint(x: x, y: y + size/2))
                            path.addLine(to: CGPoint(x: x - size/2, y: y))
                            path.closeSubpath()
                        }
                    }
                }
                .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
            }
            .padding(6)
            
            // Center design
            ZStack {
                // Outer diamond
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: width * 0.35, height: width * 0.35)
                    .rotationEffect(.degrees(45))
                
                // Inner spade
                Text("♠")
                    .font(.system(size: width * 0.25))
                    .foregroundColor(Color.white.opacity(0.25))
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
            // Subtle filled background
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.white.opacity(0.05))
            
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(
                    isHighlighted ? Color.yellow : Color.white.opacity(0.3),
                    style: StrokeStyle(lineWidth: isHighlighted ? 2.5 : 1.5, dash: isHighlighted ? [] : [6])
                )
            
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: width * 0.4, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .frame(width: width, height: height)
    }
}
