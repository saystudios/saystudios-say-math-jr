import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var name = ""
    @State private var grade: Grade = .k
    @State private var avatar = "🐶"

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("Say Math")
                            .font(.kid(46, .heavy))
                            .foregroundStyle(LinearGradient(colors: [Theme.blue, Theme.purple], startPoint: .leading, endPoint: .trailing))
                        Text("Jr.")
                            .font(.kid(40, .heavy))
                            .foregroundStyle(LinearGradient(colors: [Theme.pink, Theme.orange], startPoint: .leading, endPoint: .trailing))
                        Text("Little steps. Big math!")
                            .font(.kid(18, .semibold))
                            .foregroundStyle(Theme.inkSoft)
                    }
                    .padding(.top, 30)

                    MascotBubble(text: "Hi! I'm Pip. Let's set up your player!")

                    VStack(alignment: .leading, spacing: 12) {
                        label("Pick your buddy")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                            ForEach(ProgressStore.avatars, id: \.self) { a in
                                Button { avatar = a } label: {
                                    Text(a)
                                        .font(.system(size: 40))
                                        .frame(width: 64, height: 64)
                                        .background(Circle().fill(avatar == a ? Theme.yellow.opacity(0.6) : Theme.sky))
                                        .overlay(Circle().stroke(avatar == a ? Theme.orange : .clear, lineWidth: 4))
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
                            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.sky.opacity(0.6)))

                        label("Your grade")
                        HStack(spacing: 10) {
                            ForEach(Grade.allCases) { g in
                                Button { grade = g } label: {
                                    Text(g.short)
                                        .font(.kid(24, .heavy))
                                        .foregroundStyle(grade == g ? .white : Theme.ink)
                                        .frame(maxWidth: .infinity, minHeight: 60)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(grade == g ? Theme.blue : Theme.sky)
                                        )
                                }
                                .buttonStyle(BouncyButtonStyle())
                                .accessibilityLabel(g.title)
                            }
                        }
                    }
                    .padding(20)
                    .card()

                    Button {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        store.saveProfile(Profile(name: trimmed.isEmpty ? "Friend" : trimmed, grade: grade, avatar: avatar))
                    } label: {
                        Text("Let's Play!")
                            .font(.kid(26, .heavy))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, minHeight: 66)
                            .background(Capsule().fill(Theme.green.gradient))
                            .shadow(color: Theme.green.opacity(0.4), radius: 8, y: 4)
                    }
                    .buttonStyle(BouncyButtonStyle())

                    Text("Grown-ups: no ads, no accounts. Progress stays on this device.")
                        .font(.kid(13, .medium))
                        .foregroundStyle(Theme.inkSoft)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.kid(18, .bold)).foregroundStyle(Theme.ink)
    }
}
