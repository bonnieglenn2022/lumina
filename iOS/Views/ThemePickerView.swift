import SwiftUI

struct ThemePickerView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your theme appears on Today and your home-screen widget.")
                            .font(Theme.text(15))
                            .foregroundStyle(Theme.secondary)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(CardTheme.all) { theme in
                                let locked = !theme.isFree && !appState.isPremium
                                Button {
                                    if locked { showPaywall = true } else { appState.data.themeID = theme.id }
                                } label: {
                                    tile(theme, selected: appState.theme.id == theme.id, locked: locked)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("\(theme.name)\(locked ? ", Premium" : "")")
                            }
                        }
                        .sensoryFeedback(.selection, trigger: appState.data.themeID)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Card Theme")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Done") { dismiss() } }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
        .presentationDetents([.medium, .large])
    }

    private func tile(_ theme: CardTheme, selected: Bool, locked: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                ThemeBackground(theme: theme)
                    .frame(height: 110)
                    .overlay(
                        Text("Aa")
                            .font(Theme.serif(26))
                            .foregroundStyle(theme.textColor)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(selected ? Theme.accent : Theme.hairline, lineWidth: selected ? 2.5 : 0.5))
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(theme.textColor)
                        .padding(6)
                        .background(Circle().fill(theme.chipBackground))
                        .padding(8)
                }
            }
            Text(theme.name)
                .font(Theme.text(13, weight: selected ? .semibold : .regular))
                .foregroundStyle(Theme.ink)
        }
    }
}
