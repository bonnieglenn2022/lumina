import SwiftUI

/// Celebration shown only on milestone days (7, 30, 100, 365) so it stays special.
struct MilestoneView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    let days: Int
    @State private var shareImage: Image?

    private var message: String {
        switch days {
        case 7: return "One full week of showing up for yourself."
        case 30: return "A month of intention. This is becoming who you are."
        case 100: return "One hundred days. Your words are taking root."
        default: return "A whole year of daily practice. Remarkable."
        }
    }

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 22) {
                Spacer()
                ZStack {
                    ConfettiBurst()
                    Circle()
                        .fill(Theme.glowSoft)
                        .frame(width: 170, height: 170)
                    VStack(spacing: 0) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(Theme.glow)
                        Text("\(days)")
                            .font(Theme.display(56, weight: .bold))
                            .foregroundStyle(Theme.ink)
                        Text("day streak")
                            .font(Theme.text(15, weight: .medium))
                            .foregroundStyle(Theme.secondary)
                    }
                }
                Text(message)
                    .font(Theme.serif(26))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Label("You earned a streak freeze", systemImage: "snowflake")
                    .font(Theme.text(14, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(Capsule().fill(Theme.accentSoft))
                Spacer()
                if let shareImage {
                    ShareLink(item: shareImage, preview: SharePreview("My \(days)-day streak on Lumina", image: shareImage)) {
                        Label("Share my milestone", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                Button("Continue") { dismiss() }
                    .buttonStyle(QuietButtonStyle())
            }
            .padding(24)
        }
        .sensoryFeedback(.success, trigger: days)
        .onAppear {
            SoundManager.shared.playChime(enabled: appState.data.soundsOn)
            let renderer = ImageRenderer(content: ShareCardView(days: days, affirmation: appState.today.text, theme: appState.theme))
            renderer.scale = 3
            if let ui = renderer.uiImage { shareImage = Image(uiImage: ui) }
        }
    }
}

/// Square card designed for Instagram Stories and Messages.
struct ShareCardView: View {
    let days: Int
    let affirmation: String
    let theme: CardTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundStyle(Theme.glow)
                Text("\(days)-day streak")
                    .font(Theme.text(16, weight: .semibold))
                    .foregroundStyle(theme.textColor)
            }
            Spacer()
            Text(affirmation)
                .font(Theme.serif(28))
                .foregroundStyle(theme.textColor)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "sparkle")
                Text("Lumina")
            }
            .font(Theme.text(14, weight: .semibold))
            .foregroundStyle(theme.secondaryTextColor)
        }
        .padding(28)
        .frame(width: 360, height: 360, alignment: .leading)
        .background(theme.id == "classic"
                    ? AnyView(Color(hex: 0xF6F1E7))
                    : AnyView(ThemeBackground(theme: theme)))
        .environment(\.colorScheme, .light)
    }
}
