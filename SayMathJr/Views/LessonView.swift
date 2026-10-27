import SwiftUI

struct LessonView: View {
    let skill: Skill

    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [Question] = []
    @State private var index = 0
    @State private var wrongPicks: Set<Int> = []
    @State private var solved = false
    @State private var mistakes = 0
    @State private var firstTryCorrect = 0
    @State private var shake: CGFloat = 0
    @State private var bubble = ""
    @State private var mood: PipMood = .think
    @State private var successCount = 0
    @State private var errorCount = 0
    @State private var result: LessonResult?

    private var current: Question? { questions.indices.contains(index) ? questions[index] : nil }

    var body: some View {
        ZStack {
            SceneBackground(tint: skill.color, showHills: false)  // uses bg_lesson art when present

            if let q = current {
                VStack(spacing: 12) {
                    topBar
                    ScrollView {
                        VStack(spacing: 14) {
                            questionCard(q)
                            MascotBubble(text: bubble.isEmpty ? "Tap the right answer!" : bubble, mood: mood, pipSize: 92)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 30)
                        .padding(.bottom, 110)
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                    }
                }
                .overlay(alignment: .bottom) { nextButton }
            }

            ConfettiBurst(trigger: successCount)

            if let result {
                ResultView(result: result, skill: skill, onAgain: restart, onHome: { dismiss() })
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: successCount) { _, _ in store.settings.haptics }
        .sensoryFeedback(.error, trigger: errorCount) { _, _ in store.settings.haptics }
        .onAppear {
            if questions.isEmpty {
                restart()
                runDemoIfNeeded()
            }
        }
        .onDisappear { Speaker.shared.stop() }
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: 12) {
            RoundIconButton(systemName: "chevron.left", label: "Back") { dismiss() }

            ProgressTrack(
                fraction: questions.isEmpty ? 0 : Double(index + (solved ? 1 : 0)) / Double(questions.count))

            RoundIconButton(systemName: "speaker.wave.2.fill", label: "Read question out loud") {
                if let q = current { Speaker.shared.say(q.spoken) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private func questionCard(_ q: Question) -> some View {
        VStack(spacing: 16) {
            WoodSign(text: q.prompt, size: q.prompt.count > 22 ? 22 : 27)
                .padding(.top, -34)

            if q.visual != .empty {
                QuestionVisualView(visual: q.visual)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(red: 0.99, green: 0.98, blue: 0.95))
                    )
            }

            choicesGrid(q)
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .background(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(.white.opacity(0.96))
                .shadow(color: Theme.ink.opacity(0.12), radius: 14, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(.white, lineWidth: 3)
        )
    }

    private func choicesGrid(_ q: Question) -> some View {
        let isGroup: Bool = {
            if let first = q.choices.first, case .group = first { return true }
            return false
        }()
        let columns = isGroup ? 1 : (q.choices.count == 3 ? 3 : 2)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 8) {
            ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
                let mark = state(for: i, in: q)
                Button { pick(i) } label: {
                    ChoiceLabel(choice: choice, state: mark)
                }
                .buttonStyle(CandyButtonStyle(color: ChoiceLabel.color(for: mark, index: i), radius: 24, depth: 6))
                .opacity(mark == .wrong ? 0.6 : 1)
                .disabled(solved || wrongPicks.contains(i))
                .accessibilityLabel(ChoiceLabel.spoken(choice))
            }
        }
        .modifier(Shake(animatableData: shake))
    }

    private func state(for i: Int, in q: Question) -> ChoiceLabel.Mark {
        if wrongPicks.contains(i) { return .wrong }
        if solved && i == q.correctIndex { return .right }
        return .normal
    }

    @ViewBuilder
    private var nextButton: some View {
        if solved, result == nil {
            Button(action: next) {
                HStack(spacing: 10) {
                    Text(index + 1 < questions.count ? "Next" : "Finish")
                    Image(systemName: index + 1 < questions.count ? "arrow.right" : "star.fill")
                }
                .font(.kid(24, .heavy))
                .foregroundStyle(.white)
                .frame(maxWidth: 520, minHeight: 62)
            }
            .buttonStyle(CandyButtonStyle(color: Theme.green, radius: 31, depth: 7))
            .padding(.horizontal, 18)
            .padding(.bottom, 10)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: Logic

    private func restart() {
        questions = QuestionGenerator(grade: store.grade).lesson(skill)
        index = 0
        mistakes = 0
        firstTryCorrect = 0
        result = nil
        resetQuestionState()
        speakCurrent()
    }

    private func resetQuestionState() {
        wrongPicks = []
        solved = false
        bubble = ""
        mood = .think
    }

    private func speakCurrent() {
        guard store.settings.readAloud, let q = current else { return }
        Speaker.shared.say(q.spoken)
    }

    private func pick(_ i: Int) {
        guard let q = current, !solved, !wrongPicks.contains(i) else { return }
        if i == q.correctIndex {
            if wrongPicks.isEmpty { firstTryCorrect += 1 }
            successCount += 1
            let cheer = Speaker.praise.randomElement() ?? "Great job!"
            withAnimation(.spring) {
                solved = true
                mood = .cheer
                bubble = "\(cheer) \(q.explanation)"
            }
            if store.settings.readAloud { Speaker.shared.say("\(cheer) \(q.explanation)") }
        } else {
            mistakes += 1
            errorCount += 1
            let nudge = Speaker.encourage.randomElement() ?? "Try again!"
            wrongPicks.insert(i)
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
            withAnimation(.spring) {
                mood = .oops
                bubble = "\(nudge) Hint: \(q.hint)"
            }
            if store.settings.readAloud { Speaker.shared.say("\(nudge) \(q.hint)") }
        }
    }

    private func next() {
        if index + 1 < questions.count {
            withAnimation(.easeInOut) {
                index += 1
                resetQuestionState()
            }
            speakCurrent()
        } else {
            let stars = ProgressStore.stars(mistakes: mistakes)
            let newStickers = store.recordLesson(
                skill: skill, stars: stars, firstTryCorrect: firstTryCorrect, questions: questions.count)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                result = LessonResult(stars: stars, firstTryCorrect: firstTryCorrect, total: questions.count, newStickers: newStickers)
            }
            if store.settings.readAloud {
                Speaker.shared.say(stars == 3 ? "Perfect! You earned 3 stars!" : "You earned \(stars) stars! Great work!")
            }
        }
    }

    /// Screenshot mode only: show a correct or wrong answer, or the results card.
    private func runDemoIfNeeded() {
        guard let q = current else { return }
        switch DemoMode.screen {
        case "lessonCorrect":
            pick(q.correctIndex)
        case "lessonWrong":
            pick((q.correctIndex + 1) % q.choices.count)
        case "result":
            result = LessonResult(stars: 3, firstTryCorrect: 5, total: 5, newStickers: 1)
        default:
            break
        }
    }
}

/// Green progress bar with a star at the finish line.
struct ProgressTrack: View {
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.92))
                Capsule()
                    .fill(LinearGradient(colors: [Theme.green.lighter(0.25), Theme.green], startPoint: .top, endPoint: .bottom))
                    .frame(width: max(20, (geo.size.width - 8) * fraction))
                    .padding(4)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: fraction)
            }
        }
        .frame(height: 26)
        .overlay(alignment: .trailing) {
            Image(systemName: "star.fill")
                .font(.system(size: 30, weight: .heavy))
                .foregroundStyle(Theme.yellow)
                .shadow(color: Theme.orange.opacity(0.5), radius: 0, y: 2)
                .offset(x: 8)
        }
        .padding(.trailing, 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int((fraction * 100).rounded())) percent")
    }
}

struct ChoiceLabel: View {
    enum Mark { case normal, right, wrong }
    let choice: Choice
    let state: Mark

    static let palette: [Color] = [Theme.pink, Theme.yellow, Theme.blue, Theme.green]

    static func color(for mark: Mark, index: Int) -> Color {
        switch mark {
        case .normal: return palette[index % palette.count].lighter(0.42)
        case .right: return Theme.green.lighter(0.15)
        case .wrong: return Color(white: 0.86)
        }
    }

    static let numberInk = Color(red: 0.36, green: 0.20, blue: 0.12)

    static func spoken(_ choice: Choice) -> String {
        switch choice {
        case .text(let t): return t
        case .group(_, let n): return "\(n)"
        }
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 74)
            .padding(.vertical, 6)
            .overlay(alignment: .topTrailing) {
                if state != .normal {
                    Image(systemName: state == .right ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(state == .right ? Theme.green : Theme.red)
                        .background(Circle().fill(.white))
                        .offset(x: 6, y: -8)
                        .transition(.scale)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        switch choice {
        case .text(let text):
            Text(text)
                .font(.kid(text.count > 4 ? 26 : 40, .black))
                .foregroundStyle(state == .right ? .white : Self.numberInk)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 8)
        case .group(let emoji, let count):
            ObjectsGrid(emoji: emoji, count: count)
                .padding(10)
        }
    }
}
