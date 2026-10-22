import SwiftUI

@main
struct SayMathJrApp: App {
    @StateObject private var store = ProgressStore()

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

/// Pip the puppy, the app's helper, with a speech bubble.
struct MascotBubble: View {
    let text: String
    var mascot: String = "🐶"

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(mascot)
                .font(.system(size: 54))
                .accessibilityHidden(true)
            Text(text)
                .font(.kid(19, .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.white)
                        .shadow(color: Theme.ink.opacity(0.08), radius: 6, y: 3)
                )
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
