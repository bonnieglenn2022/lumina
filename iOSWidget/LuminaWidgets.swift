import WidgetKit
import SwiftUI

/// iPhone Home Screen + Lock Screen widgets showing today's manifestation.
struct LuminaEntry: TimelineEntry {
    let date: Date
    let text: String
    let category: String
    let streak: Int
    let checkedIn: Bool
    let theme: CardTheme
}

struct LuminaProvider: TimelineProvider {
    func placeholder(in context: Context) -> LuminaEntry {
        LuminaEntry(date: .now, text: "I am a magnet for wonderful opportunities.",
                    category: "Abundance", streak: 5, checkedIn: false, theme: .classic)
    }

    func getSnapshot(in context: Context, completion: @escaping (LuminaEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry(for: .now))
    }

    /// One entry per day so the widget rolls over at midnight on its own.
    func getTimeline(in context: Context, completion: @escaping (Timeline<LuminaEntry>) -> Void) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        var entries = [entry(for: .now)]
        for offset in 1...6 {
            if let day = cal.date(byAdding: .day, value: offset, to: start) {
                entries.append(entry(for: day))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(for date: Date) -> LuminaEntry {
        let snapshot = WatchSnapshot.load()
        let item = snapshot.item(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        return LuminaEntry(date: date,
                           text: item.text,
                           category: item.category,
                           streak: isToday ? snapshot.streak : 0,
                           checkedIn: isToday && snapshot.checkedInDay == DailyPicker.dayNumber(for: date),
                           theme: CardTheme.with(id: snapshot.themeID))
    }
}

// MARK: Home Screen

struct HomeWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LuminaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "sparkle")
                Text(family == .systemSmall ? "Today" : entry.category)
                Spacer()
                if entry.streak > 0 {
                    Image(systemName: entry.checkedIn ? "checkmark.circle.fill" : "flame.fill")
                        .foregroundStyle(entry.checkedIn ? entry.theme.chipForeground : Theme.glow)
                    Text("\(entry.streak)")
                }
            }
            .font(Theme.text(12, weight: .semibold))
            .foregroundStyle(entry.theme.chipForeground)

            Spacer(minLength: 0)

            Text(entry.text)
                .font(Theme.serif(family == .systemSmall ? 16 : 20))
                .foregroundStyle(entry.theme.textColor)
                .lineLimit(family == .systemSmall ? 5 : 4)
                .minimumScaleFactor(0.8)
        }
        .widgetURL(URL(string: "lumina://today"))
    }
}

struct LuminaHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LuminaHome", provider: LuminaProvider()) { entry in
            HomeWidgetView(entry: entry)
                .containerBackground(for: .widget) { ThemeBackground(theme: entry.theme) }
        }
        .configurationDisplayName("Today's Manifestation")
        .description("Your daily words, in your chosen theme.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: Lock Screen

struct LockWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LuminaEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 1) {
                Label("Lumina", systemImage: "sparkle")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .widgetAccentable()
                Text(entry.text)
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .accessoryInline:
            Label(entry.text, systemImage: "sparkle")
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: entry.checkedIn ? "checkmark" : "flame.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .widgetAccentable()
                    Text("\(entry.streak)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                }
            }
        default:
            Text(entry.text)
        }
    }
}

struct LuminaLockWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "LuminaLock", provider: LuminaProvider()) { entry in
            LockWidgetView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Lumina")
        .description("Today's manifestation or your streak on the Lock Screen.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular])
    }
}

@main
struct LuminaWidgetBundle: WidgetBundle {
    var body: some Widget {
        LuminaHomeWidget()
        LuminaLockWidget()
    }
}
