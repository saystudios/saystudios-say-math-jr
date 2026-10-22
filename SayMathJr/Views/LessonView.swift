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
    @State private var successCount = 0
    @State private var errorCount = 0
    @State private var result: LessonResult?

    private var current: Question? { questions.indices.contains(index) ? questions[index] : nil }

    var body: some View {
        ZStack {
            LinearGradient(colors: [skill.color.opacity(0.25), Theme.cream], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            if let q = current {
                VStack(spacing: 14) {
                    topBar
                    ScrollView {
                        VStack(spacing: 16) {
                            questionCard(q)
                            choicesGrid(q)
                            MascotBubble(text: bubble.isEmpty ? "Tap the right answer!" : bubble)
                                .animation(.spring, value: bubble)
                        }
                        .padding(.horizontal, 18)
                        .padding(.bottom, 100)
                        .frame(maxWidth: 680)
                        .frame(maxWidth: .infinity)
                    }
                }
                .overlay(alignment: .bottom) { nextButton }
            }

            if let result {
                ResultView(result: result, skill: skill, onAgain: restart, onHome: { dismiss() })
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sensoryFeedback(.success, trigger: successCount) { _, _ in store.settings.haptics }
        .sensoryFeedback(.error, trigger: errorCount) { _, _ in store.settings.haptics }
        .onAppear { if questions.isEmpty { restart() } }
        .onDisappear { Speaker.shared.stop() }
    }

    // MARK: Pieces

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(.white))
            }
            .accessibilityLabel("Close")

            ProgressView(value: Double(index + (solved ? 1 : 0)), total: Double(max(questions.count, 1)))
                .tint(skill.color)
                .scaleEffect(x: 1, y: 3, anchor: .center)

            Text("\(min(index + 1, questions.count))/\(questions.count)")
                .font(.kid(18, .bold))
                .foregroundStyle(Theme.inkSoft)
                .monospacedDigit()
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
    }

    private func questionCard(_ q: Question) -> some View {
        VStack(spacing: 18) {
            HStack(alignment: .top) {
                Text(q.prompt)
                    .font(.kid(26, .heavy))
                    .foregroundStyle(Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    Speaker.shared.say(q.spoken)
                } label: {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(Circle().fill(Theme.blue.gradient))
                }
                .buttonStyle(BouncyButtonStyle())
                .accessibilityLabel("Read question out loud")
            }
            if q.visual != .empty {
                QuestionVisualView(visual: q.visual)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
        }
        .padding(20)
        .card()
    }

    private func choicesGrid(_ q: Question) -> some View {
        let isGroup: Bool = {
            if let first = q.choices.first, case .group = first { return true }
            return false
        }()
        let columns = isGroup ? 1 : 2
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns), spacing: 12) {
            ForEach(Array(q.choices.enumerated()), id: \.offset) { i, choice in
                Button { pick(i) } label: {
                    ChoiceLabel(choice: choice, state: state(for: i, in: q))
                }
                .buttonStyle(BouncyButtonStyle())
                .disabled(solved || wrongPicks.contains(i))
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
                Text(index + 1 < questions.count ? "Next" : "Finish")
                    .font(.kid(24, .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 520, minHeight: 64)
                    .background(Capsule().fill(Theme.blue.gradient))
                    .shadow(color: Theme.blue.opacity(0.4), radius: 8, y: 4)
            }
            .buttonStyle(BouncyButtonStyle())
            .padding(.horizontal, 18)
            .padding(.bottom, 12)
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
                bubble = "\(cheer) \(q.explanation)"
            }
            if store.settings.readAloud { Speaker.shared.say("\(cheer) \(q.explanation)") }
        } else {
            mistakes += 1
            errorCount += 1
            let nudge = Speaker.encourage.randomElement() ?? "Try again!"
            wrongPicks.insert(i)
            withAnimation(.linear(duration: 0.4)) { shake += 1 }
            withAnimation(.spring) { bubble = "\(nudge) Hint: \(q.hint)" }
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
}

struct ChoiceLabel: View {
    enum Mark { case normal, right, wrong }
    let choice: Choice
    let state: Mark

    var body: some View {
        content
            .frame(maxWidth: .infinity, minHeight: 76)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(fill)
                    .shadow(color: Theme.ink.opacity(0.08), radius: 5, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(stroke, lineWidth: 4)
            )
            .overlay(alignment: .topTrailing) {
                if state != .normal {
                    Image(systemName: state == .right ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(state == .right ? Theme.green : Theme.red)
                        .background(Circle().fill(.white))
                        .offset(x: 6, y: -6)
                }
            }
            .opacity(state == .wrong ? 0.6 : 1)
    }

    @ViewBuilder
    private var content: some View {
        switch choice {
        case .text(let text):
            Text(text)
                .font(.kid(text.count > 4 ? 26 : 34, .heavy))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.horizontal, 8)
        case .group(let emoji, let count):
            ObjectsGrid(emoji: emoji, count: count)
                .padding(10)
        }
    }

    private var fill: Color {
        switch state {
        case .normal: return .white
        case .right: return Theme.green.opacity(0.2)
        case .wrong: return Theme.red.opacity(0.12)
        }
    }

    private var stroke: Color {
        switch state {
        case .normal: return .clear
        case .right: return Theme.green
        case .wrong: return Theme.red.opacity(0.6)
        }
    }
}
