import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var width: CGFloat = 48
    var height: CGFloat { width * 1.12 }  // Much wider, almost square
    
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
            // Clean white card with rounded corners
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
            
            // Subtle border
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 0.5)

            cardContent
        }
    }
    
    private var cardContent: some View {
        VStack(spacing: 0) {
            // Top left corner - HUGE rank, smaller suit below
            HStack(alignment: .top) {
                VStack(alignment: .center, spacing: -2) {
                    Text(card.rank.display)
                        .font(.system(size: width * 0.48, weight: .semibold))
                        .minimumScaleFactor(0.5)
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.32))
                }
                .foregroundColor(suitColor)
                Spacer()
            }
            .padding(.leading, 4)
            .padding(.top, 2)

            Spacer()

            // Large center suit
            Text(card.suit.symbol)
                .font(.system(size: width * 0.85))
                .foregroundColor(suitColor)

            Spacer()

            // Bottom right corner (inverted)
            HStack(alignment: .bottom) {
                Spacer()
                VStack(alignment: .center, spacing: -2) {
                    Text(card.rank.display)
                        .font(.system(size: width * 0.48, weight: .semibold))
                        .minimumScaleFactor(0.5)
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.32))
                }
                .foregroundColor(suitColor)
                .rotationEffect(.degrees(180))
            }
            .padding(.trailing, 4)
            .padding(.bottom, 2)
        }
    }

    private var faceDownCard: some View {
        ZStack {
            // Card base - blue
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.15, green: 0.35, blue: 0.75))
            
            // White border
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.white, lineWidth: 2)
            
            // Inner border
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
                .padding(4)
            
            // Diamond pattern
            GeometryReader { geo in
                let rows = 5
                let cols = 4
                let spacingX = geo.size.width / CGFloat(cols + 1)
                let spacingY = geo.size.height / CGFloat(rows + 1)
                
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        Image(systemName: "suit.diamond.fill")
                            .font(.system(size: width * 0.14))
                            .foregroundColor(.white.opacity(0.25))
                            .position(
                                x: spacingX * CGFloat(col + 1),
                                y: spacingY * CGFloat(row + 1)
                            )
                    }
                }
            }
        }
    }
}

struct EmptyPileView: View {
    var label: String = ""
    var width: CGFloat = 48
    var height: CGFloat { width * 1.12 }
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.08))
            
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isHighlighted ? Color.yellow : Color.white.opacity(0.35),
                    style: StrokeStyle(lineWidth: isHighlighted ? 2.5 : 1.5, dash: isHighlighted ? [] : [5])
                )
            
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: width * 0.55, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(width: width, height: height)
    }
}
