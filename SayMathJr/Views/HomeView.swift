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
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        header
                        MascotBubble(text: greeting)
                        statsRow
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                            ForEach(skills) { skill in
                                NavigationLink(value: skill) {
                                    SkillTile(skill: skill, progress: store.progress(for: skill))
                                }
                                .buttonStyle(BouncyButtonStyle())
                            }
                        }
                        bottomButtons
                        Text("© Say Studios LLC")
                            .font(.kid(12, .medium))
                            .foregroundStyle(Theme.inkSoft)
                            .padding(.top, 6)
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
                .font(.system(size: 38))
                .frame(width: 60, height: 60)
                .background(Circle().fill(.white))
            VStack(alignment: .leading, spacing: 0) {
                Text("Hi, \(store.profile?.name ?? "Friend")!")
                    .font(.kid(26, .heavy))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("Say Math Jr. · \(store.grade.title)")
                    .font(.kid(15, .semibold))
                    .foregroundStyle(Theme.inkSoft)
            }
            Spacer()
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatPill(icon: "⭐", value: "\(store.data.totalStars)", label: "Stars", color: Theme.yellow)
            StatPill(icon: "🔥", value: "\(store.currentStreak)", label: "Day streak", color: Theme.orange)
            StatPill(icon: "🎁", value: "\(store.unlockedStickerCount)", label: "Stickers", color: Theme.pink)
        }
    }

    private var bottomButtons: some View {
        HStack(spacing: 12) {
            Button { showStickers = true } label: {
                Label("Sticker Book", systemImage: "book.fill")
                    .font(.kid(18, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Capsule().fill(Theme.purple.gradient))
            }
            .buttonStyle(BouncyButtonStyle())

            Button { showGate = true } label: {
                Label("Grown-ups", systemImage: "lock.fill")
                    .font(.kid(18, .bold))
                    .foregroundStyle(Theme.ink)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Capsule().fill(.white))
            }
            .buttonStyle(BouncyButtonStyle())
        }
        .padding(.top, 6)
    }
}

struct StatPill: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text("\(icon) \(value)").font(.kid(22, .heavy)).foregroundStyle(Theme.ink)
            Text(label).font(.kid(12, .semibold)).foregroundStyle(Theme.inkSoft)
        }
        .frame(maxWidth: .infinity, minHeight: 68)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(color.opacity(0.25)))
        .accessibilityElement(children: .combine)
    }
}

struct SkillTile: View {
    let skill: Skill
    let progress: SkillProgress

    var body: some View {
        VStack(spacing: 8) {
            Text(skill.emoji)
                .font(.system(size: 44))
                .frame(width: 76, height: 76)
                .background(Circle().fill(.white.opacity(0.85)))
            Text(skill.title)
                .font(.kid(19, .heavy))
                .foregroundStyle(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: i < progress.bestStars ? "star.fill" : "star")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(i < progress.bestStars ? Theme.yellow : Theme.ink.opacity(0.25))
                }
            }
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(skill.color.opacity(0.28))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .stroke(skill.color.opacity(0.6), lineWidth: 2)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(skill.title), \(progress.bestStars) of 3 stars")
    }
}
