import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var isHinted: Bool = false
    var width: CGFloat = 48
    var height: CGFloat { width * 1.4 }
    
    @State private var flipped: Bool = false
    @State private var showFace: Bool = false
    @State private var hintPulse: Bool = false
    
    private var suitColor: Color {
        card.color == .red ? Color.red : Color.black
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
            RoundedRectangle(cornerRadius: 6)
                .stroke(isSelected ? Color.yellow : Color.clear, lineWidth: 3)
        )
        .overlay(
            // Hint glow overlay
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.green, lineWidth: hintPulse ? 4 : 2)
                .opacity(isHinted ? (hintPulse ? 1.0 : 0.6) : 0)
                .shadow(color: .green.opacity(isHinted ? 0.8 : 0), radius: hintPulse ? 12 : 6)
        )
        .shadow(color: .black.opacity(0.4), radius: 2, x: 1, y: 2)
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
        .onChange(of: isHinted) { _, newValue in
            if newValue {
                // Start pulsing animation
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    hintPulse = true
                }
            } else {
                hintPulse = false
            }
        }
    }

    private var faceUpCard: some View {
        ZStack {
            // Clean white card
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
            
            // Subtle green border like reference
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color(red: 0.3, green: 0.5, blue: 0.35), lineWidth: 1)

            cardContent
        }
    }
    
    private var cardContent: some View {
        GeometryReader { geo in
            // Top left: Rank with small suit to the right
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text(card.rank.display)
                    .font(.system(size: width * 0.5, weight: .bold))
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.25))
            }
            .foregroundColor(suitColor)
            .position(x: width * 0.42, y: height * 0.20)
            
            // Large center suit - sized to fit with room for top text
            Text(card.suit.symbol)
                .font(.system(size: width * 0.75))
                .foregroundColor(suitColor)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.65)
        }
    }

    private var faceDownCard: some View {
        ZStack {
            // Card base - blue
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.2, green: 0.4, blue: 0.8))
            
            // White border
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.white, lineWidth: 2)
            
            // Horizontal stripes pattern like reference
            VStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
        }
    }
}

struct EmptyPileView: View {
    var label: String = ""
    var width: CGFloat = 48
    var height: CGFloat { width * 1.4 }
    var isHighlighted: Bool = false
    var isHinted: Bool = false
    
    @State private var hintPulse: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.06))
            
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isHighlighted ? Color.yellow : (isHinted ? Color.green : Color.white.opacity(0.3)),
                    style: StrokeStyle(lineWidth: isHighlighted || isHinted ? 2.5 : 1.5, dash: (isHighlighted || isHinted) ? [] : [5])
                )
            
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: width * 0.55, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .frame(width: width, height: height)
        .shadow(color: isHinted ? .green.opacity(hintPulse ? 0.8 : 0.4) : .clear, radius: hintPulse ? 12 : 6)
        .onChange(of: isHinted) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    hintPulse = true
                }
            } else {
                hintPulse = false
            }
        }
    }
}
