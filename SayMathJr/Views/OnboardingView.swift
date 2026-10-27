import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var name = ""
    @State private var grade: Grade = .k
    @State private var avatar = "🐶"

    var body: some View {
        ZStack {
            SceneBackground()
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 0) {
                        BubbleTitle(text: "Say Math", size: 54)
                        BubbleTitle(text: "Jr.", size: 44, colors: [Theme.pink, Theme.orange, Theme.yellow])
                            .padding(.top, -6)
                        Text("Little steps. Big math!")
                            .font(.kid(18, .heavy))
                            .foregroundStyle(Theme.ink)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(.white.opacity(0.9)))
                            .padding(.top, 6)
                    }
                    .padding(.top, 24)

                    MascotBubble(text: "Hi! I'm Pip. Let's set up your player!", mood: .wave, pipSize: 96)

                    VStack(alignment: .leading, spacing: 12) {
                        label("Pick your buddy")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(ProgressStore.avatars, id: \.self) { a in
                                Button { avatar = a } label: {
                                    Text(a)
                                        .font(.system(size: 38))
                                        .frame(width: 64, height: 64)
                                        .background(Circle().fill(avatar == a ? Theme.yellow.lighter(0.4) : Theme.sky))
                                        .overlay(Circle().stroke(avatar == a ? Theme.orange : .white, lineWidth: 4))
                                        .scaleEffect(avatar == a ? 1.08 : 1)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: avatar)
                                }
                                .buttonStyle(BouncyButtonStyle())
                                .accessibilityLabel("Buddy \(a)")
                            }
                        }

                        label("Your name")
                        TextField("Name", text: $name)
                            .font(.kid(24, .semibold))
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: 18).fill(Theme.sky.opacity(0.6)))

                        label("Your grade")
                        HStack(spacing: 10) {
                            ForEach(Grade.allCases) { g in
                                Button { grade = g } label: {
                                    Text(g.short)
                                        .font(.kid(24, .heavy))
                                        .foregroundStyle(grade == g ? .white : Theme.ink)
                                        .frame(maxWidth: .infinity, minHeight: 56)
                                }
                                .buttonStyle(CandyButtonStyle(color: grade == g ? Theme.blue : Theme.sky, radius: 20, depth: 5))
                                .accessibilityLabel(g.title)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 30, style: .continuous)
                            .fill(.white)
                            .shadow(color: Theme.ink.opacity(0.10), radius: 12, y: 6)
                    )

                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.saveProfile(Profile(name: trimmed.isEmpty ? "Friend" : trimmed, grade: grade, avatar: avatar))
                    } label: {
                        Text("Let's Play!")
                            .font(.kid(26, .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 64)
                    }
                    .buttonStyle(CandyButtonStyle(color: Theme.green, radius: 32, depth: 7))

                    Text("Grown-ups: no ads, no accounts. Progress stays on this device.")
                        .font(.kid(13, .semibold))
                        .foregroundStyle(Theme.ink.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 10)
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.kid(18, .heavy)).foregroundStyle(Theme.ink)
    }
}
