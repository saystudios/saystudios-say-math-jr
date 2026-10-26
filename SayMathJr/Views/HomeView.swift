import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: ProgressStore
    @State private var path: [Skill] = []
    @State private var showStickers = false
    @State private var showGate = false
    @State private var showParent = false

    private var skills: [Skill] { Skill.skills(for: store.grade) }

    var body: some View {
        NavigationStack(path: $path) {
            ZStack {
                SceneBackground()
                ScrollView {
                    VStack(spacing: 16) {
                        header
                        MascotBubble(text: greeting, mood: .happy, pipSize: 84)
                        statsRow
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 12) {
                            ForEach(skills) { skill in
                                NavigationLink(value: skill) {
                                    SkillTile(skill: skill, progress: store.progress(for: skill))
                                }
                                .buttonStyle(CandyButtonStyle(color: skill.color.lighter(0.62), radius: 28, depth: 7))
                            }
                        }
                        bottomButtons
                        Text("© Say Studios LLC")
                            .font(.kid(12, .medium))
                            .foregroundStyle(Theme.ink.opacity(0.6))
                            .padding(.top, 4)
                    }
                    .padding(18)
                    .frame(maxWidth: 820)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationDestination(for: Skill.self) { skill in
                LessonView(skill: skill)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showStickers) { StickerBookView() }
        .sheet(isPresented: $showGate) {
            ParentGateView {
                showGate = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { showParent = true }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showParent) { ParentView() }
        .onAppear(perform: openDemoScreen)
    }

    private var greeting: String {
        let done = skills.filter { store.progress(for: $0).bestStars > 0 }.count
        if done == 0 { return "Pick a game to start. You've got this!" }
        if done == skills.count { return "Wow, you tried every game! Can you get 3 stars on all?" }
        return "Yay! Pick another game to earn more stars."
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(store.profile?.avatar ?? "🐶")
                .font(.system(size: 36))
                .frame(width: 62, height: 62)
                .background(Circle().fill(.white))
                .overlay(Circle().stroke(Theme.yellow, lineWidth: 4))
                .shadow(color: Theme.ink.opacity(0.12), radius: 4, y: 3)
            VStack(alignment: .leading, spacing: 2) {
                Text("Hi, \(store.profile?.name ?? "Friend")!")
                    .font(.kid(28, .heavy))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(store.grade.title)
                    .font(.kid(14, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Theme.purple))
            }
            Spacer()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(icon: "star.fill", value: "\(store.data.totalStars)", label: "Stars", color: Theme.yellow)
            StatPill(icon: "flame.fill", value: "\(store.currentStreak)", label: "Day streak", color: Theme.orange)
            StatPill(icon: "gift.fill", value: "\(store.unlockedStickerCount)", label: "Stickers", color: Theme.pink)
        }
    }

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button { showStickers = true } label: {
                Label("Sticker Book", systemImage: "book.fill")
                    .font(.kid(18, .heavy))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(CandyButtonStyle(color: Theme.purple, radius: 27))

            Button { showGate = true } label: {
                Label("Grown-ups", systemImage: "lock.fill")
                    .font(.kid(18, .heavy))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(CandyButtonStyle(color: .white, radius: 27))
        }
        .padding(.top, 6)
    }

    private func openDemoScreen() {
        switch DemoMode.screen {
        case "lesson", "lessonCorrect", "lessonWrong", "result":
            if path.isEmpty { path = [DemoMode.skill] }
        case "stickers":
            showStickers = true
        default:
            break
        }
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(color.darker(0.05))
                Text(value)
                    .font(.kid(24, .heavy))
                    .foregroundStyle(Theme.ink)
            }
            Text(label).font(.kid(12, .bold)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, minHeight: 66)
        .candy(.white, radius: 22, depth: 5)
        .accessibilityElement(children: .combine)
    }
}

struct SkillTile: View {
    let skill: Skill
    let progress: SkillProgress

    var body: some View {
        VStack(spacing: 8) {
            SkillIcon(skill: skill, size: 80)
                .overlay(alignment: .topTrailing) {
                    if progress.bestStars == 3 {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(Theme.yellow)
                            .shadow(color: Theme.orange.opacity(0.5), radius: 0, y: 2)
                            .rotationEffect(.degrees(20))
                            .offset(x: 6, y: -6)
                    }
                }
            Text(skill.title)
                .font(.kid(19, .heavy))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(i < progress.bestStars ? Theme.yellow : .white.opacity(0.85))
                        .shadow(color: i < progress.bestStars ? Theme.orange.opacity(0.4) : .clear, radius: 0, y: 1.5)
                }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(skill.title), \(progress.bestStars) of 3 stars")
    }
}
