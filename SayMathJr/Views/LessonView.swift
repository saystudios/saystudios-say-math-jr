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
            SceneBackground(tint: skill.color, showHills: false)

            if let q = current {
                VStack(spacing: 12) {
                    topBar
                    ScrollView {
                        VStack(spacing: 16) {
                            questionCard(q)
                            choicesGrid(q)
                            MascotBubble(text: bubble.isEmpty ? "Tap the right answer!" : bubble, mood: mood)
                        }
                        .padding(.horizontal, 18)
                        .padding(.top, 4)
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
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 46, height: 46)
            }
            .buttonStyle(CandyButtonStyle(color: .white, radius: 23, depth: 4))
            .accessibilityLabel("Close")

            StarTrack(total: questions.count, done: index + (solved ? 1 : 0), color: skill.color)

            Text(skill.emoji)
                .font(.system(size: 26))
                .frame(width: 46, height: 46)
                .background(Circle().fill(.white))
                .overlay(Circle().stroke(skill.color.lighter(0.3), lineWidth: 3))
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func questionCard(_ q: Question) -> some View {
        VStack(spacing: 18) {
            HStack(alignment: .top) {
                Text(q.prompt)
                    .font(.kid(27, .heavy))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    Speaker.shared.say(q.spoken)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                }
                .buttonStyle(CandyButtonStyle(color: Theme.blue, radius: 25, depth: 4))
                .accessibilityLabel("Read question out loud")
            }
            if q.visual != .empty {
                QuestionVisualView(visual: q.visual)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(skill.color.lighter(0.86))
                    )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(.white)
                .shadow(color: Theme.ink.opacity(0.10), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(skill.color.lighter(0.5), lineWidth: 3)
        )
    }

    private func choicesGrid(_ q: Question) -> some View {
        let isGroup: Bool = {
            if let first = q.choices.first, case .group = first { return true }
            return false
        }()
        let columns = isGroup ? 1 : 2
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: columns), spacing: 10) {
            ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
                let mark = state(for: i, in: q)
                Button { pick(i) } label: {
                    ChoiceLabel(choice: choice, state: mark)
                }
                .buttonStyle(CandyButtonStyle(color: ChoiceLabel.color(for: mark), radius: 24, depth: 7))
                .opacity(mark == .wrong ? 0.55 : 1)
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

/// Row of little stars that fill in as questions are answered.
struct StarTrack: View {
    let total: Int
    let done: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<max(total, 1), id: \.self) { i in
                Image(systemName: i < done ? "star.fill" : "star")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(i < done ? Theme.yellow : Theme.ink.opacity(0.2))
                    .scaleEffect(i == done - 1 ? 1.2 : 1)
                    .animation(.spring(response: 0.3, dampingFraction: 0.5), value: done)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Capsule().fill(.white.opacity(0.9)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Question \(min(done + 1, total)) of \(total)")
    }
}

struct ChoiceLabel: View {
    enum Mark { case normal, right, wrong }
    let choice: Choice
    let state: Mark

    static func color(for mark: Mark) -> Color {
        switch mark {
        case .normal: return .white
        case .right: return Theme.green.lighter(0.55)
        case .wrong: return Theme.red.lighter(0.7)
        }
    }

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
                .font(.kid(text.count > 4 ? 26 : 36, .heavy))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 8)
        case .group(let emoji, let count):
            ObjectsGrid(emoji: emoji, count: count)
                .padding(10)
        }
    }
}
