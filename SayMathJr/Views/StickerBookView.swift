import SwiftUI

struct StickerBookView: View {
    @EnvironmentObject private var store: ProgressStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 18) {
                        MascotBubble(text: store.unlockedStickerCount >= ProgressStore.stickers.count
                            ? "You collected every sticker! Amazing!"
                            : "Earn \(store.starsToNextSticker) more ⭐ for a new sticker!")
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), spacing: 12)], spacing: 12) {
                            ForEach(Array(ProgressStore.stickers.enumerated()), id: \.offset) { i, sticker in
                                let unlocked = i < store.unlockedStickerCount
                                ZStack {
                                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                                        .fill(unlocked ? Color.white : Theme.ink.opacity(0.08))
                                    if unlocked {
                                        Text(sticker).font(.system(size: 50))
                                    } else {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 26, weight: .bold))
                                            .foregroundStyle(Theme.ink.opacity(0.3))
                                    }
                                }
                                .frame(height: 90)
                                .accessibilityLabel(unlocked ? "Sticker \(sticker)" : "Locked sticker")
                            }
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: 760)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Sticker Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.font(.kid(17, .bold))
                }
            }
        }
    }
}
