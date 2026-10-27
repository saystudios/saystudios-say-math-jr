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
    @State private var confetti = 0

    var body: some View {
        ZStack {
            Theme.ink.opacity(0.35).ignoresSafeArea()

            VStack(spacing: 14) {
                PipView(mood: .trophy, size: 130)
                    .padding(.top, -70)

                WoodSign(text: result.stars == 3 ? "Perfect!" : "Great Work!", size: 32)

                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(0..<3, id: \.self) { i in
                        Image(systemName: "star.fill")
                            .font(.system(size: i == 1 ? 66 : 52, weight: .bold))
                            .foregroundStyle(i < result.stars ? Theme.yellow : Theme.ink.opacity(0.12))
                            .shadow(color: i < result.stars ? Theme.orange.opacity(0.55) : .clear, radius: 0, y: 4)
                            .scaleEffect(i < shown || i >= result.stars ? 1 : 0.2)
                            .rotationEffect(.degrees(i == 0 ? -10 : i == 2 ? 10 : 0))
                            .offset(y: i == 1 ? -10 : 0)
                    }
                }

                Text("\(result.firstTryCorrect) of \(result.total) right on the first try")
                    .font(.kid(17, .bold))
                    .foregroundStyle(Theme.inkSoft)

                if result.newStickers > 0 {
                    Label("New sticker unlocked!", systemImage: "gift.fill")
                        .font(.kid(19, .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .candy(Theme.pink, radius: 22, depth: 4)
                }

                VStack(spacing: 6) {
                    Button(action: onAgain) {
                        Label("Play Again", systemImage: "arrow.clockwise")
                            .font(.kid(22, .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(CandyButtonStyle(color: Theme.green, radius: 28))

                    Button(action: onHome) {
                        Label("Home", systemImage: "house.fill")
                            .font(.kid(22, .heavy))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 56)
                    }
                    .buttonStyle(CandyButtonStyle(color: Theme.sky, radius: 28))
                }
                .padding(.top, 4)
            }
            .padding(24)
            .padding(.top, 10)
            .frame(maxWidth: 400)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(LinearGradient(colors: [.white, skill.color.lighter(0.85)], startPoint: .top, endPoint: .bottom))
                    .shadow(color: Theme.ink.opacity(0.2), radius: 20, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .stroke(.white, lineWidth: 4)
            )
            .padding(24)
            .padding(.top, 50)

            ConfettiBurst(trigger: confetti, count: 40)
        }
        .onAppear {
            for i in 0..<result.stars {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25 + Double(i) * 0.3) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { shown = i + 1 }
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { confetti += 1 }
        }
    }
}
