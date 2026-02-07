import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var width: CGFloat = 60
    var height: CGFloat { width * 1.4 }
    
    @State private var flipped: Bool = false
    @State private var showFace: Bool = false

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
        .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
        .onAppear {
            showFace = card.isFaceUp
            flipped = card.isFaceUp
        }
        .onChange(of: card.isFaceUp) { _, newValue in
            if newValue {
                // Flip to face up
                withAnimation(.easeInOut(duration: 0.15)) {
                    flipped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    showFace = true
                    withAnimation(.easeInOut(duration: 0.15)) {
                        // Continue rotation
                    }
                }
            } else {
                // Flip to face down
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
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white)
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.gray.opacity(0.4), lineWidth: 0.5)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: -2) {
                        Text(card.rank.display)
                            .font(.system(size: width * 0.25, weight: .bold, design: .rounded))
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.2))
                    }
                    .foregroundColor(card.color == .red ? .red : .black)
                    Spacer()
                }
                .padding(.leading, 4)
                .padding(.top, 3)

                Spacer()

                Text(card.suit.symbol)
                    .font(.system(size: width * 0.45))
                    .foregroundColor(card.color == .red ? .red : .black)

                Spacer()

                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: -2) {
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.2))
                        Text(card.rank.display)
                            .font(.system(size: width * 0.25, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(card.color == .red ? .red : .black)
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, 4)
                .padding(.bottom, 3)
            }
        }
    }

    private var faceDownCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(red: 0.1, green: 0.3, blue: 0.6))
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)

            // Pattern
            RoundedRectangle(cornerRadius: 4)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.35, blue: 0.65),
                            Color(red: 0.08, green: 0.25, blue: 0.55)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(3)

            // Diamond pattern
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: width * 0.3))
                .foregroundColor(.white.opacity(0.15))
        }
    }
}

struct EmptyPileView: View {
    var label: String = ""
    var width: CGFloat = 60
    var height: CGFloat { width * 1.4 }
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(
                    isHighlighted ? Color.yellow : Color.white.opacity(0.2),
                    style: StrokeStyle(lineWidth: isHighlighted ? 2 : 1, dash: [5])
                )
            if !label.isEmpty {
                Text(label)
                    .font(.system(size: width * 0.25))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .frame(width: width, height: height)
    }
}
