import Foundation

@MainActor
final class StatsManager: ObservableObject {
    static let shared = StatsManager()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Key {
        static let gamesPlayed = "stats_gamesPlayed"
        static let gamesWon = "stats_gamesWon"
        static let bestTime = "stats_bestTime"
        static let currentStreak = "stats_currentStreak"
        static let longestStreak = "stats_longestStreak"
    }

    // MARK: - Published Stats

    @Published var gamesPlayed: Int
    @Published var gamesWon: Int
    @Published var bestTime: Int // seconds, 0 = no best time
    @Published var currentStreak: Int
    @Published var longestStreak: Int

    var winPercentage: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed) * 100
    }

    // MARK: - Init

    private init() {
        gamesPlayed = defaults.integer(forKey: Key.gamesPlayed)
        gamesWon = defaults.integer(forKey: Key.gamesWon)
        bestTime = defaults.integer(forKey: Key.bestTime)
        currentStreak = defaults.integer(forKey: Key.currentStreak)
        longestStreak = defaults.integer(forKey: Key.longestStreak)
    }

    // MARK: - Record Game End

    func recordWin(time: Int) {
        gamesPlayed += 1
        gamesWon += 1
        currentStreak += 1

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        if bestTime == 0 || time < bestTime {
            bestTime = time
        }

        save()
    }

    func recordLoss() {
        gamesPlayed += 1
        currentStreak = 0
        save()
    }

    // MARK: - Reset

    func resetStats() {
        gamesPlayed = 0
        gamesWon = 0
        bestTime = 0
        currentStreak = 0
        longestStreak = 0
        save()
    }

    // MARK: - Persistence

    private func save() {
        defaults.set(gamesPlayed, forKey: Key.gamesPlayed)
        defaults.set(gamesWon, forKey: Key.gamesWon)
        defaults.set(bestTime, forKey: Key.bestTime)
        defaults.set(currentStreak, forKey: Key.currentStreak)
        defaults.set(longestStreak, forKey: Key.longestStreak)
    }

    // MARK: - Formatted Best Time

    var formattedBestTime: String {
        guard bestTime > 0 else { return "--:--" }
        let m = bestTime / 60
        let s = bestTime % 60
        return String(format: "%d:%02d", m, s)
    }
}
