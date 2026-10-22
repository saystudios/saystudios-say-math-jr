import Foundation

/// Builds original, randomized questions for each skill, scaled to the child's grade.
/// Every question has exactly one correct choice and unique choices.
struct QuestionGenerator {
    let grade: Grade

    func lesson(_ skill: Skill, count: Int = 5) -> [Question] {
        var rng = SystemRandomNumberGenerator()
        return lesson(skill, count: count, using: &rng)
    }

    func lesson<R: RandomNumberGenerator>(_ skill: Skill, count: Int = 5, using rng: inout R) -> [Question] {
        var result: [Question] = []
        var seenPrompts = Set<String>()
        var attempts = 0
        while result.count < count && attempts < count * 20 {
            attempts += 1
            let q = make(skill, using: &rng)
            let key = q.spoken + "\(q.visual)" + "\(q.choices)"
            if seenPrompts.contains(key) { continue }
            seenPrompts.insert(key)
            result.append(q)
        }
        return result
    }

    func make<R: RandomNumberGenerator>(_ skill: Skill, using rng: inout R) -> Question {
        switch skill {
        case .counting: return counting(&rng)
        case .compare: return compare(&rng)
        case .addition: return addition(&rng)
        case .subtraction: return subtraction(&rng)
        case .makeTen: return makeTen(&rng)
        case .shapes: return shapes(&rng)
        case .patterns: return patterns(&rng)
        case .skipCounting: return skipCounting(&rng)
        case .tensOnes: return tensOnes(&rng)
        case .time: return time(&rng)
        }
    }

    // MARK: - Choice helpers

    /// Correct number plus nearby distractors, all inside `range`, shuffled.
    static func numberChoices<R: RandomNumberGenerator>(
        correct: Int, range: ClosedRange<Int>, count: Int, spread: Int = 3, using rng: inout R
    ) -> ([Choice], Int) {
        var values: [Int] = [correct]
        var attempts = 0
        while values.count < count && attempts < 200 {
            attempts += 1
            let delta = Int.random(in: -spread...spread, using: &rng)
            let v = correct + delta
            if delta != 0, range.contains(v), !values.contains(v) { values.append(v) }
        }
        var fill = range.lowerBound
        while values.count < count && fill <= range.upperBound {
            if !values.contains(fill) { values.append(fill) }
            fill += 1
        }
        values.shuffle(using: &rng)
        let index = values.firstIndex(of: correct) ?? 0
        return (values.map { .text(String($0)) }, index)
    }

    static func textChoices<R: RandomNumberGenerator>(
        correct: String, pool: [String], count: Int, using rng: inout R
    ) -> ([Choice], Int) {
        var values = [correct]
        for item in pool.shuffled(using: &rng) where values.count < count && !values.contains(item) {
            values.append(item)
        }
        values.shuffle(using: &rng)
        let index = values.firstIndex(of: correct) ?? 0
        return (values.map { .text($0) }, index)
    }

    private var countMax: Int { grade == .k ? 10 : 20 }

    // MARK: - Skills

    private func counting<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        let thing = Thing.all.randomElement(using: &rng)!
        let lower = grade == .k ? 1 : 6
        let n = Int.random(in: lower...countMax, using: &rng)
        let (choices, idx) = Self.numberChoices(
            correct: n, range: 0...(countMax + 3), count: grade.choiceCount, spread: 2, using: &rng)
        return Question(
            skill: .counting,
            prompt: "How many \(thing.many)?",
            spoken: "How many \(thing.many) do you see?",
            visual: .objects(emoji: thing.emoji, count: n),
            choices: choices, correctIndex: idx,
            hint: "Touch each \(thing.one) as you count. Count each one only once!",
            explanation: "There \(n == 1 ? "is" : "are") \(n) \(thing.name(n)).")
    }

    private func compare<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        let wantMore = Bool.random(using: &rng)
        let word = wantMore ? "more" : "fewer"

        if grade == .k {
            let thing = Thing.all.randomElement(using: &rng)!
            let a = Int.random(in: 1...9, using: &rng)
            var b = Int.random(in: 1...9, using: &rng)
            while b == a { b = Int.random(in: 1...9, using: &rng) }
            let choices: [Choice] = [.group(emoji: thing.emoji, count: a), .group(emoji: thing.emoji, count: b)]
            let correctIsA = wantMore ? a > b : a < b
            return Question(
                skill: .compare,
                prompt: "Which group has \(word)?",
                spoken: "Which group has \(word) \(thing.many)?",
                visual: .empty,
                choices: choices, correctIndex: correctIsA ? 0 : 1,
                hint: "Count each group. The \(wantMore ? "bigger" : "smaller") number has \(word).",
                explanation: "\(max(a, b)) is more than \(min(a, b)).")
        }

        let maxN = grade == .first ? 20 : 100
        let a = Int.random(in: 1...maxN, using: &rng)
        var b = Int.random(in: max(1, a - 15)...min(maxN, a + 15), using: &rng)
        while b == a { b = Int.random(in: 1...maxN, using: &rng) }
        let big = wantMore ? "bigger" : "smaller"
        let correct = wantMore ? max(a, b) : min(a, b)
        var values = [a, b].map { String($0) }
        values.shuffle(using: &rng)
        let idx = values.firstIndex(of: String(correct)) ?? 0
        let hint = grade == .second
            ? "Look at the tens first. More tens means a bigger number."
            : "Think of a number line. Numbers get bigger as you count up."
        return Question(
            skill: .compare,
            prompt: "Which number is \(big)?",
            spoken: "Which number is \(big), \(values[0]) or \(values[1])?",
            visual: .empty,
            choices: values.map { .text($0) }, correctIndex: idx,
            hint: hint,
            explanation: "\(max(a, b)) is bigger than \(min(a, b)).")
    }

    private func addition<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        switch grade {
        case .k:
            let thing = Thing.all.randomElement(using: &rng)!
            let a = Int.random(in: 1...5, using: &rng)
            let b = Int.random(in: 0...min(5, 10 - a), using: &rng)
            let (choices, idx) = Self.numberChoices(correct: a + b, range: 0...12, count: grade.choiceCount, spread: 2, using: &rng)
            return Question(
                skill: .addition,
                prompt: "\(a) + \(b) = ?",
                spoken: "\(a) \(thing.name(a)) plus \(b) more. How many in all?",
                visual: .addition(emoji: thing.emoji, a: a, b: b),
                choices: choices, correctIndex: idx,
                hint: "Count all of the \(thing.many) together.",
                explanation: "\(a) + \(b) = \(a + b)")
        case .first:
            let a = Int.random(in: 1...10, using: &rng)
            let b = Int.random(in: 1...min(10, 20 - a), using: &rng)
            let showObjects = a + b <= 10
            let thing = Thing.all.randomElement(using: &rng)!
            let (choices, idx) = Self.numberChoices(correct: a + b, range: 0...22, count: grade.choiceCount, spread: 3, using: &rng)
            return Question(
                skill: .addition,
                prompt: "\(a) + \(b) = ?",
                spoken: "What is \(a) plus \(b)?",
                visual: showObjects ? .addition(emoji: thing.emoji, a: a, b: b) : .equation("\(a) + \(b) = ?"),
                choices: choices, correctIndex: idx,
                hint: "Start at \(max(a, b)) and count up \(min(a, b)) more.",
                explanation: "\(a) + \(b) = \(a + b)")
        case .second:
            let a = Int.random(in: 10...79, using: &rng)
            let b = Int.random(in: 5...min(60, 99 - a), using: &rng)
            let sum = a + b
            let (choices, idx) = Self.tensAwareChoices(correct: sum, count: grade.choiceCount, using: &rng)
            return Question(
                skill: .addition,
                prompt: "\(a) + \(b) = ?",
                spoken: "What is \(a) plus \(b)?",
                visual: .equation("\(a) + \(b) = ?"),
                choices: choices, correctIndex: idx,
                hint: "Add the tens, then add the ones. If the ones make 10 or more, make a new ten!",
                explanation: "\(a) + \(b) = \(sum)")
        }
    }

    private func subtraction<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        switch grade {
        case .k, .first:
            let maxTotal = grade == .k ? 10 : 20
            let total = Int.random(in: 2...maxTotal, using: &rng)
            let take = Int.random(in: 1...min(total, grade == .k ? 5 : 10), using: &rng)
            let showObjects = total <= 10
            let thing = Thing.all.randomElement(using: &rng)!
            let (choices, idx) = Self.numberChoices(correct: total - take, range: 0...maxTotal, count: grade.choiceCount, spread: 2, using: &rng)
            return Question(
                skill: .subtraction,
                prompt: "\(total) − \(take) = ?",
                spoken: showObjects
                    ? "There are \(total) \(thing.name(total)). \(take) go away. How many are left?"
                    : "What is \(total) minus \(take)?",
                visual: showObjects ? .subtraction(emoji: thing.emoji, total: total, takeAway: take) : .equation("\(total) − \(take) = ?"),
                choices: choices, correctIndex: idx,
                hint: showObjects ? "Count the ones that are not crossed out." : "Start at \(take) and count up to \(total).",
                explanation: "\(total) − \(take) = \(total - take)")
        case .second:
            let a = Int.random(in: 30...99, using: &rng)
            let b = Int.random(in: 5...(a - 5), using: &rng)
            let (choices, idx) = Self.tensAwareChoices(correct: a - b, count: grade.choiceCount, using: &rng)
            return Question(
                skill: .subtraction,
                prompt: "\(a) − \(b) = ?",
                spoken: "What is \(a) minus \(b)?",
                visual: .equation("\(a) − \(b) = ?"),
                choices: choices, correctIndex: idx,
                hint: "Subtract the tens, then the ones. If you need more ones, break a ten into 10 ones.",
                explanation: "\(a) − \(b) = \(a - b)")
        }
    }

    /// Distractors that mimic common 2-digit mistakes (off by ten, off by one).
    static func tensAwareChoices<R: RandomNumberGenerator>(correct: Int, count: Int, using rng: inout R) -> ([Choice], Int) {
        var values = [correct]
        let candidates = [correct + 10, correct - 10, correct + 1, correct - 1, correct + 2, correct - 2].shuffled(using: &rng)
        for c in candidates where values.count < count && c >= 0 && !values.contains(c) {
            values.append(c)
        }
        values.shuffle(using: &rng)
        return (values.map { .text(String($0)) }, values.firstIndex(of: correct) ?? 0)
    }

    private func makeTen<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        let whole: Int
        let part: Int
        switch grade {
        case .k:
            whole = Bool.random(using: &rng) ? 5 : 10
            part = Int.random(in: 0...whole, using: &rng)
        case .first:
            whole = Bool.random(using: &rng) ? 10 : Int.random(in: 11...20, using: &rng)
            part = Int.random(in: 1...(whole - 1), using: &rng)
        case .second:
            if Bool.random(using: &rng) {
                whole = 100
                part = Int.random(in: 1...9, using: &rng) * 10
            } else {
                whole = 20
                part = Int.random(in: 1...19, using: &rng)
            }
        }
        let missing = whole - part
        let spread = whole == 100 ? 20 : 3
        let built: ([Choice], Int)
        if whole == 100 {
            let options = [missing, missing + 10, missing - 10, missing + 20].filter { $0 >= 0 }
            built = Self.textChoices(correct: String(missing), pool: options.map { String($0) }, count: grade.choiceCount, using: &rng)
        } else {
            built = Self.numberChoices(correct: missing, range: 0...whole, count: grade.choiceCount, spread: spread, using: &rng)
        }
        let choices = built.0
        let idx = built.1
        return Question(
            skill: .makeTen,
            prompt: "\(part) and ? make \(whole)",
            spoken: "\(part) and what number make \(whole)?",
            visual: .numberBond(whole: whole, part: part),
            choices: choices, correctIndex: idx,
            hint: "Start at \(part) and count up until you reach \(whole).",
            explanation: "\(part) + \(missing) = \(whole)")
    }

    private func shapes<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        let pool: [ShapeKind] = grade == .k
            ? [.circle, .square, .triangle, .rectangle, .star, .heart]
            : ShapeKind.allCases
        let shape = pool.randomElement(using: &rng)!

        // Older kids sometimes get a "how many sides" question.
        if grade != .k, let sides = shape.sides, shape != .star, Bool.random(using: &rng) {
            let (choices, idx) = Self.numberChoices(correct: sides, range: 3...8, count: grade.choiceCount, spread: 2, using: &rng)
            return Question(
                skill: .shapes,
                prompt: "How many sides?",
                spoken: "How many sides does a \(shape.name) have?",
                visual: .shape(shape),
                choices: choices, correctIndex: idx,
                hint: "Trace each straight side with your finger and count.",
                explanation: "A \(shape.name) has \(sides) sides.")
        }

        let (choices, idx) = Self.textChoices(
            correct: shape.name, pool: pool.map(\.name), count: grade.choiceCount, using: &rng)
        return Question(
            skill: .shapes,
            prompt: "What shape is this?",
            spoken: "What shape is this?",
            visual: .shape(shape),
            choices: choices, correctIndex: idx,
            hint: shapeHint(shape),
            explanation: "This is a \(shape.name)!")
    }

    private func shapeHint(_ shape: ShapeKind) -> String {
        switch shape {
        case .circle: return "It is round with no corners."
        case .oval: return "It is round, but stretched like an egg."
        case .square: return "It has 4 sides that are all the same length."
        case .rectangle: return "It has 4 sides. Two are long and two are short."
        case .triangle: return "Count the corners. It has 3."
        case .hexagon: return "Count the sides. It has 6."
        case .star: return "It has 5 pointy tips."
        case .heart: return "It is the shape we use to show love."
        }
    }

    private func patterns<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        let palette = ["🔴", "🔵", "🟡", "🟢", "🟣", "⭐", "🌙", "🍎", "🐟", "🌸"].shuffled(using: &rng)
        let cores: [[Int]] = grade == .k
            ? [[0, 1], [0, 0, 1], [0, 1, 1]]
            : [[0, 1], [0, 0, 1], [0, 1, 1], [0, 1, 2], [0, 0, 1, 1], [0, 1, 2, 2]]
        let core = cores.randomElement(using: &rng)!
        let unit = core.map { palette[$0] }
        let length = core.count * 2 + Int.random(in: 1...core.count, using: &rng)
        let full = (0..<length).map { unit[$0 % unit.count] }
        let answer = full.last!
        let shown = Array(full.dropLast()) + ["?"]
        let pool = Array(Set(unit)) + [palette[5], palette[6]]
        let (choices, idx) = Self.textChoices(correct: answer, pool: pool, count: grade.choiceCount, using: &rng)
        return Question(
            skill: .patterns,
            prompt: "What comes next?",
            spoken: "Look at the pattern. What comes next?",
            visual: .sequence(shown),
            choices: choices, correctIndex: idx,
            hint: "Say the pattern out loud. Find the part that repeats.",
            explanation: "The pattern repeats: \(unit.joined(separator: " ")).")
    }

    private func skipCounting<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        let steps = grade == .first ? [2, 5, 10] : [2, 5, 10, 100]
        let step = steps.randomElement(using: &rng)!
        let limit = step == 100 ? 1000 : (grade == .first ? 50 : 100)
        let maxStart = (limit / step) - 5
        let startIndex = Int.random(in: 0...max(0, maxStart), using: &rng)
        let values = (0..<5).map { (startIndex + $0) * step }
        let hide = Int.random(in: (grade == .first ? 4 : 1)...4, using: &rng)
        let answer = values[hide]
        var shown = values.map { String($0) }
        shown[hide] = "?"
        let options = [answer, answer + step, answer - step, answer + 1, answer + step * 2].filter { $0 >= 0 }
        let (choices, idx) = Self.textChoices(correct: String(answer), pool: options.map { String($0) }, count: grade.choiceCount, using: &rng)
        return Question(
            skill: .skipCounting,
            prompt: "Count by \(step)s. What's missing?",
            spoken: "We are counting by \(step)s. What number is missing?",
            visual: .sequence(shown),
            choices: choices, correctIndex: idx,
            hint: "Each jump adds \(step). Look at the number before the question mark.",
            explanation: "\(shown.joined(separator: ", ").replacingOccurrences(of: "?", with: String(answer)))")
    }

    private func tensOnes<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        let maxTens = grade == .first ? 4 : 9
        let tens = Int.random(in: 1...maxTens, using: &rng)
        let ones = Int.random(in: 0...9, using: &rng)
        let n = tens * 10 + ones

        if grade == .second && Bool.random(using: &rng) {
            // Reverse: how many tens are in a number?
            let (choices, idx) = Self.numberChoices(correct: tens, range: 0...9, count: grade.choiceCount, spread: 2, using: &rng)
            return Question(
                skill: .tensOnes,
                prompt: "How many tens in \(n)?",
                spoken: "How many tens are in \(n)?",
                visual: .equation("\(n)"),
                choices: choices, correctIndex: idx,
                hint: "The first digit tells you the tens.",
                explanation: "\(n) is \(tens) tens and \(ones) ones.")
        }

        // Distractors: swapped digits, off by one ten, off by one.
        var pool = [n + 10, n - 10, n + 1, n - 1]
        if ones > 0 { pool.insert(ones * 10 + tens, at: 0) }
        let (choices, idx) = Self.textChoices(
            correct: String(n), pool: pool.filter { $0 > 0 && $0 != n }.map { String($0) },
            count: grade.choiceCount, using: &rng)
        return Question(
            skill: .tensOnes,
            prompt: "What number is this?",
            spoken: "Each long bar is ten. Each little cube is one. What number is this?",
            visual: .tensOnes(tens: tens, ones: ones),
            choices: choices, correctIndex: idx,
            hint: "Count the bars by tens: 10, 20, 30… then count the cubes by ones.",
            explanation: "\(tens) tens and \(ones) ones make \(n).")
    }

    static func timeString(_ h: Int, _ m: Int) -> String {
        "\(h):" + (m < 10 ? "0\(m)" : "\(m)")
    }

    private func time<R: RandomNumberGenerator>(_ rng: inout R) -> Question {
        let hour = Int.random(in: 1...12, using: &rng)
        let minutes: [Int] = grade == .first ? [0, 30] : [0, 15, 30, 45, 5, 10, 20, 25, 35, 40, 50, 55]
        let minute = minutes.randomElement(using: &rng)!
        let correct = Self.timeString(hour, minute)
        let next = hour == 12 ? 1 : hour + 1
        let prev = hour == 1 ? 12 : hour - 1
        var pool = [
            Self.timeString(next, minute),
            Self.timeString(prev, minute),
            Self.timeString(hour, (minute + 30) % 60),
        ]
        // Mixing up the hands: hour hand read as minutes.
        let swappedHour = minute / 5 == 0 ? 12 : minute / 5
        let swapped = Self.timeString(swappedHour, (hour % 12) * 5)
        if swapped != correct { pool.insert(swapped, at: 0) }
        let (choices, idx) = Self.textChoices(correct: correct, pool: pool.filter { $0 != correct }, count: grade.choiceCount, using: &rng)
        let hint = minute == 0
            ? "The long hand points to 12. That means o'clock. The short hand shows the hour."
            : "The short hand shows the hour. The long hand shows minutes. Count by 5s around the clock."
        return Question(
            skill: .time,
            prompt: "What time is it?",
            spoken: "What time does the clock show?",
            visual: .clock(hour: hour, minute: minute),
            choices: choices, correctIndex: idx,
            hint: hint,
            explanation: "It is \(correct).")
    }
}
