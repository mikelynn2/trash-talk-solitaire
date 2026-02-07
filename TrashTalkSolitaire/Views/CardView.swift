import SwiftUI

struct CardView: View {
    let card: Card
    var isSelected: Bool = false
    var width: CGFloat = 52
    var height: CGFloat { width * 1.28 }
    
    @State private var flipped: Bool = false
    @State private var showFace: Bool = false
    
    private var isFaceCard: Bool {
        card.rank == .jack || card.rank == .queen || card.rank == .king
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
            RoundedRectangle(cornerRadius: 8)
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
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)

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
            HStack {
                VStack(alignment: .center, spacing: -1) {
                    Text(card.rank.display)
                        .font(.system(size: width * 0.32, weight: .heavy, design: .rounded))
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.26, weight: .bold))
                }
                .foregroundColor(card.color == .red ? .red : .black)
                Spacer()
            }
            .padding(.leading, 5)
            .padding(.top, 4)

            Spacer()

            // Center suit
            Text(card.suit.symbol)
                .font(.system(size: width * 0.55, weight: .bold))
                .foregroundColor(card.color == .red ? .red : .black)

            Spacer()

            // Bottom right corner (inverted)
            HStack {
                Spacer()
                VStack(alignment: .center, spacing: -1) {
                    Text(card.suit.symbol)
                        .font(.system(size: width * 0.26, weight: .bold))
                    Text(card.rank.display)
                        .font(.system(size: width * 0.32, weight: .heavy, design: .rounded))
                }
                .foregroundColor(card.color == .red ? .red : .black)
                .rotationEffect(.degrees(180))
            }
            .padding(.trailing, 5)
            .padding(.bottom, 4)
        }
    }
    
    // MARK: - Face Cards (J, Q, K)
    
    private var faceCardContent: some View {
        ZStack {
            // Background tint for face cards
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            card.color == .red ? Color.red.opacity(0.08) : Color.black.opacity(0.05),
                            Color.white
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            
            VStack(spacing: 0) {
                // Top left corner
                HStack {
                    VStack(alignment: .center, spacing: -1) {
                        Text(card.rank.display)
                            .font(.system(size: width * 0.30, weight: .heavy, design: .rounded))
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.22, weight: .bold))
                    }
                    .foregroundColor(card.color == .red ? .red : .black)
                    Spacer()
                }
                .padding(.leading, 4)
                .padding(.top, 3)

                Spacer()

                // Face card image
                faceCardImage
                    .frame(width: width * 0.65, height: width * 0.55)

                Spacer()

                // Bottom right corner (inverted)
                HStack {
                    Spacer()
                    VStack(alignment: .center, spacing: -1) {
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.22, weight: .bold))
                        Text(card.rank.display)
                            .font(.system(size: width * 0.30, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(card.color == .red ? .red : .black)
                    .rotationEffect(.degrees(180))
                }
                .padding(.trailing, 4)
                .padding(.bottom, 3)
            }
        }
    }
    
    @ViewBuilder
    private var faceCardImage: some View {
        let color = card.color == .red ? Color.red : Color.black
        
        ZStack {
            // Decorative frame
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
            
            VStack(spacing: 2) {
                // Crown/symbol for the face
                switch card.rank {
                case .king:
                    Image(systemName: "crown.fill")
                        .font(.system(size: width * 0.28, weight: .bold))
                        .foregroundColor(color)
                    Text("K")
                        .font(.system(size: width * 0.22, weight: .black, design: .serif))
                        .foregroundColor(color)
                case .queen:
                    Image(systemName: "sparkle")
                        .font(.system(size: width * 0.26, weight: .bold))
                        .foregroundColor(color)
                    Text("Q")
                        .font(.system(size: width * 0.22, weight: .black, design: .serif))
                        .foregroundColor(color)
                case .jack:
                    Image(systemName: "shield.fill")
                        .font(.system(size: width * 0.26, weight: .bold))
                        .foregroundColor(color)
                    Text("J")
                        .font(.system(size: width * 0.22, weight: .black, design: .serif))
                        .foregroundColor(color)
                default:
                    EmptyView()
                }
            }
        }
    }

    private var faceDownCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.1, green: 0.3, blue: 0.6))
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)

            // Pattern
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.15, green: 0.38, blue: 0.68),
                            Color(red: 0.08, green: 0.22, blue: 0.52)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .padding(4)

            // Diamond pattern
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: width * 0.35))
                .foregroundColor(.white.opacity(0.18))
        }
    }
}

struct EmptyPileView: View {
    var label: String = ""
    var width: CGFloat = 52
    var height: CGFloat { width * 1.28 }
    var isHighlighted: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
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
