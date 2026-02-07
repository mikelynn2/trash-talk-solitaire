import SwiftUI

struct CommentaryBubble: View {
    let text: String
    let mood: CommentaryMood

    var body: some View {
        HStack(spacing: 8) {
            Text(moodEmoji)
                .font(.title2)

            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(3)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }

    private var moodEmoji: String {
        switch mood {
        case .roast: return "🔥"
        case .praise: return "👏"
        case .neutral: return "😐"
        case .brilliant: return "🤯"
        case .terrible: return "💀"
        }
    }

    private var backgroundColor: Color {
        switch mood {
        case .roast: return Color(red: 0.4, green: 0.1, blue: 0.1)
        case .praise: return Color(red: 0.1, green: 0.3, blue: 0.1)
        case .neutral: return Color(white: 0.2)
        case .brilliant: return Color(red: 0.3, green: 0.2, blue: 0.0)
        case .terrible: return Color(red: 0.3, green: 0.0, blue: 0.0)
        }
    }

    private var borderColor: Color {
        switch mood {
        case .roast: return .red.opacity(0.5)
        case .praise: return .green.opacity(0.5)
        case .neutral: return .gray.opacity(0.3)
        case .brilliant: return .yellow.opacity(0.5)
        case .terrible: return .red.opacity(0.7)
        }
    }
}
