import SwiftUI

struct StickerBookView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    private let tileColors = [Theme.pink, Theme.blue, Theme.yellow, Theme.green, Theme.purple, Theme.orange]

    var body: some View {
        NavigationStack {
            ZStack {
                SceneBackground(showHills: false)
                ScrollView {
                    VStack(spacing: 18) {
                        BubbleTitle(text: "Stickers", size: 40)
                            .padding(.top, 4)
                        MascotBubble(
                            text: store.unlockedStickerCount >= ProgressStore.stickers.count
                                ? "You collected every sticker! Amazing!"
                                : "Earn \(store.starsToNextSticker) more ⭐ for a new sticker!",
                            mood: .happy)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 12)], spacing: 10) {
                            ForEach(Array(ProgressStore.stickers.enumerated()), id: \.offset) { i, sticker in
                                let unlocked = i < store.unlockedStickerCount
                                ZStack {
                                    if unlocked {
                                        Text(sticker)
                                            .font(.system(size: 46))
                                            .padding(6)
                                            .background(Circle().fill(.white))
                                            .rotationEffect(.degrees(Double((i * 37) % 21) - 10))
                                    } else {
                                        Image(systemName: "questionmark")
                                            .font(.system(size: 26, weight: .black, design: .rounded))
                                            .foregroundStyle(Theme.purple.lighter(0.45))
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 86)
                                .candy(unlocked ? tileColors[i % tileColors.count].lighter(0.55) : Theme.purple.lighter(0.86),
                                       radius: 22, depth: 5)
                                .accessibilityLabel(unlocked ? "Sticker \(sticker)" : "Locked sticker")
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(.kid(17, .bold))
                }
            }
        }
    }
}
