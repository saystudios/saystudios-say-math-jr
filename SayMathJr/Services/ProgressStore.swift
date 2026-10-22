import Foundation
import SwiftUI

struct Profile: Codable, Equatable {
    var name: String
    var grade: Grade
    var avatar: String
}

struct SkillProgress: Codable, Equatable {
    var bestStars: Int = 0
    var lessonsDone: Int = 0
    var firstTryCorrect: Int = 0
    var questionsSeen: Int = 0

    var accuracy: Double {
        questionsSeen == 0 ? 0 : Double(firstTryCorrect) / Double(questionsSeen)
    }
}

struct Settings: Codable, Equatable {
    var readAloud: Bool = true
    var haptics: Bool = true
}

struct AppData: Codable, Equatable {
    var profile: Profile?
    var progress: [String: SkillProgress] = [:]
    var totalStars: Int = 0
    var streak: Int = 0
    var lastPlayDay: String?
    var settings = Settings()
}

/// Saves everything locally on the device. No accounts, no network, no tracking.
@MainActor
final class ProgressStore: ObservableObject {
    @Published private(set) var data: AppData

    static let starsPerSticker = 5
    static let stickers: [String] = [
        "🐶", "🐱", "🐰", "🐼", "🦊", "🐨", "🦁", "🐯", "🐸", "🐵",
        "🦄", "🐳", "🦕", "🐙", "🦉", "🐝", "🌈", "🚀", "🏆", "👑",
    ]
    static let avatars = ["🐶", "🐱", "🐰", "🐼", "🦊", "🐨", "🦄", "🐸"]

    private let key: String
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard, key: String = "saymathjr.data.v1") {
        self.defaults = defaults
        self.key = key
        if let raw = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppData.self, from: raw) {
            data = decoded
        } else {
            data = AppData()
        }
    }

    // MARK: Read

    var profile: Profile? { data.profile }
    var grade: Grade { data.profile?.grade ?? .k }
    var settings: Settings { data.settings }

    func progress(for skill: Skill) -> SkillProgress {
        data.progress[Self.progressKey(grade, skill)] ?? SkillProgress()
    }

    var unlockedStickerCount: Int {
        min(Self.stickers.count, data.totalStars / Self.starsPerSticker)
    }

    var starsToNextSticker: Int {
        Self.starsPerSticker - (data.totalStars % Self.starsPerSticker)
    }

    /// Streak only counts if the child played today or yesterday.
    var currentStreak: Int {
        guard let last = data.lastPlayDay else { return 0 }
        let today = Self.dayString(Date())
        let yesterday = Self.dayString(Date().addingTimeInterval(-86_400))
        return (last == today || last == yesterday) ? data.streak : 0
    }

    // MARK: Write

    func saveProfile(_ profile: Profile) {
        data.profile = profile
        persist()
    }

    func updateSettings(_ change: (inout Settings) -> Void) {
        change(&data.settings)
        persist()
    }

    /// Records a finished lesson and returns how many new stickers it unlocked.
    @discardableResult
    func recordLesson(skill: Skill, stars: Int, firstTryCorrect: Int, questions: Int, now: Date = Date()) -> Int {
        let before = unlockedStickerCount
        let k = Self.progressKey(grade, skill)
        var p = data.progress[k] ?? SkillProgress()
        p.bestStars = max(p.bestStars, stars)
        p.lessonsDone += 1
        p.firstTryCorrect += firstTryCorrect
        p.questionsSeen += questions
        data.progress[k] = p
        data.totalStars += stars

        let today = Self.dayString(now)
        let yesterday = Self.dayString(now.addingTimeInterval(-86_400))
        if data.lastPlayDay == today {
            // already counted today
        } else if data.lastPlayDay == yesterday {
            data.streak += 1
        } else {
            data.streak = 1
        }
        data.lastPlayDay = today
        persist()
        return unlockedStickerCount - before
    }

    func resetProgress() {
        let keptProfile = data.profile
        let keptSettings = data.settings
        data = AppData(profile: keptProfile, settings: keptSettings)
        persist()
    }

    func resetEverything() {
        data = AppData()
        persist()
    }

    // MARK: Helpers

    nonisolated static func stars(mistakes: Int) -> Int {
        switch mistakes {
        case 0: return 3
        case 1...2: return 2
        default: return 1
        }
    }

    nonisolated static func progressKey(_ grade: Grade, _ skill: Skill) -> String {
        "\(grade.rawValue)-\(skill.rawValue)"
    }

    nonisolated static func dayString(_ date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    private func persist() {
        if let raw = try? JSONEncoder().encode(data) {
            defaults.set(raw, forKey: key)
        }
    }
}
