import SwiftUI

@main
struct SayMathJrApp: App {
    @StateObject private var store: ProgressStore

    init() {
        _store = StateObject(wrappedValue: DemoMode.makeStore() ?? ProgressStore())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: ProgressStore

    var body: some View {
        Group {
            if store.profile == nil {
                OnboardingView()
            } else {
                HomeView()
            }
        }
        .animation(.easeInOut, value: store.profile == nil)
    }
}

extension Skill {
    var color: Color {
        switch colorName {
        case "red": return Theme.red
        case "purple": return Theme.purple
        case "green": return Theme.green
        case "orange": return Theme.orange
        case "blue": return Theme.blue
        case "pink": return Theme.pink
        case "yellow": return Theme.yellow
        default: return Theme.teal
        }
    }
}

/// Screenshot/demo mode, used by the cloud build to capture screens.
/// Launch with arguments like `-demoScreen home -demoSkill counting -demoGrade K`.
/// Never active in normal use.
enum DemoMode {
    static var screen: String? { UserDefaults.standard.string(forKey: "demoScreen") }
    static var skill: Skill { Skill(rawValue: UserDefaults.standard.string(forKey: "demoSkill") ?? "") ?? .addition }
    static var isOn: Bool { screen != nil }

    @MainActor
    static func makeStore() -> ProgressStore? {
        guard let screen, let defaults = UserDefaults(suiteName: "SayMathJrDemo") else { return nil }
        defaults.removePersistentDomain(forName: "SayMathJrDemo")
        let store = ProgressStore(defaults: defaults, key: "demo")
        store.updateSettings { $0.readAloud = false }
        if screen != "onboarding" {
            let grade = Grade(rawValue: UserDefaults.standard.string(forKey: "demoGrade") ?? "K") ?? .k
            store.saveProfile(Profile(name: "Mia", grade: grade, avatar: "🐶"))
            let earned: [(Skill, Int)] = [(.counting, 3), (.addition, 2), (.shapes, 3), (.patterns, 1), (.compare, 3), (.makeTen, 2)]
            for (skill, stars) in earned {
                store.recordLesson(skill: skill, stars: stars, firstTryCorrect: stars + 2, questions: 5)
            }
        }
        return store
    }
}
