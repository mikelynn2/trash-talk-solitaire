import SwiftUI

@main
struct TrashTalkSolitaireApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
                .preferredColorScheme(.dark)
        }
    }
}
