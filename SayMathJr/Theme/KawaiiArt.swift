import SwiftUI
import UIKit

// MARK: - Color helpers

extension Color {
    /// Blend toward another color. t = 0 keeps self, t = 1 gives `other`.
    func mixed(with other: Color, _ t: CGFloat) -> Color {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(
            red: Double(r1 + (r2 - r1) * t),
            green: Double(g1 + (g2 - g1) * t),
            blue: Double(b1 + (b2 - b1) * t),
            opacity: Double(a1 + (a2 - a1) * t))
    }

    func lighter(_ t: CGFloat = 0.5) -> Color { mixed(with: .white, t) }
    func darker(_ t: CGFloat = 0.2) -> Color { mixed(with: .black, t) }
}

// MARK: - Pip the puppy

enum PipMood: Equatable {
    case happy, cheer, think, oops, wave, trophy

    /// Image name in the asset catalog. If the image is missing, Pip is drawn in code instead.
    var assetName: String {
        switch self {
        case .happy: return "pip_happy"
        case .cheer: return "pip_cheer"
        case .think: return "pip_think"
        case .oops: return "pip_oops"
        case .wave: return "pip_wave"
        case .trophy: return "pip_trophy"
        }
    }

    /// The finished artwork for this mood. Thinking falls back to the happy pose
    /// so the art style stays consistent until a thinking pose is added.
    var artwork: UIImage? {
        if let image = UIImage(named: assetName) { return image }
        switch self {
        case .think, .wave: return UIImage(named: "pip_happy")
        case .trophy: return UIImage(named: "pip_cheer")
        default: return nil
        }
    }

    /// Mood used by the code-drawn fallback, which only has four faces.
    var drawnMood: PipMood {
        switch self {
        case .wave: return .happy
        case .trophy: return .cheer
        default: return self
        }
    }
}

/// Pip, the app's original puppy helper, drawn entirely in code.
struct PipView: View {
    var mood: PipMood = .happy
    var size: CGFloat = 80
    var bobbing = true

    @State private var pop = false

    var body: some View {
        let art = mood.artwork
        ZStack {
            if mood.drawnMood == .cheer && art == nil {
                ForEach(0..<4, id: \.self) { i in
                    SparkleShape()
                        .fill(i.isMultiple(of: 2) ? Theme.yellow : Theme.pink)
                        .frame(width: size * 0.18, height: size * 0.18)
                        .offset(
                            x: CGFloat([-0.52, 0.52, -0.42, 0.46][i]) * size,
                            y: CGFloat([-0.38, -0.3, 0.32, 0.36][i]) * size)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            if let art {
                // Finished artwork (Assets.xcassets/pip_<mood>) when it has been added
                Image(uiImage: art)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: size * 1.12, height: size * 1.12)
            } else {
                Canvas { ctx, canvasSize in
                    PipDrawing(mood: mood.drawnMood).draw(in: &ctx, size: canvasSize)
                }
                .frame(width: size, height: size)
            }
        }
        .frame(width: size, height: size)
        .scaleEffect(pop ? 1.12 : 1)
        .phaseAnimator(bobbing ? [false, true] : [false]) { content, up in
            content.offset(y: up ? -size * 0.04 : size * 0.02)
        } animation: { _ in
            .easeInOut(duration: 1.3)
        }
        .onChange(of: mood) { _, newMood in
            guard newMood == .cheer || newMood == .oops else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.45)) { pop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { pop = false }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PipDrawing {
    let mood: PipMood

    static let cream = Color(red: 1.00, green: 0.95, blue: 0.86)
    static let caramel = Color(red: 0.86, green: 0.62, blue: 0.42)
    static let outline = Color(red: 0.42, green: 0.28, blue: 0.22)
    static let dark = Color(red: 0.22, green: 0.16, blue: 0.20)
    static let blush = Color(red: 1.00, green: 0.55, blue: 0.62)

    func draw(in ctx: inout GraphicsContext, size: CGSize) {
        let s = min(size.width, size.height)
        let c = CGPoint(x: size.width / 2, y: size.height / 2)
        let line = s * 0.024

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: c.x + x * s, y: c.y + y * s) }
        func ell(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> Path {
            Path(ellipseIn: CGRect(x: c.x + (x - w / 2) * s, y: c.y + (y - h / 2) * s, width: w * s, height: h * s))
        }
        func rotated(_ path: Path, around pt: CGPoint, by angle: CGFloat) -> Path {
            path.applying(
                CGAffineTransform(translationX: pt.x, y: pt.y)
                    .rotated(by: angle)
                    .translatedBy(x: -pt.x, y: -pt.y))
        }

        // Collar (behind head)
        let collar = Path(roundedRect: CGRect(x: c.x - 0.22 * s, y: c.y + 0.33 * s, width: 0.44 * s, height: 0.1 * s),
                          cornerRadius: 0.05 * s)
        ctx.fill(collar, with: .color(Theme.blue))
        ctx.stroke(collar, with: .color(Self.outline), lineWidth: line)

        // Floppy ears
        for side in [-1.0, 1.0] as [CGFloat] {
            let center = p(side * 0.35, 0.0)
            let ear = rotated(ell(side * 0.35, 0.0, 0.25, 0.48), around: center, by: side * 0.38)
            ctx.fill(ear, with: .color(Self.caramel))
            ctx.stroke(ear, with: .color(Self.outline), lineWidth: line)
        }

        // Head
        let head = ell(0, 0.0, 0.80, 0.74)
        ctx.fill(head, with: .color(Self.cream))
        ctx.drawLayer { layer in
            layer.clip(to: head)
            layer.fill(ell(0.22, -0.12, 0.30, 0.28), with: .color(Self.caramel.opacity(0.75)))   // eye patch
            layer.fill(ell(-0.12, -0.26, 0.22, 0.10), with: .color(.white.opacity(0.55)))      // shine
        }
        ctx.stroke(head, with: .color(Self.outline), lineWidth: line)

        // Muzzle
        ctx.fill(ell(0, 0.17, 0.40, 0.27), with: .color(.white))

        // Blush
        for side in [-1.0, 1.0] as [CGFloat] {
            ctx.fill(ell(side * 0.27, 0.10, 0.12, 0.07), with: .color(Self.blush.opacity(0.55)))
        }

        // Eyes
        for side in [-1.0, 1.0] as [CGFloat] {
            let ex = side * 0.17, ey: CGFloat = -0.04
            switch mood {
            case .cheer, .trophy:
                var arc = Path()
                arc.move(to: p(ex - 0.06, ey + 0.025))
                arc.addQuadCurve(to: p(ex + 0.06, ey + 0.025), control: p(ex, ey - 0.07))
                ctx.stroke(arc, with: .color(Self.dark), style: StrokeStyle(lineWidth: line * 1.3, lineCap: .round))
            case .happy, .think, .oops, .wave:
                let h: CGFloat = mood == .oops ? 0.12 : 0.15
                ctx.fill(ell(ex, ey, 0.115, h), with: .color(Self.dark))
                let lookUp: CGFloat = mood == .think ? -0.02 : 0
                ctx.fill(ell(ex - 0.02, ey - 0.035 + lookUp, 0.048, 0.048), with: .color(.white))
                ctx.fill(ell(ex + 0.022, ey + 0.03 + lookUp, 0.022, 0.022), with: .color(.white.opacity(0.9)))
                if mood == .oops {
                    var brow = Path()
                    brow.move(to: p(ex - 0.05 * side, ey - 0.12))
                    brow.addLine(to: p(ex + 0.05 * side, ey - 0.10))
                    ctx.stroke(brow, with: .color(Self.outline), style: StrokeStyle(lineWidth: line, lineCap: .round))
                }
            }
        }

        // Nose
        ctx.fill(ell(0, 0.095, 0.105, 0.072), with: .color(Self.dark))
        ctx.fill(ell(-0.02, 0.083, 0.03, 0.018), with: .color(.white.opacity(0.7)))

        // Mouth
        let mouthStyle = StrokeStyle(lineWidth: line, lineCap: .round, lineJoin: .round)
        switch mood {
        case .happy, .wave:
            var m = Path()
            m.move(to: p(0, 0.13)); m.addLine(to: p(0, 0.165))
            m.move(to: p(-0.075, 0.165))
            m.addQuadCurve(to: p(0, 0.165), control: p(-0.037, 0.225))
            m.addQuadCurve(to: p(0.075, 0.165), control: p(0.037, 0.225))
            ctx.stroke(m, with: .color(Self.dark), style: mouthStyle)
        case .cheer, .trophy:
            var m = Path()
            m.move(to: p(-0.1, 0.155))
            m.addQuadCurve(to: p(0.1, 0.155), control: p(0, 0.36))
            m.closeSubpath()
            ctx.fill(m, with: .color(Color(red: 0.62, green: 0.22, blue: 0.28)))
            ctx.drawLayer { layer in
                layer.clip(to: m)
                layer.fill(ell(0, 0.26, 0.11, 0.09), with: .color(Color(red: 1.0, green: 0.55, blue: 0.62)))
            }
            ctx.stroke(m, with: .color(Self.dark), style: mouthStyle)
        case .think:
            ctx.fill(ell(0.05, 0.2, 0.045, 0.045), with: .color(Self.dark))
        case .oops:
            var m = Path()
            m.move(to: p(-0.065, 0.2))
            m.addQuadCurve(to: p(0, 0.2), control: p(-0.032, 0.17))
            m.addQuadCurve(to: p(0.065, 0.2), control: p(0.032, 0.23))
            ctx.stroke(m, with: .color(Self.dark), style: mouthStyle)
            // Sweat drop
            var drop = Path()
            drop.move(to: p(0.36, -0.30))
            drop.addQuadCurve(to: p(0.36, -0.14), control: p(0.29, -0.17))
            drop.addQuadCurve(to: p(0.36, -0.30), control: p(0.43, -0.17))
            ctx.fill(drop, with: .color(Color(red: 0.55, green: 0.80, blue: 1.0)))
        }

        // Collar tag
        let tag = ell(0, 0.43, 0.10, 0.10)
        ctx.fill(tag, with: .color(Theme.yellow))
        ctx.stroke(tag, with: .color(Self.outline), lineWidth: line * 0.8)
    }
}

// MARK: - Sparkles, clouds and scenery

struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        var p = Path()
        p.move(to: CGPoint(x: c.x, y: c.y - r))
        p.addQuadCurve(to: CGPoint(x: c.x + r, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y + r), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x - r, y: c.y), control: c)
        p.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: c)
        p.closeSubpath()
        return p
    }
}

struct CloudView: View {
    var width: CGFloat = 120

    var body: some View {
        ZStack(alignment: .bottom) {
            Capsule().frame(width: width, height: width * 0.32)
            Circle().frame(width: width * 0.42).offset(x: -width * 0.16, y: -width * 0.1)
            Circle().frame(width: width * 0.55).offset(x: width * 0.1, y: -width * 0.14)
        }
        .foregroundStyle(.white.opacity(0.92))
        .frame(width: width, height: width * 0.6, alignment: .bottom)
        .shadow(color: Theme.blue.opacity(0.12), radius: 6, y: 4)
    }
}

/// Soft sky with drifting clouds, twinkling sparkles and rolling hills.
struct SceneBackground: View {
    var tint: Color? = nil
    var showHills = true

    private let sparkles: [(CGFloat, CGFloat, CGFloat)] = [
        (0.08, 0.22, 16), (0.9, 0.14, 12), (0.78, 0.36, 10), (0.18, 0.48, 9), (0.94, 0.56, 14), (0.5, 0.08, 10),
    ]

    /// Finished background artwork for this kind of screen, if it has been added.
    private var artName: String {
        if tint != nil { return "bg_lesson" }
        return showHills ? "bg_home" : "bg_stickers"
    }

    var body: some View {
        if let art = UIImage(named: artName) {
            Color.clear
                .overlay(alignment: .bottom) {
                    Image(uiImage: art)
                        .resizable()
                        .scaledToFill()
                }
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        } else {
            drawnScene
        }
    }

    private var drawnScene: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                LinearGradient(
                    colors: [
                        (tint ?? Color(red: 0.62, green: 0.82, blue: 1.0)).lighter(tint == nil ? 0.15 : 0.55),
                        Color(red: 0.92, green: 0.95, blue: 1.0),
                        Theme.cream,
                    ],
                    startPoint: .top, endPoint: .bottom)

                CloudView(width: 130)
                    .drifting(18)
                    .position(x: w * 0.2, y: h * 0.10)
                CloudView(width: 90)
                    .drifting(-14)
                    .position(x: w * 0.82, y: h * 0.22)
                CloudView(width: 70)
                    .drifting(10)
                    .position(x: w * 0.55, y: h * 0.42)
                    .opacity(0.7)

                ForEach(Array(sparkles.enumerated()), id: \.offset) { i, s in
                    SparkleShape()
                        .fill(i.isMultiple(of: 2) ? Theme.yellow : .white)
                        .frame(width: s.2, height: s.2)
                        .twinkling(startBright: i.isMultiple(of: 2))
                        .position(x: w * s.0, y: h * s.1)
                }

                if showHills {
                    Ellipse()
                        .fill(Color(red: 0.70, green: 0.90, blue: 0.72))
                        .frame(width: w * 1.3, height: 220)
                        .position(x: w * 0.15, y: h + 40)
                    Ellipse()
                        .fill(Color(red: 0.62, green: 0.86, blue: 0.66))
                        .frame(width: w * 1.2, height: 200)
                        .position(x: w * 0.95, y: h + 60)
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

private extension View {
    /// Slow side-to-side drift that only animates its own offset.
    func drifting(_ distance: CGFloat) -> some View {
        phaseAnimator([false, true]) { content, right in
            content.offset(x: right ? distance : -distance * 0.6)
        } animation: { _ in
            .easeInOut(duration: 7)
        }
    }

    func twinkling(startBright: Bool) -> some View {
        phaseAnimator([startBright, !startBright]) { content, bright in
            content.opacity(bright ? 1 : 0.35).scaleEffect(bright ? 1 : 0.7)
        } animation: { _ in
            .easeInOut(duration: 1.6)
        }
    }
}

// MARK: - Candy (3D) buttons and surfaces

extension View {
    /// Chunky, glossy "candy" surface with a darker bottom edge, like a toy button.
    func candy(_ color: Color, radius: CGFloat = 24, depth: CGFloat = 6, pressed: Bool = false) -> some View {
        modifier(CandySurface(color: color, radius: radius, depth: depth, pressed: pressed))
    }
}

struct CandySurface: ViewModifier {
    let color: Color
    var radius: CGFloat
    var depth: CGFloat
    var pressed: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .background(
                shape
                    .fill(LinearGradient(colors: [color.lighter(0.25), color], startPoint: .top, endPoint: .bottom))
                    .overlay(alignment: .top) {
                        Capsule()
                            .fill(.white.opacity(0.45))
                            .frame(height: max(4, radius * 0.28))
                            .padding(.horizontal, radius * 0.7)
                            .padding(.top, radius * 0.22)
                    }
                    .overlay(shape.stroke(.white.opacity(0.7), lineWidth: 2))
            )
            .offset(y: pressed ? depth * 0.75 : 0)
            .background(
                shape
                    .fill(color.darker(0.22))
                    .offset(y: depth)
                    .shadow(color: color.darker(0.4).opacity(0.25), radius: 6, y: depth + 2)
            )
            .padding(.bottom, depth)
    }
}

struct CandyButtonStyle: ButtonStyle {
    var color: Color
    var radius: CGFloat = 24
    var depth: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .candy(color, radius: radius, depth: depth, pressed: configuration.isPressed)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Bubble-letter title

struct BubbleTitle: View {
    let text: String
    var size: CGFloat = 48
    var colors: [Color] = [Theme.blue, Theme.pink, Theme.yellow, Theme.green, Theme.purple, Theme.orange]

    var body: some View {
        HStack(spacing: -size * 0.04) {
            ForEach(Array(text.enumerated()), id: \.offset) { i, ch in
                if ch == " " {
                    Spacer().frame(width: size * 0.3)
                } else {
                    BubbleLetter(letter: String(ch), color: colors[i % colors.count], size: size)
                        .rotationEffect(.degrees(i.isMultiple(of: 2) ? -4 : 4))
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
    }
}

private struct BubbleLetter: View {
    let letter: String
    let color: Color
    let size: CGFloat

    var body: some View {
        let font = Font.system(size: size, weight: .black, design: .rounded)
        let o = size * 0.07
        ZStack {
            // White outline made from offset copies
            ForEach(0..<8, id: \.self) { k in
                let a = Double(k) * .pi / 4
                Text(letter).font(font).foregroundStyle(.white)
                    .offset(x: CGFloat(cos(a)) * o, y: CGFloat(sin(a)) * o)
            }
            Text(letter).font(font)
                .foregroundStyle(LinearGradient(colors: [color.lighter(0.2), color.darker(0.08)], startPoint: .top, endPoint: .bottom))
        }
        .shadow(color: Theme.ink.opacity(0.18), radius: 0, x: 0, y: size * 0.06)
    }
}

// MARK: - Confetti

struct ConfettiBurst: View {
    let trigger: Int
    var count = 26

    @State private var bursts: [Burst] = []

    struct Piece: Identifiable {
        let id = UUID()
        let color: Color
        let end: CGSize
        let spin: Double
        let size: CGFloat
        let kind: Int
    }

    struct Burst: Identifiable {
        let id = UUID()
        let pieces: [Piece]
    }

    var body: some View {
        ZStack {
            ForEach(bursts) { burst in
                ForEach(burst.pieces) { ConfettiPiece(piece: $0) }
            }
        }
        .allowsHitTesting(false)
        .onChange(of: trigger) { _, _ in fire() }
        .accessibilityHidden(true)
    }

    private func fire() {
        let palette = [Theme.pink, Theme.yellow, Theme.blue, Theme.green, Theme.purple, Theme.orange]
        let pieces = (0..<count).map { _ -> Piece in
            let angle = Double.random(in: 0..<(2 * .pi))
            let dist = CGFloat.random(in: 90...220)
            return Piece(
                color: palette.randomElement() ?? Theme.pink,
                end: CGSize(width: CGFloat(cos(angle)) * dist, height: CGFloat(sin(angle)) * dist + 80),
                spin: Double.random(in: -360...360),
                size: CGFloat.random(in: 8...14),
                kind: Int.random(in: 0...2))
        }
        let burst = Burst(pieces: pieces)
        bursts.append(burst)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            bursts.removeAll { $0.id == burst.id }
        }
    }
}

private struct ConfettiPiece: View {
    let piece: ConfettiBurst.Piece
    @State private var go = false

    var body: some View {
        shape
            .frame(width: piece.size, height: piece.kind == 0 ? piece.size * 0.55 : piece.size)
            .rotationEffect(.degrees(go ? piece.spin : 0))
            .offset(go ? piece.end : .zero)
            .animation(.easeOut(duration: 1.1), value: go)
            .opacity(go ? 0 : 1)
            .animation(.easeIn(duration: 0.7).delay(0.6), value: go)
            .onAppear { go = true }
    }

    @ViewBuilder
    private var shape: some View {
        switch piece.kind {
        case 0: RoundedRectangle(cornerRadius: 2).fill(piece.color)
        case 1: Circle().fill(piece.color)
        default: SparkleShape().fill(piece.color)
        }
    }
}

// MARK: - Kawaii face (for shapes and stickers)

struct KawaiiFace: View {
    var size: CGFloat = 60
    var color: Color = Color(red: 0.22, green: 0.16, blue: 0.20)

    var body: some View {
        VStack(spacing: size * 0.08) {
            HStack(spacing: size * 0.42) {
                eye
                eye
            }
            ZStack {
                HStack(spacing: size * 0.62) {
                    Ellipse().fill(Color(red: 1, green: 0.5, blue: 0.6).opacity(0.55))
                        .frame(width: size * 0.2, height: size * 0.12)
                    Ellipse().fill(Color(red: 1, green: 0.5, blue: 0.6).opacity(0.55))
                        .frame(width: size * 0.2, height: size * 0.12)
                }
                SmileShape()
                    .stroke(color, style: StrokeStyle(lineWidth: max(2, size * 0.05), lineCap: .round))
                    .frame(width: size * 0.22, height: size * 0.1)
            }
        }
        .accessibilityHidden(true)
    }

    private var eye: some View {
        Ellipse().fill(color)
            .frame(width: size * 0.13, height: size * 0.17)
            .overlay(alignment: .topLeading) {
                Circle().fill(.white).frame(width: size * 0.055).offset(x: size * 0.02, y: size * 0.025)
            }
    }
}

struct SmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.midX, y: rect.maxY * 2))
        return p
    }
}

// MARK: - Speech bubble with Pip

struct MascotBubble: View {
    let text: String
    var mood: PipMood = .happy
    var pipSize: CGFloat = 76

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            PipView(mood: mood, size: pipSize)
            Text(text)
                .font(.kid(19, .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    BubbleShape()
                        .fill(.white)
                        .shadow(color: Theme.ink.opacity(0.10), radius: 8, y: 4)
                )
                .fixedSize(horizontal: false, vertical: true)
                .id(text)
                .transition(.scale(scale: 0.85, anchor: .leading).combined(with: .opacity))
            Spacer(minLength: 0)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: text)
    }
}

/// Rounded bubble with a little tail pointing left at Pip.
struct BubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r: CGFloat = 20
        var p = Path(roundedRect: rect, cornerRadius: r, style: .continuous)
        let tailY = rect.midY
        var tail = Path()
        tail.move(to: CGPoint(x: rect.minX + 1, y: tailY - 9))
        tail.addLine(to: CGPoint(x: rect.minX - 10, y: tailY + 2))
        tail.addLine(to: CGPoint(x: rect.minX + 1, y: tailY + 9))
        tail.closeSubpath()
        p.addPath(tail)
        return p
    }
}

// MARK: - Skill icon (artwork when available, emoji otherwise)

extension Skill {
    var iconAssetName: String {
        switch self {
        case .counting: return "icon_counting"
        case .compare: return "icon_compare"
        case .addition: return "icon_addition"
        case .subtraction: return "icon_subtraction"
        case .makeTen: return "icon_numberbonds"
        case .shapes: return "icon_shapes"
        case .patterns: return "icon_patterns"
        case .skipCounting: return "icon_skipcounting"
        case .tensOnes: return "icon_tensones"
        case .time: return "icon_time"
        }
    }
}

struct SkillIcon: View {
    let skill: Skill
    var size: CGFloat

    var body: some View {
        if let art = UIImage(named: skill.iconAssetName) {
            Image(uiImage: art)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        } else {
            Text(skill.emoji)
                .font(.system(size: size * 0.6))
                .frame(width: size, height: size)
                .background(Circle().fill(.white))
                .overlay(Circle().stroke(skill.color.lighter(0.25), lineWidth: max(3, size * 0.05)))
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Wooden sign (title plaques)

struct WoodSign: View {
    let text: String
    var size: CGFloat = 28

    static let wood = Color(red: 0.97, green: 0.80, blue: 0.55)
    static let woodDark = Color(red: 0.90, green: 0.66, blue: 0.40)
    static let outline = Color(red: 0.47, green: 0.29, blue: 0.17)
    static let ink = Color(red: 0.36, green: 0.20, blue: 0.12)

    var body: some View {
        Text(text)
            .font(.kid(size, .black))
            .foregroundStyle(Self.ink)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.6)
            .padding(.horizontal, 26)
            .padding(.vertical, 10)
            .background(WoodPlank())
            .accessibilityAddTraits(.isHeader)
    }
}

struct WoodPlank: View {
    var radius: CGFloat = 18

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        ZStack {
            shape.fill(WoodSign.outline.opacity(0.85)).offset(y: 5)
            shape.fill(LinearGradient(colors: [WoodSign.wood, WoodSign.woodDark], startPoint: .top, endPoint: .bottom))
            GeometryReader { geo in
                // Wood grain
                Capsule().fill(WoodSign.outline.opacity(0.14))
                    .frame(width: geo.size.width * 0.34, height: 3)
                    .position(x: geo.size.width * 0.24, y: geo.size.height * 0.32)
                Capsule().fill(WoodSign.outline.opacity(0.12))
                    .frame(width: geo.size.width * 0.28, height: 3)
                    .position(x: geo.size.width * 0.74, y: geo.size.height * 0.72)
                Capsule().fill(.white.opacity(0.35))
                    .frame(width: geo.size.width * 0.5, height: 4)
                    .position(x: geo.size.width * 0.5, y: 7)
            }
            .clipShape(shape)
            shape.stroke(WoodSign.outline, lineWidth: 4)
        }
    }
}
