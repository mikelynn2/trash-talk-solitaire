import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var width: CGFloat = 48
    var height: CGFloat { width * 1.4 }
    
    @State private var flipped: Bool = false
    @State private var showFace: Bool = false
    
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
        VStack(spacing: 0) {
            // Top left: Big rank with tiny suit as superscript
            HStack(alignment: .top, spacing: 1) {
                Text(card.rank.display)
                    .font(.system(size: width * 0.45, weight: .bold))
                Text(card.suit.symbol)
                    .font(.system(size: width * 0.22))
                    .offset(y: 2)
                Spacer()
            }
            .foregroundColor(suitColor)
            .padding(.leading, 5)
            .padding(.top, 4)

            Spacer()

            // HUGE center suit
            Text(card.suit.symbol)
                .font(.system(size: width * 1.0))
                .foregroundColor(suitColor)
                .offset(y: height * 0.05)

            Spacer()
            Spacer()
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

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.06))
            
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isHighlighted ? Color.yellow : Color.white.opacity(0.3),
                    style: StrokeStyle(lineWidth: isHighlighted ? 2.5 : 1.5, dash: isHighlighted ? [] : [5])
                )
            
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: width * 0.55, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .frame(width: width, height: height)
    }
}
