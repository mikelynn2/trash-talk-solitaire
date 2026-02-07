import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var width: CGFloat = 48
    var height: CGFloat { width * 1.28 }
    
    @State private var flipped: Bool = false
    @State private var showFace: Bool = false
    
    private var isFaceCard: Bool {
        card.rank == .jack || card.rank == .queen || card.rank == .king
    }
    
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
            RoundedRectangle(cornerRadius: 4)
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
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
            
            // Subtle border
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.gray.opacity(0.4), lineWidth: 0.5)

            cardContent
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // Top left corner - BIG AND BOLD
            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: -4) {
                    Text(card.rank.display)
                        .font(.system(size: width * 0.45, weight: .bold))
                        .minimumScaleFactor(0.5)
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.35))
                }
                .foregroundColor(suitColor)
                Spacer()
            }
            .padding(.leading, 3)
            .padding(.top, 2)

            Spacer()

            // Large center suit
            Text(card.suit.symbol)
                .font(.system(size: width * 0.7))
                .foregroundColor(suitColor)

            Spacer()

            // Bottom right corner (inverted)
            HStack(alignment: .bottom) {
                Spacer()
                VStack(alignment: .center, spacing: -4) {
                    Text(card.rank.display)
                        .font(.system(size: width * 0.45, weight: .bold))
                        .minimumScaleFactor(0.5)
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.35))
                }
                .foregroundColor(suitColor)
                .rotationEffect(.degrees(180))
            }
            .padding(.trailing, 3)
            .padding(.bottom, 2)
        }
    }

    private var faceDownCard: some View {
        ZStack {
            // Card base - blue
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0.1, green: 0.3, blue: 0.7))
            
            // White border
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white, lineWidth: 2)
            
            // Inner pattern area
            RoundedRectangle(cornerRadius: 2)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                .padding(5)
            
            // Simple pattern
            VStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { row in
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { col in
                            Image(systemName: "suit.diamond.fill")
                                .font(.system(size: width * 0.12))
                                .foregroundColor(.white.opacity(0.2))
                        }
                    }
                }
            }
        }
    }
}

struct EmptyPileView: View {
    var label: String = ""
    var width: CGFloat = 48
    var height: CGFloat { width * 1.28 }
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            // Subtle filled background
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white.opacity(0.08))
            
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(
                    isHighlighted ? Color.yellow : Color.white.opacity(0.35),
                    style: StrokeStyle(lineWidth: isHighlighted ? 2.5 : 1.5, dash: isHighlighted ? [] : [5])
                )
            
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: width * 0.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(width: width, height: height)
    }
}
