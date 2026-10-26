import SwiftUI

struct MyManifestationsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @State private var showCompose = false
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 32) {
                        writtenByYou
                        favoritesSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Mine")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: newTapped) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Theme.bg)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Theme.ink))
                    }
                    .accessibilityLabel("Write a manifestation")
                }
            }
            .sheet(isPresented: $showCompose) { ComposeView() }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var writtenByYou: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(text: "Written by you")
                Spacer()
                if !appState.isPremium {
                    Text("\(appState.data.custom.count) of \(AppConfig.freeCustomLimit)")
                        .font(Theme.text(13))
                        .foregroundStyle(Theme.secondary)
                        .monospacedDigit()
                }
            }
            if appState.data.custom.isEmpty {
                Card(padding: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Theme.accent)
                            .padding(.bottom, 6)
                        Text("Your words carry the most power")
                            .font(Theme.text(18, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        Text("Write a manifestation in your own voice. It joins your daily rotation and reminders.")
                            .font(Theme.text(15))
                            .foregroundStyle(Theme.secondary)
                        Button("Write your first", action: newTapped)
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.top, 12)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    ForEach(appState.data.custom) { item in row(item, deletable: true) }
                }
            }
        }
    }

    private var favoritesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionTitle(text: "Favorites")
            if appState.favorites.isEmpty {
                Text("Tap the heart on any manifestation to save it here. Favorites also appear on your Apple Watch.")
                    .font(Theme.text(15))
                    .foregroundStyle(Theme.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach(appState.favorites) { item in row(item, deletable: false) }
                }
            }
        }
    }

    private func row(_ item: Affirmation, deletable: Bool) -> some View {
        Card(padding: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.text)
                        .font(Theme.text(17, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if !item.isCustom {
                        Text(item.categoryTitle)
                            .font(Theme.text(13))
                            .foregroundStyle(Theme.secondary)
                    }
                }
                Spacer()
                Button {
                    withAnimation(.snappy) { appState.toggleFavorite(item) }
                } label: {
                    Image(systemName: appState.isFavorite(item) ? "heart.fill" : "heart")
                        .foregroundStyle(appState.isFavorite(item) ? Theme.accent : Theme.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .contextMenu {
            ShareLink(item: item.text)
            if deletable {
                Button(role: .destructive) {
                    withAnimation { appState.deleteCustom(item) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private func newTapped() {
        if appState.canAddCustom { showCompose = true } else { showPaywall = true }
    }
}

struct ComposeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var text = ""
    @FocusState private var focused: Bool

    private let starters = ["I am ", "I have ", "I attract ", "I am grateful for ", "I deserve "]

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                VStack(alignment: .leading, spacing: 16) {
                    Text("Write it as if it's already true.")
                        .font(Theme.text(15))
                        .foregroundStyle(Theme.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(starters, id: \.self) { starter in
                                Button(starter.trimmingCharacters(in: .whitespaces) + "…") {
                                    text = starter
                                    focused = true
                                }
                                .font(Theme.text(14, weight: .medium))
                                .foregroundStyle(Theme.ink)
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(Capsule().fill(Theme.surface))
                                .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 0.5))
                            }
                        }
                    }

                    ZStack(alignment: .topLeading) {
                        if text.isEmpty {
                            Text("I am ready to receive…")
                                .font(Theme.display(24, weight: .semibold))
                                .foregroundStyle(Theme.secondary.opacity(0.6))
                                .padding(.top, 8).padding(.leading, 5)
                        }
                        TextEditor(text: $text)
                            .font(Theme.display(24, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                            .scrollContentBackground(.hidden)
                            .focused($focused)
                            .onChange(of: text) { _, value in
                                if value.count > AppConfig.maxManifestationLength {
                                    text = String(value.prefix(AppConfig.maxManifestationLength))
                                }
                            }
                    }
                    .frame(minHeight: 180)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Theme.surface))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 0.5))

                    Text("\(text.count)/\(AppConfig.maxManifestationLength)")
                        .font(Theme.text(12))
                        .foregroundStyle(Theme.secondary)
                        .monospacedDigit()
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    Spacer()

                    Button("Save") {
                        appState.addCustom(text)
                        dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(20)
            }
            .navigationTitle("New Manifestation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }
}
