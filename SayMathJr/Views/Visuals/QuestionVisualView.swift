import SwiftUI

/// Renders the picture part of a question.
struct QuestionVisualView: View {
    let visual: QuestionVisual

    var body: some View {
        switch visual {
        case .empty:
            EmptyView()
        case .equation(let text):
            Text(text)
                .font(.kid(56, .heavy))
                .foregroundStyle(Theme.ink)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        case .objects(let emoji, let count):
            ObjectsGrid(emoji: emoji, count: count)
        case .addition(let emoji, let a, let b):
            HStack(spacing: 10) {
                ObjectsGrid(emoji: emoji, count: a, columns: min(max(a, 1), 3), compact: true)
                Text("+").font(.kid(44, .heavy)).foregroundStyle(Theme.green)
                ObjectsGrid(emoji: emoji, count: b, columns: min(max(b, 1), 3), compact: true)
            }
        case .subtraction(let emoji, let total, let take):
            ObjectsGrid(emoji: emoji, count: total, crossedFromEnd: take)
        case .numberBond(let whole, let part):
            NumberBondView(whole: whole, part: part)
        case .shape(let kind):
            ShapeFigure(kind: kind)
        case .sequence(let items):
            SequenceRow(items: items)
        case .tensOnes(let tens, let ones):
            TensOnesView(tens: tens, ones: ones)
        case .clock(let hour, let minute):
            ClockFace(hour: hour, minute: minute)
                .frame(width: 210, height: 210)
        }
    }
}

/// Objects laid out in rows of five (like a ten-frame) so they're easy to count.
struct ObjectsGrid: View {
    let emoji: String
    let count: Int
    var columns: Int = 5
    var crossedFromEnd: Int = 0
    var compact = false

    private var itemSize: CGFloat { compact || count > 10 ? 28 : 36 }

    var body: some View {
        let cell = itemSize + 12
        let cols = Array(repeating: GridItem(.fixed(cell), spacing: 4), count: max(1, min(columns, max(count, 1))))
        LazyVGrid(columns: cols, spacing: 5) {
            ForEach(0..<count, id: \.self) { i in
                let crossed = i >= count - crossedFromEnd
                Text(emoji)
                    .font(.system(size: itemSize))
                    .frame(width: cell, height: cell)
                    .background(Circle().fill(.white))
                    .overlay(Circle().stroke(Theme.sky, lineWidth: 2))
                    .opacity(crossed ? 0.4 : 1)
                    .overlay {
                        if crossed {
                            Image(systemName: "xmark")
                                .font(.system(size: itemSize * 0.95, weight: .black))
                                .foregroundStyle(Theme.red)
                        }
                    }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(count) items")
    }
}

/// Part–part–whole diagram: the whole on top, two parts below (one unknown).
struct NumberBondView: View {
    let whole: Int
    let part: Int

    var body: some View {
        ZStack {
            Path { p in
                p.move(to: CGPoint(x: 110, y: 50))
                p.addLine(to: CGPoint(x: 50, y: 140))
                p.move(to: CGPoint(x: 110, y: 50))
                p.addLine(to: CGPoint(x: 170, y: 140))
            }
            .stroke(Theme.ink.opacity(0.5), style: StrokeStyle(lineWidth: 5, lineCap: .round))

            bubble("\(whole)", Theme.blue).position(x: 110, y: 50)
            bubble("\(part)", Theme.green).position(x: 50, y: 140)
            bubble("?", Theme.pink).position(x: 170, y: 140)
        }
        .frame(width: 220, height: 190)
    }

    private func bubble(_ text: String, _ color: Color) -> some View {
        Text(text)
            .font(.kid(30, .heavy))
            .foregroundStyle(.white)
            .frame(width: 76, height: 76)
            .background(Circle().fill(color.gradient))
            .overlay(Circle().stroke(.white, lineWidth: 4))
            .shadow(color: Theme.ink.opacity(0.15), radius: 4, y: 2)
    }
}

/// A row of pattern or number tiles; "?" is highlighted.
struct SequenceRow: View {
    let items: [String]

    var body: some View {
        let isNumbers = items.contains { Int($0) != nil }
        let size: CGFloat = isNumbers ? 62 : 46
        LazyVGrid(columns: [GridItem(.adaptive(minimum: size, maximum: size + 10), spacing: 8)], spacing: 8) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Text(item)
                    .font(item == "?" || isNumbers ? Font.kid(isNumbers ? 24 : 30, .heavy) : Font.system(size: 32))
                    .foregroundStyle(item == "?" ? .white : Theme.ink)
                    .minimumScaleFactor(0.5)
                    .frame(width: size, height: size)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(item == "?" ? AnyShapeStyle(Theme.pink.gradient) : AnyShapeStyle(Theme.sky))
                    )
            }
        }
        .padding(.horizontal, 4)
    }
}

/// Base-ten blocks: tall rods of ten and small single cubes.
struct TensOnesView: View {
    let tens: Int
    let ones: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 18) {
            HStack(alignment: .bottom, spacing: 5) {
                ForEach(0..<tens, id: \.self) { _ in rod }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(16), spacing: 3), count: 3), spacing: 3) {
                ForEach(0..<ones, id: \.self) { _ in cube(Theme.orange) }
            }
            .frame(width: 60)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tens) tens and \(ones) ones")
    }

    private var rod: some View {
        VStack(spacing: 1) {
            ForEach(0..<10, id: \.self) { _ in cube(Theme.blue) }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 4).fill(Theme.ink.opacity(0.25)))
    }

    private func cube(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(color)
            .frame(width: 16, height: 16)
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Theme.ink.opacity(0.35), lineWidth: 1))
    }
}

/// Analog clock with numbers, an hour hand and a minute hand.
struct ClockFace: View {
    let hour: Int
    let minute: Int

    var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let r = size / 2
            ZStack {
                Circle().fill(.white)
                Circle().stroke(Theme.blue, lineWidth: 8)

                ForEach(0..<60, id: \.self) { tick in
                    Rectangle()
                        .fill(Theme.ink.opacity(tick % 5 == 0 ? 0.6 : 0.2))
                        .frame(width: tick % 5 == 0 ? 3 : 1.5, height: tick % 5 == 0 ? 10 : 5)
                        .offset(y: -r + 14)
                        .rotationEffect(.degrees(Double(tick) * 6))
                }

                ForEach(1...12, id: \.self) { n in
                    let angle = Double(n) * 30 * .pi / 180
                    Text("\(n)")
                        .font(.kid(size * 0.1, .heavy))
                        .foregroundStyle(Theme.ink)
                        .position(
                            x: r + CGFloat(sin(angle)) * r * 0.72,
                            y: r - CGFloat(cos(angle)) * r * 0.72)
                }

                // Hour hand (short, thick)
                hand(length: r * 0.45, width: 9, color: Theme.ink)
                    .rotationEffect(.degrees(Double(hour % 12) * 30 + Double(minute) * 0.5))
                // Minute hand (long, thin)
                hand(length: r * 0.7, width: 5, color: Theme.pink)
                    .rotationEffect(.degrees(Double(minute) * 6))

                Circle().fill(Theme.ink).frame(width: 14, height: 14)
            }
            .frame(width: size, height: size)
        }
        .accessibilityLabel("Clock")
    }

    private func hand(length: CGFloat, width: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2)
    }
}
