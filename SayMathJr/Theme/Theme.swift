import SwiftUI

/// Soft pastel palette shared across the app (matches the Say Math family look).
enum Theme {
    static let sky = Color(red: 0.84, green: 0.92, blue: 1.00)
    static let cream = Color(red: 1.00, green: 0.98, blue: 0.93)
    static let ink = Color(red: 0.16, green: 0.18, blue: 0.32)
    static let inkSoft = Color(red: 0.38, green: 0.40, blue: 0.55)

    static let blue = Color(red: 0.36, green: 0.62, blue: 0.98)
    static let pink = Color(red: 1.00, green: 0.55, blue: 0.70)
    static let yellow = Color(red: 1.00, green: 0.80, blue: 0.30)
    static let green = Color(red: 0.36, green: 0.80, blue: 0.55)
    static let purple = Color(red: 0.62, green: 0.52, blue: 0.96)
    static let orange = Color(red: 1.00, green: 0.62, blue: 0.35)
    static let teal = Color(red: 0.30, green: 0.78, blue: 0.80)
    static let red = Color(red: 0.96, green: 0.40, blue: 0.42)

    static let background = LinearGradient(
        colors: [sky, cream],
        startPoint: .top,
        endPoint: .bottom
    )
}

extension Font {
    /// Big, round, friendly type for young readers.
    static func kid(_ size: CGFloat, _ weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// White rounded card with a soft shadow.
struct CardBackground: ViewModifier {
    var tint: Color = .white
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(tint)
                    .shadow(color: Theme.ink.opacity(0.10), radius: 10, y: 5)
            )
    }
}

extension View {
    func card(_ tint: Color = .white) -> some View { modifier(CardBackground(tint: tint)) }
}

/// A chunky "pressable" button style for little fingers.
struct BouncyButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// Side-to-side wiggle used when an answer is wrong.
struct Shake: GeometryEffect {
    var amount: CGFloat = 10
    var shakes: CGFloat = 3
    var animatableData: CGFloat
    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * shakes), y: 0))
    }
}
