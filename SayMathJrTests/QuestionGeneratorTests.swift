import XCTest
@testable import SayMathJr

/// Deterministic RNG so test runs are repeatable.
struct SeededRNG: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed &+ 0x9E37_79B9_7F4A_7C15 }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

final class QuestionGeneratorTests: XCTestCase {

    /// Generates thousands of questions for every grade and skill and checks the basics.
    func testEveryQuestionIsWellFormed() {
        var rng = SeededRNG(seed: 42)
        for grade in Grade.allCases {
            let gen = QuestionGenerator(grade: grade)
            for skill in Skill.skills(for: grade) {
                for _ in 0..<400 {
                    let q = gen.make(skill, using: &rng)
                    let label = "\(grade.rawValue)/\(skill.rawValue): \(q.prompt)"
                    XCTAssertGreaterThanOrEqual(q.choices.count, 2, label)
                    XCTAssertTrue(q.choices.indices.contains(q.correctIndex), label)
                    XCTAssertEqual(Set(q.choices).count, q.choices.count, "duplicate choices in \(label)")
                    XCTAssertFalse(q.prompt.isEmpty, label)
                    XCTAssertFalse(q.hint.isEmpty, label)
                    for case .text(let t) in q.choices {
                        if let n = Int(t) { XCTAssertGreaterThanOrEqual(n, 0, "negative choice in \(label)") }
                    }
                }
            }
        }
    }

    func testArithmeticAnswersAreCorrect() {
        var rng = SeededRNG(seed: 7)
        for grade in Grade.allCases {
            let gen = QuestionGenerator(grade: grade)
            for _ in 0..<500 {
                for skill in [Skill.addition, .subtraction] {
                    let q = gen.make(skill, using: &rng)
                    let parts = q.prompt.replacingOccurrences(of: " = ?", with: "")
                        .components(separatedBy: skill == .addition ? " + " : " − ")
                        .compactMap { Int($0) }
                    XCTAssertEqual(parts.count, 2, q.prompt)
                    guard parts.count == 2, case .text(let ans) = q.correctChoice else { continue }
                    let expected = skill == .addition ? parts[0] + parts[1] : parts[0] - parts[1]
                    XCTAssertEqual(Int(ans), expected, q.prompt)
                    XCTAssertGreaterThanOrEqual(expected, 0, q.prompt)
                }
            }
        }
    }

    func testCountingMatchesObjects() {
        var rng = SeededRNG(seed: 99)
        let gen = QuestionGenerator(grade: .k)
        for _ in 0..<300 {
            let q = gen.make(.counting, using: &rng)
            guard case .objects(_, let count) = q.visual, case .text(let ans) = q.correctChoice else {
                return XCTFail("unexpected counting question shape")
            }
            XCTAssertEqual(Int(ans), count)
            XCTAssertLessThanOrEqual(count, 10)
        }
    }

    func testNumberBondsAddUp() {
        var rng = SeededRNG(seed: 5)
        for grade in Grade.allCases {
            let gen = QuestionGenerator(grade: grade)
            for _ in 0..<300 {
                let q = gen.make(.makeTen, using: &rng)
                guard case .numberBond(let whole, let part) = q.visual, case .text(let ans) = q.correctChoice else {
                    return XCTFail("unexpected bond question shape")
                }
                XCTAssertEqual(part + (Int(ans) ?? -999), whole)
            }
        }
    }

    func testCompareGroupsAnswer() {
        var rng = SeededRNG(seed: 11)
        let gen = QuestionGenerator(grade: .k)
        for _ in 0..<300 {
            let q = gen.make(.compare, using: &rng)
            let counts = q.choices.compactMap { c -> Int? in
                if case .group(_, let n) = c { return n }
                return nil
            }
            XCTAssertEqual(counts.count, 2)
            let wantMore = q.prompt.contains("more")
            let chosen = counts[q.correctIndex]
            XCTAssertEqual(chosen, wantMore ? counts.max() : counts.min(), q.prompt)
        }
    }

    func testClockAnswerMatchesFace() {
        var rng = SeededRNG(seed: 3)
        for grade in [Grade.first, .second] {
            let gen = QuestionGenerator(grade: grade)
            for _ in 0..<300 {
                let q = gen.make(.time, using: &rng)
                guard case .clock(let h, let m) = q.visual, case .text(let ans) = q.correctChoice else {
                    return XCTFail("unexpected time question shape")
                }
                XCTAssertEqual(ans, QuestionGenerator.timeString(h, m))
                if grade == .first { XCTAssertTrue(m == 0 || m == 30) }
            }
        }
    }

    func testLessonHasFiveUniqueQuestions() {
        for grade in Grade.allCases {
            for skill in Skill.skills(for: grade) {
                let lesson = QuestionGenerator(grade: grade).lesson(skill)
                XCTAssertEqual(lesson.count, 5, "\(grade.rawValue)/\(skill.rawValue)")
            }
        }
    }

    func testStarRules() {
        XCTAssertEqual(ProgressStore.stars(mistakes: 0), 3)
        XCTAssertEqual(ProgressStore.stars(mistakes: 2), 2)
        XCTAssertEqual(ProgressStore.stars(mistakes: 5), 1)
    }

    @MainActor
    func testProgressAndStreak() {
        let defaults = UserDefaults(suiteName: "SayMathJrTests-\(UUID().uuidString)")!
        let store = ProgressStore(defaults: defaults, key: "test")
        store.saveProfile(Profile(name: "Test", grade: .first, avatar: "🐶"))
        let day1 = Date(timeIntervalSince1970: 1_800_000_000)
        store.recordLesson(skill: .addition, stars: 3, firstTryCorrect: 5, questions: 5, now: day1)
        store.recordLesson(skill: .addition, stars: 2, firstTryCorrect: 3, questions: 5, now: day1.addingTimeInterval(86_400))
        XCTAssertEqual(store.data.totalStars, 5)
        XCTAssertEqual(store.data.streak, 2)
        XCTAssertEqual(store.progress(for: .addition).bestStars, 3)
        XCTAssertEqual(store.unlockedStickerCount, 1)

        // Reload from disk
        let reloaded = ProgressStore(defaults: defaults, key: "test")
        XCTAssertEqual(reloaded.data, store.data)
    }
}
