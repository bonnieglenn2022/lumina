import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Lumina design system (research-informed):
/// • Warm cream canvas + moonlit blue, the calm/trust pairing used by the category leaders.
/// • Evening mode = deep navy (never pure black) with cream text.
/// • Serif (Apple's New York) for the affirmation itself; SF Pro Rounded for everything else.
/// • A warm orange glow reserved for celebrations.
enum Theme {
    static let bg         = dynamic(light: 0xF6F1E7, dark: 0x0F1626)
    static let surface    = dynamic(light: 0xFFFDF8, dark: 0x18213A)
    static let ink        = dynamic(light: 0x1B2433, dark: 0xF3EEE4)
    static let secondary  = dynamic(light: 0x687080, dark: 0xA3ABBE)
    static let hairline   = dynamic(light: 0xE6DFD0, dark: 0x263150)
    static let accent     = dynamic(light: 0x2F4F8F, dark: 0x9DB5F0)
    static let accentSoft = dynamic(light: 0xE5EAF5, dark: 0x22305A)
    static let onAccent   = dynamic(light: 0xFFFDF8, dark: 0x0F1626)
    static let glow       = Color(hex: 0xE8915A)
    static let glowSoft   = dynamic(light: 0xFBE6D8, dark: 0x4A2E22)
    static let navy       = Color(hex: 0x0F1626)
    static let cream      = Color(hex: 0xF3EEE4)

    static var brandGradient: LinearGradient {
        LinearGradient(colors: [Color(hex: 0x3B5BA5), Color(hex: 0x23366B)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// The affirmation voice: elegant serif.
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Headlines: friendly rounded sans.
    static func display(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Body and UI text.
    static func text(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        #if os(iOS)
        return Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
        #else
        return Color(hex: dark)
        #endif
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

#if os(iOS)
extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
#endif

/// Plain canvas background used by every screen.
struct AppBackground: View {
    var body: some View {
        Theme.bg.ignoresSafeArea()
    }
}

/// App-icon-style mark used in onboarding and the paywall.
struct LogoMark: View {
    var size: CGFloat = 72
    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
            .fill(Theme.brandGradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "sparkle")
                    .font(.system(size: size * 0.44, weight: .semibold))
                    .foregroundStyle(Theme.cream)
            )
            .accessibilityHidden(true)
    }
}

// MARK: Card themes

/// Background themes for the affirmation card and home-screen widget.
/// Add nature photography later by giving a theme an `imageName` that exists in the asset catalog.
struct CardTheme: Identifiable, Hashable {
    let id: String
    let name: String
    let top: UInt32
    let bottom: UInt32
    let lightText: Bool
    let isFree: Bool
    var imageName: String? = nil

    static let classic = CardTheme(id: "classic", name: "Classic", top: 0, bottom: 0, lightText: false, isFree: true)

    static let all: [CardTheme] = [
        classic,
        CardTheme(id: "moonlit", name: "Moonlit", top: 0x2F4F8F, bottom: 0x1B2B52, lightText: true, isFree: true),
        CardTheme(id: "sage", name: "Sage", top: 0xDCE5D3, bottom: 0xB9C9AE, lightText: false, isFree: true),
        CardTheme(id: "seaglass", name: "Sea Glass", top: 0xD7E8E8, bottom: 0xA9CACB, lightText: false, isFree: true),
        CardTheme(id: "dawn", name: "Dawn", top: 0xF9D8C2, bottom: 0xE8A98C, lightText: false, isFree: false),
        CardTheme(id: "lavender", name: "Lavender", top: 0xE3DDF3, bottom: 0xBDB2E2, lightText: false, isFree: false),
        CardTheme(id: "dusk", name: "Dusk", top: 0x5B4B8A, bottom: 0xD9826E, lightText: true, isFree: false),
        CardTheme(id: "forest", name: "Forest", top: 0x2E4A3E, bottom: 0x1A2D25, lightText: true, isFree: false),
        CardTheme(id: "ocean", name: "Ocean", top: 0x2A6F97, bottom: 0x163F5C, lightText: true, isFree: false),
        CardTheme(id: "rose", name: "Rose", top: 0xF4D6D8, bottom: 0xE2A6AE, lightText: false, isFree: false),
        CardTheme(id: "sand", name: "Sand", top: 0xEFE3CC, bottom: 0xD9C29B, lightText: false, isFree: false),
        CardTheme(id: "midnight", name: "Midnight", top: 0x151B2E, bottom: 0x2B2F57, lightText: true, isFree: false)
    ]

    static func with(id: String) -> CardTheme { all.first { $0.id == id } ?? classic }

    var textColor: Color {
        if id == "classic" { return Theme.ink }
        return lightText ? Theme.cream : Color(hex: 0x1B2433)
    }

    var secondaryTextColor: Color {
        if id == "classic" { return Theme.secondary }
        return textColor.opacity(0.7)
    }

    var chipBackground: Color {
        if id == "classic" { return Theme.accentSoft }
        return lightText ? .white.opacity(0.16) : .white.opacity(0.45)
    }

    var chipForeground: Color {
        id == "classic" ? Theme.accent : textColor
    }
}

struct ThemeBackground: View {
    let theme: CardTheme

    var body: some View {
        if let imageName = theme.imageName {
            Image(imageName).resizable().scaledToFill()
                .overlay(Color.black.opacity(theme.lightText ? 0.25 : 0))
        } else if theme.id == "classic" {
            Theme.surface
        } else {
            LinearGradient(colors: [Color(hex: theme.top), Color(hex: theme.bottom)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
