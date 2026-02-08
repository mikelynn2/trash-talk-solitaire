import SwiftUI

@main
struct TrashTalkSolitaireApp: App {
    @State private var showSplash = true
    
    init() {
        // Register default settings (Vegas mode ON by default)
        UserDefaults.standard.register(defaults: [
            "vegasMode": true,
            "drawThreeMode": false,
            "deckDifficulty": "Medium"
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                GameView()
                    .preferredColorScheme(.dark)
                
                if showSplash {
                    SplashScreen()
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
    }
}

struct SplashScreen: View {
    @State private var heartScale: CGFloat = 0.5
    @State private var textOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.05, blue: 0.1), Color(red: 0.05, green: 0.1, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                Text("❤️")
                    .font(.system(size: 60))
                    .scaleEffect(heartScale)
                
                Text("Mike loves Angie")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                heartScale = 1.0
            }
            withAnimation(.easeIn(duration: 0.4).delay(0.2)) {
                textOpacity = 1.0
            }
        }
    }
}
