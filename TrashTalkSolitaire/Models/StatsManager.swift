import Foundation

// MARK: - Achievement Definition

enum Achievement: String, CaseIterable, Identifiable {
    case speedDemon = "speed_demon"           // Win under 2 min
    case lightningRound = "lightning_round"   // Win under 60 sec
    case perfectionist = "perfectionist"      // Win without undo
    case noHintsNeeded = "no_hints_needed"    // Win without hints
    case streakMaster = "streak_master"       // 5 game streak
    case unstoppable = "unstoppable"          // 10 game streak
    case centuryClub = "century_club"         // 100 games played
    case cardShark = "card_shark"             // 50 wins
    case highRoller = "high_roller"           // +$1000 Vegas cumulative
    case butlersChoice = "butlers_choice"    // 10 wins in one day
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .speedDemon: return "Speed Demon"
        case .lightningRound: return "Lightning Round"
        case .perfectionist: return "Perfectionist"
        case .noHintsNeeded: return "No Hints Needed"
        case .streakMaster: return "Streak Master"
        case .unstoppable: return "Unstoppable"
        case .centuryClub: return "Century Club"
        case .cardShark: return "Card Shark"
        case .highRoller: return "High Roller"
        case .butlersChoice: return "Butler's Choice"
        }
    }
    
    var description: String {
        switch self {
        case .speedDemon: return "Win in under 2 minutes"
        case .lightningRound: return "Win in under 60 seconds"
        case .perfectionist: return "Win without using undo"
        case .noHintsNeeded: return "Win without using hints"
        case .streakMaster: return "Win 5 games in a row"
        case .unstoppable: return "Win 10 games in a row"
        case .centuryClub: return "Play 100 games"
        case .cardShark: return "Win 50 games"
        case .highRoller: return "Earn $1,000 in Vegas mode"
        case .butlersChoice: return "Win 10 games in one day"
        }
    }
    
    var icon: String {
        switch self {
        case .speedDemon: return "hare.fill"
        case .lightningRound: return "bolt.fill"
        case .perfectionist: return "checkmark.seal.fill"
        case .noHintsNeeded: return "brain.head.profile"
        case .streakMaster: return "flame.fill"
        case .unstoppable: return "crown.fill"
        case .centuryClub: return "100.circle.fill"
        case .cardShark: return "fish.fill"
        case .highRoller: return "dollarsign.circle.fill"
        case .butlersChoice: return "star.fill"
        }
    }
    
    var color: String {
        switch self {
        case .speedDemon: return "orange"
        case .lightningRound: return "yellow"
        case .perfectionist: return "green"
        case .noHintsNeeded: return "purple"
        case .streakMaster: return "red"
        case .unstoppable: return "yellow"
        case .centuryClub: return "blue"
        case .cardShark: return "cyan"
        case .highRoller: return "green"
        case .butlersChoice: return "gold"
        }
    }
}

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
        static let vegasCumulative = "stats_vegasCumulative"
        static let unlockedAchievements = "stats_achievements"
        static let winsToday = "stats_winsToday"
        static let lastWinDate = "stats_lastWinDate"
    }

    // MARK: - Published Stats

    @Published var gamesPlayed: Int
    @Published var gamesWon: Int
    @Published var bestTime: Int // seconds, 0 = no best time
    @Published var currentStreak: Int
    @Published var longestStreak: Int
    @Published var vegasCumulative: Int  // Total Vegas earnings
    @Published var unlockedAchievements: Set<String>
    @Published var newlyUnlockedAchievement: Achievement?  // For showing unlock animation
    
    private var winsToday: Int
    private var lastWinDate: String

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
        vegasCumulative = defaults.integer(forKey: Key.vegasCumulative)
        winsToday = defaults.integer(forKey: Key.winsToday)
        lastWinDate = defaults.string(forKey: Key.lastWinDate) ?? ""
        
        let achievementStrings = defaults.stringArray(forKey: Key.unlockedAchievements) ?? []
        unlockedAchievements = Set(achievementStrings)
    }

    // MARK: - Record Game End

    func recordWin(time: Int, undoCount: Int = 0, hintCount: Int = 0, vegasScore: Int = 0) {
        gamesPlayed += 1
        gamesWon += 1
        currentStreak += 1

        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        if bestTime == 0 || time < bestTime {
            bestTime = time
        }
        
        // Vegas cumulative
        if vegasScore != 0 {
            vegasCumulative += vegasScore
        }
        
        // Track daily wins
        let today = todayString()
        if lastWinDate == today {
            winsToday += 1
        } else {
            winsToday = 1
            lastWinDate = today
        }

        save()
        
        // Check achievements
        checkAchievements(time: time, undoCount: undoCount, hintCount: hintCount)
    }

    func recordLoss() {
        gamesPlayed += 1
        currentStreak = 0
        save()
        
        // Check games played achievements
        if gamesPlayed >= 100 && !unlockedAchievements.contains(Achievement.centuryClub.rawValue) {
            unlock(.centuryClub)
        }
    }
    
    // MARK: - Achievements
    
    private func checkAchievements(time: Int, undoCount: Int, hintCount: Int) {
        // Speed achievements
        if time < 60 {
            unlock(.lightningRound)
        }
        if time < 120 {
            unlock(.speedDemon)
        }
        
        // Perfect game achievements
        if undoCount == 0 {
            unlock(.perfectionist)
        }
        if hintCount == 0 {
            unlock(.noHintsNeeded)
        }
        
        // Streak achievements
        if currentStreak >= 5 {
            unlock(.streakMaster)
        }
        if currentStreak >= 10 {
            unlock(.unstoppable)
        }
        
        // Volume achievements
        if gamesPlayed >= 100 {
            unlock(.centuryClub)
        }
        if gamesWon >= 50 {
            unlock(.cardShark)
        }
        
        // Vegas achievement
        if vegasCumulative >= 1000 {
            unlock(.highRoller)
        }
        
        // Daily wins
        if winsToday >= 10 {
            unlock(.butlersChoice)
        }
    }
    
    private func unlock(_ achievement: Achievement) {
        guard !unlockedAchievements.contains(achievement.rawValue) else { return }
        unlockedAchievements.insert(achievement.rawValue)
        newlyUnlockedAchievement = achievement
        save()
        
        // Clear the newly unlocked after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [weak self] in
            self?.newlyUnlockedAchievement = nil
        }
    }
    
    func isUnlocked(_ achievement: Achievement) -> Bool {
        unlockedAchievements.contains(achievement.rawValue)
    }
    
    private func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // MARK: - Reset

    func resetStats() {
        gamesPlayed = 0
        gamesWon = 0
        bestTime = 0
        currentStreak = 0
        longestStreak = 0
        vegasCumulative = 0
        winsToday = 0
        lastWinDate = ""
        unlockedAchievements.removeAll()
        save()
    }

    // MARK: - Persistence

    private func save() {
        defaults.set(gamesPlayed, forKey: Key.gamesPlayed)
        defaults.set(gamesWon, forKey: Key.gamesWon)
        defaults.set(bestTime, forKey: Key.bestTime)
        defaults.set(currentStreak, forKey: Key.currentStreak)
        defaults.set(longestStreak, forKey: Key.longestStreak)
        defaults.set(vegasCumulative, forKey: Key.vegasCumulative)
        defaults.set(winsToday, forKey: Key.winsToday)
        defaults.set(lastWinDate, forKey: Key.lastWinDate)
        defaults.set(Array(unlockedAchievements), forKey: Key.unlockedAchievements)
    }

    // MARK: - Formatted Values

    var formattedBestTime: String {
        guard bestTime > 0 else { return "--:--" }
        let m = bestTime / 60
        let s = bestTime % 60
        return String(format: "%d:%02d", m, s)
    }
    
    var formattedVegasCumulative: String {
        if vegasCumulative >= 0 {
            return "+$\(vegasCumulative)"
        } else {
            return "-$\(abs(vegasCumulative))"
        }
    }
}
