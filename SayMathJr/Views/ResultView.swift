import SwiftUI

struct LessonResult: Equatable {
    let stars: Int
    let firstTryCorrect: Int
    let total: Int
    let newStickers: Int
}

struct ResultView: View {
    let result: LessonResult
    let skill: Skill
    let onAgain: () -> Void
    let onHome: () -> Void

    @State private var shown = 0

    var body: some View {
        ZStack {
            Color.black.opacity(0.25).ignoresSafeArea()
            VStack(spacing: 18) {
                Text(result.stars == 3 ? "Perfect!" : "Great Work!")
                    .font(.kid(38, .heavy))
                    .foregroundStyle(Theme.ink)

                HStack(spacing: 10) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: i < result.stars ? "star.fill" : "star")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundStyle(i < result.stars ? Theme.yellow : Theme.ink.opacity(0.2))
                            .scaleEffect(i < shown ? 1 : 0.2)
                            .opacity(i < shown || i >= result.stars ? 1 : 0)
                    }
                }

                Text("\(result.firstTryCorrect) of \(result.total) right on the first try")
                    .font(.kid(18, .semibold))
                    .foregroundStyle(Theme.inkSoft)

                if result.newStickers > 0 {
                    Label("New sticker unlocked!", systemImage: "gift.fill")
                        .font(.kid(20, .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Theme.pink.gradient))
                }

                Text(skill.emoji).font(.system(size: 60))

                VStack(spacing: 10) {
                    Button(action: onAgain) {
                        Text("Play Again")
                            .font(.kid(22, .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background(Capsule().fill(Theme.green.gradient))
                    }
                    Button(action: onHome) {
                        Text("Home")
                            .font(.kid(22, .heavy))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 58)
                            .background(Capsule().fill(Theme.sky))
                    }
                }
                .buttonStyle(BouncyButtonStyle())
            }
            .padding(26)
            .frame(maxWidth: 420)
            .card()
            .padding(24)
        }
        .onAppear {
            for i in 0..<result.stars {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { shown = i + 1 }
                }
            }
        }
    }
}
