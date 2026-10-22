import Foundation

// MARK: - Grade

enum Grade: String, Codable, CaseIterable, Identifiable {
    case k = "K"
    case first = "1"
    case second = "2"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .k: return "Kindergarten"
        case .first: return "Grade 1"
        case .second: return "Grade 2"
        }
    }

    var short: String {
        switch self {
        case .k: return "K"
        case .first: return "1st"
        case .second: return "2nd"
        }
    }

    /// How many answer choices to show. Fewer for the youngest kids.
    var choiceCount: Int { self == .k ? 3 : 4 }
}

// MARK: - Skill

enum Skill: String, Codable, CaseIterable, Identifiable {
    case counting, compare, addition, subtraction, makeTen, shapes, patterns, skipCounting, tensOnes, time

    var id: String { rawValue }

    var title: String {
        switch self {
        case .counting: return "Counting"
        case .compare: return "More or Less"
        case .addition: return "Adding"
        case .subtraction: return "Taking Away"
        case .makeTen: return "Number Bonds"
        case .shapes: return "Shapes"
        case .patterns: return "Patterns"
        case .skipCounting: return "Skip Counting"
        case .tensOnes: return "Tens & Ones"
        case .time: return "Telling Time"
        }
    }

    var emoji: String {
        switch self {
        case .counting: return "🍎"
        case .compare: return "⚖️"
        case .addition: return "➕"
        case .subtraction: return "➖"
        case .makeTen: return "🔟"
        case .shapes: return "🔺"
        case .patterns: return "🌈"
        case .skipCounting: return "🐸"
        case .tensOnes: return "🧱"
        case .time: return "⏰"
        }
    }

    var colorName: String {
        switch self {
        case .counting: return "red"
        case .compare: return "purple"
        case .addition: return "green"
        case .subtraction: return "orange"
        case .makeTen: return "blue"
        case .shapes: return "pink"
        case .patterns: return "yellow"
        case .skipCounting: return "teal"
        case .tensOnes: return "orange"
        case .time: return "blue"
        }
    }

    /// Which grades see this skill on their map.
    var grades: [Grade] {
        switch self {
        case .counting: return [.k, .first]
        case .patterns: return [.k, .first]
        case .skipCounting, .tensOnes, .time: return [.first, .second]
        default: return Grade.allCases
        }
    }

    static func skills(for grade: Grade) -> [Skill] {
        allCases.filter { $0.grades.contains(grade) }
    }
}

// MARK: - Question

enum ShapeKind: String, CaseIterable, Codable {
    case circle, square, triangle, rectangle, star, heart, hexagon, oval

    var name: String { rawValue }

    /// Number of straight sides, or nil for curvy shapes.
    var sides: Int? {
        switch self {
        case .square, .rectangle: return 4
        case .triangle: return 3
        case .hexagon: return 6
        case .star: return 10
        case .circle, .heart, .oval: return nil
        }
    }
}

enum Choice: Hashable {
    case text(String)
    case group(emoji: String, count: Int)
}

enum QuestionVisual: Equatable {
    case empty
    case equation(String)
    case objects(emoji: String, count: Int)
    case addition(emoji: String, a: Int, b: Int)
    case subtraction(emoji: String, total: Int, takeAway: Int)
    case numberBond(whole: Int, part: Int)
    case shape(ShapeKind)
    case sequence([String])
    case tensOnes(tens: Int, ones: Int)
    case clock(hour: Int, minute: Int)
}

struct Question: Identifiable {
    let id = UUID()
    let skill: Skill
    /// Text shown on screen.
    let prompt: String
    /// Text read aloud (written out for the speech engine).
    let spoken: String
    let visual: QuestionVisual
    let choices: [Choice]
    let correctIndex: Int
    let hint: String
    let explanation: String

    var correctChoice: Choice { choices[correctIndex] }
}

// MARK: - Things to count

struct Thing {
    let emoji: String
    let one: String
    let many: String

    func name(_ n: Int) -> String { n == 1 ? one : many }

    static let all: [Thing] = [
        Thing(emoji: "🍎", one: "apple", many: "apples"),
        Thing(emoji: "🐟", one: "fish", many: "fish"),
        Thing(emoji: "⭐", one: "star", many: "stars"),
        Thing(emoji: "🐞", one: "ladybug", many: "ladybugs"),
        Thing(emoji: "🍓", one: "strawberry", many: "strawberries"),
        Thing(emoji: "🎈", one: "balloon", many: "balloons"),
        Thing(emoji: "🐥", one: "chick", many: "chicks"),
        Thing(emoji: "🍪", one: "cookie", many: "cookies"),
        Thing(emoji: "🌸", one: "flower", many: "flowers"),
        Thing(emoji: "🚗", one: "car", many: "cars"),
        Thing(emoji: "🦋", one: "butterfly", many: "butterflies"),
        Thing(emoji: "🧁", one: "cupcake", many: "cupcakes"),
    ]
}
