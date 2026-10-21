import Foundation

/// The small package of data the iPhone sends to the Apple Watch.
/// The Watch app and the watch-face complication both read it.
struct WatchSnapshot: Codable {
    struct DayItem: Codable, Hashable {
        var day: Int
        var text: String
        var category: String
    }

    var name: String = ""
    var week: [DayItem] = []
    var favorites: [String] = []
    var streak: Int = 0
    var checkedInDay: Int = -1
    var themeID: String = "classic"

    private static let key = "lumina.watch.snapshot"

    func item(for date: Date) -> DayItem {
        let day = DailyPicker.dayNumber(for: date)
        if let match = week.first(where: { $0.day == day }) { return match }
        // Fallback so the Watch is never empty, even before the first sync.
        let pool = DailyPicker.pool(categories: Set(ManifestCategory.allCases.filter(\.isFree)), isPremium: false, custom: [])
        let pick = DailyPicker.affirmation(for: date, pool: pool)
        return DayItem(day: day, text: pick.text, category: pick.categoryTitle)
    }

    static func load() -> WatchSnapshot {
        guard let data = AppConfig.sharedDefaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(WatchSnapshot.self, from: data) else { return WatchSnapshot() }
        return snapshot
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            AppConfig.sharedDefaults.set(data, forKey: Self.key)
        }
    }
}
