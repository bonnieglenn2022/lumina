import WidgetKit
import SwiftUI

/// Watch-face complication: today's manifestation, always one glance away.
struct ManifestEntry: TimelineEntry {
    let date: Date
    let text: String
    let category: String
    let streak: Int
}

struct ManifestProvider: TimelineProvider {
    func placeholder(in context: Context) -> ManifestEntry {
        ManifestEntry(date: .now, text: "I am calm, centered, and grounded.", category: "Peace", streak: 3)
    }

    func getSnapshot(in context: Context, completion: @escaping (ManifestEntry) -> Void) {
        completion(entry(for: .now))
    }

    /// One entry per day for the next week, so the complication changes at midnight
    /// even if the iPhone hasn't synced.
    func getTimeline(in context: Context, completion: @escaping (Timeline<ManifestEntry>) -> Void) {
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

    private func entry(for date: Date) -> ManifestEntry {
        let snapshot = WatchSnapshot.load()
        let item = snapshot.item(for: date)
        return ManifestEntry(date: date, text: item.text, category: item.category, streak: snapshot.streak)
    }
}

struct ManifestComplicationView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ManifestEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label("Lumina", systemImage: "sparkle")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .widgetAccentable()
                Text(entry.text)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .accessoryInline:
            Label(entry.text, systemImage: "sparkle")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .medium))
                        .widgetAccentable()
                    if entry.streak > 0 {
                        Text("\(entry.streak)")
                            .font(.system(size: 12, weight: .bold))
                    }
                }
            }

        case .accessoryCorner:
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .medium))
                .widgetAccentable()
                .widgetLabel { Text(entry.text) }

        default:
            Text(entry.text)
        }
    }
}

@main
struct LuminaComplication: Widget {
    let kind = "LuminaComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ManifestProvider()) { entry in
            ManifestComplicationView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Daily Manifestation")
        .description("Today's manifestation on your watch face.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline, .accessoryCircular, .accessoryCorner])
    }
}
