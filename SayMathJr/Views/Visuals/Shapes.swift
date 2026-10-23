import SwiftUI

struct TriangleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

struct HexagonShape: Shape {
    func path(in rect: CGRect) -> Path {
        polygon(in: rect, sides: 6, startAngle: 0)
    }
}

struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.45
        var p = Path()
        for i in 0..<10 {
            let r = i.isMultiple(of: 2) ? outer : inner
            let angle = (Double(i) * 36 - 90) * .pi / 180
            let pt = CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + h * 0.3),
            control1: CGPoint(x: rect.minX + w * 0.35, y: rect.minY + h * 0.8),
            control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.55))
        p.addArc(
            center: CGPoint(x: rect.minX + w * 0.25, y: rect.minY + h * 0.3),
            radius: w * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addArc(
            center: CGPoint(x: rect.minX + w * 0.75, y: rect.minY + h * 0.3),
            radius: w * 0.25, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        p.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.55),
            control2: CGPoint(x: rect.minX + w * 0.65, y: rect.minY + h * 0.8))
        p.closeSubpath()
        return p
    }
}

private func polygon(in rect: CGRect, sides: Int, startAngle: Double) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let r = min(rect.width, rect.height) / 2
    var p = Path()
    for i in 0..<sides {
        let angle = (startAngle + Double(i) * 360 / Double(sides)) * .pi / 180
        let pt = CGPoint(x: center.x + r * CGFloat(cos(angle)), y: center.y + r * CGFloat(sin(angle)))
        if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
    }
    p.closeSubpath()
    return p
}

/// Draws one of the shapes kids learn, filled with a friendly color and outlined.
struct ShapeFigure: View {
    let kind: ShapeKind
    var size: CGFloat = 150

    var body: some View {
        Group {
            switch kind {
            case .circle:
                styled(Circle(), Theme.blue).frame(width: size, height: size)
            case .oval:
                styled(Ellipse(), Theme.teal).frame(width: size * 1.35, height: size * 0.85)
            case .square:
                styled(Rectangle(), Theme.orange).frame(width: size * 0.9, height: size * 0.9)
            case .rectangle:
                styled(Rectangle(), Theme.green).frame(width: size * 1.5, height: size * 0.8)
            case .triangle:
                styled(TriangleShape(), Theme.yellow).frame(width: size, height: size * 0.9)
            case .hexagon:
                styled(HexagonShape(), Theme.purple).frame(width: size, height: size)
            case .star:
                styled(StarShape(), Theme.yellow).frame(width: size, height: size)
            case .heart:
                styled(HeartShape(), Theme.pink).frame(width: size, height: size * 0.9)
            }
        }
        .overlay {
            KawaiiFace(size: size * faceScale)
                .offset(y: size * faceOffset)
        }
        .accessibilityLabel(kind.name)
    }

    private var faceScale: CGFloat {
        switch kind {
        case .star: return 0.32
        case .triangle: return 0.38
        default: return 0.46
        }
    }

    private var faceOffset: CGFloat {
        switch kind {
        case .triangle: return 0.16
        case .heart: return -0.04
        case .star: return 0.03
        default: return 0
        }
    }

    private func styled<S: Shape>(_ shape: S, _ color: Color) -> some View {
        shape
            .fill(color.gradient)
            .overlay(shape.stroke(Theme.ink.opacity(0.75), lineWidth: 4))
    }
}
