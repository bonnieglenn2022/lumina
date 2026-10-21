import SwiftUI

// MARK: Buttons

/// Moonlit-blue pill button.
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration)
    }

    private struct PrimaryButtonBody: View {
        let configuration: ButtonStyleConfiguration
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(Theme.text(17, weight: .semibold))
                .foregroundStyle(Theme.onAccent)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(Theme.accent))
                .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.35)
                .scaleEffect(configuration.isPressed ? 0.985 : 1)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
    }
}

struct QuietButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.text(15, weight: .medium))
            .foregroundStyle(Theme.secondary)
            .padding(.vertical, 10)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

// MARK: Surfaces

struct Card<Content: View>: View {
    var padding: CGFloat = 20
    var fill: Color = Theme.surface
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(fill))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(Theme.hairline, lineWidth: 0.5))
    }
}

struct CategoryChip: View {
    let title: String
    let symbol: String
    var foreground: Color = Theme.accent
    var background: Color = Theme.accentSoft

    var body: some View {
        Label(title, systemImage: symbol)
            .font(Theme.text(13, weight: .semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(background))
    }
}

/// The hero: today's affirmation in serif on the user's chosen theme,
/// with favorite, your-voice, share and theme actions.
struct AffirmationCard: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @ObservedObject private var voice = VoiceRecorder.shared
    let affirmation: Affirmation
    var minHeight: CGFloat = 320

    @State private var showRecorder = false
    @State private var showThemes = false
    @State private var showPaywall = false

    private var theme: CardTheme { appState.theme }
    private var hasVoice: Bool { voice.hasRecording(affirmation.id) }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            CategoryChip(title: affirmation.categoryTitle, symbol: affirmation.categorySymbol,
                         foreground: theme.chipForeground, background: theme.chipBackground)

            Text(affirmation.text)
                .font(Theme.serif(31, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(theme.textColor)
                .minimumScaleFactor(0.7)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                action(appState.isFavorite(affirmation) ? "heart.fill" : "heart",
                       label: appState.isFavorite(affirmation) ? "Remove from favorites" : "Add to favorites",
                       highlighted: appState.isFavorite(affirmation)) {
                    withAnimation(.snappy) { appState.toggleFavorite(affirmation) }
                }
                .sensoryFeedback(.selection, trigger: appState.isFavorite(affirmation))

                action(voiceSymbol, label: hasVoice ? "Play your voice" : "Record in your voice", highlighted: hasVoice) {
                    if hasVoice {
                        voice.playingID == affirmation.id ? voice.stopPlayback() : voice.play(affirmation.id)
                    } else if store.isPremium {
                        showRecorder = true
                    } else {
                        showPaywall = true
                    }
                }
                .contextMenu {
                    if hasVoice {
                        Button("Re-record", systemImage: "mic") { showRecorder = true }
                        Button("Delete recording", systemImage: "trash", role: .destructive) { voice.delete(affirmation.id) }
                    }
                }

                ShareLink(item: "\(affirmation.text)\n\n— from Lumina") {
                    iconCircle("square.and.arrow.up", highlighted: false)
                }
                .accessibilityLabel("Share")

                Spacer()

                action("paintpalette", label: "Change card theme", highlighted: false) { showThemes = true }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: minHeight, alignment: .topLeading)
        .background(ThemeBackground(theme: theme))
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(Theme.hairline, lineWidth: theme.id == "classic" ? 0.5 : 0))
        .animation(.smooth, value: theme.id)
        .sheet(isPresented: $showRecorder) { VoiceRecorderView(affirmation: affirmation) }
        .sheet(isPresented: $showThemes) { ThemePickerView() }
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private var voiceSymbol: String {
        if voice.playingID == affirmation.id { return "stop.fill" }
        return hasVoice ? "play.fill" : "mic"
    }

    private func action(_ symbol: String, label: String, highlighted: Bool, perform: @escaping () -> Void) -> some View {
        Button(action: perform) { iconCircle(symbol, highlighted: highlighted) }
            .buttonStyle(.plain)
            .accessibilityLabel(label)
    }

    private func iconCircle(_ symbol: String, highlighted: Bool) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(highlighted ? (theme.id == "classic" ? Theme.accent : theme.textColor) : theme.textColor)
            .frame(width: 42, height: 42)
            .background(Circle().fill(theme.id == "classic" ? (highlighted ? Theme.accentSoft : Theme.bg) : theme.chipBackground))
    }
}

struct CategoryTile: View {
    let category: ManifestCategory
    var isSelected = false
    var isLocked = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Image(systemName: category.symbol)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Theme.accentSoft))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.accent)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Theme.secondary)
                }
            }
            Spacer(minLength: 16)
            Text(category.title)
                .font(Theme.serif(19, weight: .medium))
                .foregroundStyle(Theme.ink)
            Text(category.subtitle)
                .font(Theme.text(13))
                .foregroundStyle(Theme.secondary)
                .lineLimit(1)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.surface))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 2 : 0.5)
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct PremiumBanner: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.cream)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Theme.brandGradient))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Try Premium free for 7 days")
                        .font(Theme.text(16, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("Themes, soundscapes, your own voice, and more")
                        .font(Theme.text(13))
                        .foregroundStyle(Theme.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondary)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.accentSoft))
        }
        .buttonStyle(.plain)
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Theme.text(15, weight: .semibold))
            .foregroundStyle(Theme.ink)
    }
}

/// A small celebratory burst used for milestones.
struct ConfettiBurst: View {
    @State private var fired = false
    private let colors: [Color] = [Theme.glow, Color(hex: 0x9DB5F0), Color(hex: 0xF3D27A), Color(hex: 0xB9C9AE)]

    var body: some View {
        ZStack {
            ForEach(0..<28, id: \.self) { i in
                let angle = Double(i) / 28 * 2 * .pi
                let distance: CGFloat = fired ? CGFloat(110 + (i % 5) * 22) : 0
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: CGFloat(6 + i % 4 * 2), height: CGFloat(6 + i % 4 * 2))
                    .offset(x: cos(angle) * distance, y: sin(angle) * distance)
                    .opacity(fired ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.4)) { fired = true }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
