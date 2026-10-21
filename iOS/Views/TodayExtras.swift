import SwiftUI

/// One-tap mood check-in shown on Today after "I receive this".
struct MoodCheckInCard: View {
    @EnvironmentObject private var appState: AppState
    @State private var chosen: Int?

    private let levels: [(Int, String, String)] = [
        (1, "cloud.rain", "Low"),
        (2, "cloud", "Uneasy"),
        (3, "cloud.sun", "Okay"),
        (4, "sun.min", "Good"),
        (5, "sun.max", "Great")
    ]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 14) {
                Text(chosen == nil ? "How are you feeling right now?" : "Thanks for checking in.")
                    .font(Theme.text(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                HStack(spacing: 6) {
                    ForEach(levels, id: \.0) { level, symbol, label in
                        Button {
                            withAnimation(.snappy) { chosen = level }
                            appState.logMood(level)
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: symbol)
                                    .font(.system(size: 20))
                                    .foregroundStyle(chosen == level ? Theme.onAccent : Theme.accent)
                                    .frame(width: 46, height: 46)
                                    .background(Circle().fill(chosen == level ? Theme.accent : Theme.accentSoft))
                                Text(label)
                                    .font(Theme.text(12))
                                    .foregroundStyle(Theme.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .disabled(chosen != nil)
                        .accessibilityLabel(label)
                    }
                }
                .sensoryFeedback(.selection, trigger: chosen)
                if appState.data.healthEnabled {
                    Label("Saved to Apple Health", systemImage: "heart.text.square")
                        .font(Theme.text(12))
                        .foregroundStyle(Theme.secondary)
                        .opacity(chosen == nil ? 0 : 1)
                }
            }
        }
    }
}

/// Entry card for breathing (daytime) or wind-down (evening).
struct PracticeCard: View {
    let evening: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: evening ? "moon.stars.fill" : "wind")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(evening ? Color(hex: 0xF3D27A) : Theme.accent)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(evening ? .white.opacity(0.10) : Theme.accentSoft))
                VStack(alignment: .leading, spacing: 2) {
                    Text(evening ? "Wind down" : "Breathe & repeat")
                        .font(Theme.text(17, weight: .semibold))
                        .foregroundStyle(evening ? Theme.cream : Theme.ink)
                    Text(evening ? "5 min · soundscape · today's words" : "1 min · 4 in, 6 out")
                        .font(Theme.text(13))
                        .foregroundStyle(evening ? Theme.cream.opacity(0.65) : Theme.secondary)
                }
                Spacer()
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(evening ? Theme.cream : Theme.accent)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(evening ? AnyShapeStyle(LinearGradient(colors: [Color(hex: 0x23366B), Theme.navy],
                                                            startPoint: .topLeading, endPoint: .bottomTrailing))
                              : AnyShapeStyle(Theme.surface)))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(Theme.hairline, lineWidth: evening ? 0 : 0.5))
        }
        .buttonStyle(.plain)
    }
}

/// Promotes the Lock Screen / Home Screen widget, the habit tool that drives retention.
struct WidgetTipCard: View {
    let open: () -> Void
    let dismiss: () -> Void

    var body: some View {
        Card(fill: Theme.accentSoft) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "lock.rectangle.on.rectangle")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 6) {
                    Text("See today's words every time you pick up your phone")
                        .font(Theme.text(15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Button("Add the Lumina widget", action: open)
                        .font(Theme.text(14, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                }
                Spacer()
                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Theme.secondary)
                }
                .accessibilityLabel("Dismiss")
            }
        }
    }
}

/// Step-by-step guide for adding widgets.
struct WidgetGuideView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var lockScreen = true

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView {
                    VStack(spacing: 22) {
                        Picker("Where", selection: $lockScreen) {
                            Text("Lock Screen").tag(true)
                            Text("Home Screen").tag(false)
                        }
                        .pickerStyle(.segmented)

                        preview

                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(Array(steps.enumerated()), id: \.offset) { i, step in
                                HStack(alignment: .top, spacing: 14) {
                                    Text("\(i + 1)")
                                        .font(Theme.text(14, weight: .bold))
                                        .foregroundStyle(Theme.onAccent)
                                        .frame(width: 28, height: 28)
                                        .background(Circle().fill(Theme.accent))
                                    Text(step)
                                        .font(Theme.text(16))
                                        .foregroundStyle(Theme.ink)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add a Widget")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        appState.data.widgetTipDismissed = true
                        dismiss()
                    }
                }
            }
        }
    }

    private var steps: [String] {
        lockScreen
            ? ["Lock your iPhone, then touch and hold the Lock Screen.",
               "Tap Customize, then tap the Lock Screen.",
               "Tap the widget area under the time and choose Lumina.",
               "Tap Done. Today's words now greet you every time you look."]
            : ["Touch and hold an empty spot on your Home Screen.",
               "Tap Edit in the top corner, then Add Widget.",
               "Search for Lumina and pick a size.",
               "Tap Add Widget, then Done."]
    }

    private var preview: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0x3B5BA5), Color(hex: 0x0F1626)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(height: 230)
            if lockScreen {
                VStack(spacing: 6) {
                    Text(Date.now, format: .dateTime.weekday(.wide).month().day())
                        .font(Theme.text(15, weight: .medium))
                    Text(Date.now, format: .dateTime.hour().minute())
                        .font(.system(size: 64, weight: .semibold, design: .rounded))
                    VStack(alignment: .leading, spacing: 2) {
                        Label("Lumina", systemImage: "sparkle").font(Theme.text(12, weight: .semibold))
                        Text(appState.today.text).font(Theme.text(13)).lineLimit(2)
                    }
                    .padding(10)
                    .frame(width: 210, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.15)))
                }
                .foregroundStyle(.white)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "sparkle").foregroundStyle(appState.theme.chipForeground)
                    Spacer(minLength: 0)
                    Text(appState.today.text)
                        .font(Theme.serif(15))
                        .foregroundStyle(appState.theme.textColor)
                        .lineLimit(5)
                }
                .padding(14)
                .frame(width: 160, height: 160, alignment: .topLeading)
                .background(ThemeBackground(theme: appState.theme))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            }
        }
        .accessibilityHidden(true)
    }
}
