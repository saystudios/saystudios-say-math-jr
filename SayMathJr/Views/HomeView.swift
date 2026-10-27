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
            GeometryReader { geo in
                let contentWidth = min(geo.size.width, 760) - 32
                ZStack {
                    SceneBackground()
                    ScrollView {
                        VStack(spacing: 16) {
                            topBar
                            hero
                            skillGrid(width: contentWidth)
                            Text("© Say Studios LLC")
                                .font(.kid(12, .semibold))
                                .foregroundStyle(Theme.ink.opacity(0.55))
                                .padding(.top, 6)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                        .frame(maxWidth: 760)
                        .frame(maxWidth: .infinity)
                    }
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

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            RoundIconButton(systemName: "gearshape.fill", label: "Grown-ups") { showGate = true }
            Spacer()
            HStack(spacing: 14) {
                PillStat(systemName: "star.fill", color: Theme.yellow.darker(0.05), value: store.data.totalStars)
                PillStat(systemName: "flame.fill", color: Theme.orange, value: store.currentStreak)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(Capsule().fill(.white.opacity(0.92)))
            .shadow(color: Theme.ink.opacity(0.1), radius: 4, y: 2)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(store.data.totalStars) stars, \(store.currentStreak) day streak")
            Spacer()
            RoundIconButton(systemName: "book.fill", label: "Sticker Book") { showStickers = true }
                .overlay(alignment: .topTrailing) {
                    if store.unlockedStickerCount > 0 {
                        Text("\(store.unlockedStickerCount)")
                            .font(.kid(12, .black))
                            .foregroundStyle(.white)
                            .frame(minWidth: 20, minHeight: 20)
                            .background(Circle().fill(Theme.pink))
                            .offset(x: 4, y: -4)
                    }
                }
        }
        .padding(.top, 6)
    }

    // MARK: Hero

    @ViewBuilder
    private var hero: some View {
        VStack(spacing: -22) {
            if let art = UIImage(named: "home_hero") {
                Image(uiImage: art)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 210)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 30, style: .continuous).stroke(.white, lineWidth: 5))
                    .shadow(color: Theme.ink.opacity(0.15), radius: 10, y: 6)
                    .accessibilityHidden(true)
            } else {
                PipView(mood: .happy, size: 170)
                    .padding(.bottom, 10)
            }
            VStack(spacing: 2) {
                WoodSign(text: "Hi, \(store.profile?.name ?? "Friend")!", size: 26)
                Text(store.grade.title)
                    .font(.kid(13, .heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Theme.purple))
                    .padding(.top, 8)
            }
        }
    }

    // MARK: Grid (3 per row, last row centered)

    private func skillGrid(width: CGFloat) -> some View {
        let spacing: CGFloat = 12
        let tileWidth = (width - spacing * 2) / 3
        let rows = stride(from: 0, to: skills.count, by: 3).map { Array(skills[$0..<min($0 + 3, skills.count)]) }
        return VStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: spacing) {
                    ForEach(row) { skill in
                        NavigationLink(value: skill) {
                            SkillTile(skill: skill, progress: store.progress(for: skill))
                                .frame(width: tileWidth)
                        }
                        .buttonStyle(CandyButtonStyle(color: skill.color.lighter(0.68), radius: 24, depth: 5))
                    }
                }
            }
        }
        .padding(.top, 4)
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

struct RoundIconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Theme.blue)
                .frame(width: 50, height: 50)
        }
        .buttonStyle(CandyButtonStyle(color: .white, radius: 25, depth: 4))
        .accessibilityLabel(label)
    }
}

struct PillStat: View {
    let systemName: String
    let color: Color
    let value: Int

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .heavy))
                .foregroundStyle(color)
            Text("\(value)")
                .font(.kid(20, .black))
                .foregroundStyle(Theme.ink)
        }
    }
}

struct SkillTile: View {
    let skill: Skill
    let progress: SkillProgress

    var body: some View {
        VStack(spacing: 6) {
            SkillIcon(skill: skill, size: 62)
                .overlay(alignment: .topTrailing) {
                    if progress.bestStars == 3 {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(Theme.yellow)
                            .shadow(color: Theme.orange.opacity(0.5), radius: 0, y: 2)
                            .rotationEffect(.degrees(20))
                            .offset(x: 8, y: -6)
                    }
                }
            Text(skill.title)
                .font(.kid(15, .heavy))
                .foregroundStyle(Theme.ink)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .frame(minHeight: 36)
            HStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(i < progress.bestStars ? Theme.yellow : .white.opacity(0.9))
                        .shadow(color: i < progress.bestStars ? Theme.orange.opacity(0.4) : .clear, radius: 0, y: 1)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(skill.title), \(progress.bestStars) of 3 stars")
    }
}
