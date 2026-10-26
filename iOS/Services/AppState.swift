import Foundation
import SwiftUI
import WidgetKit

struct Reminder: Identifiable, Codable, Hashable {
    var id = UUID()
    var hour: Int
    var minute: Int
    var isEnabled = true

    var date: Date {
        get { Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now }
        set {
            let c = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            hour = c.hour ?? 8
            minute = c.minute ?? 0
        }
    }

    var timeText: String { date.formatted(date: .omitted, time: .shortened) }
}

struct MoodEntry: Codable, Hashable {
    var date: Date
    var level: Int  // 1 (low) … 5 (great)
}

enum AppearanceMode: String, Codable, CaseIterable, Identifiable {
    case system, light, evening, automatic
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: return "System"
        case .light: return "Day"
        case .evening: return "Evening"
        case .automatic: return "Auto"
        }
    }
}

/// Everything the user creates, saved on-device only.
struct UserData: Codable {
    var hasOnboarded = false
    var userName = ""
    var focusAreas: Set<ManifestCategory> = [.gratitude, .confidence]
    var reminders: [Reminder] = [Reminder(hour: 8, minute: 0)]
    var custom: [Affirmation] = []
    var favoriteIDs: Set<String> = []
    var streak = 0
    var longestStreak = 0
    var lastCheckIn: Date?
    var streakFreezes = 1
    var celebratedMilestone = 0
    var intention = ""
    var intentionDay = -1
    var themeID = "classic"
    var appearance: AppearanceMode = .automatic
    var soundsOn = true
    var soundscape: Soundscape = .rain
    var healthEnabled = false
    var moodLog: [MoodEntry] = []
    var widgetTipDismissed = false

    init() {}

    // Tolerant decoding so future app updates never wipe a user's data.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = UserData()
        hasOnboarded = try c.decodeIfPresent(Bool.self, forKey: .hasOnboarded) ?? d.hasOnboarded
        userName = try c.decodeIfPresent(String.self, forKey: .userName) ?? d.userName
        focusAreas = try c.decodeIfPresent(Set<ManifestCategory>.self, forKey: .focusAreas) ?? d.focusAreas
        reminders = try c.decodeIfPresent([Reminder].self, forKey: .reminders) ?? d.reminders
        custom = try c.decodeIfPresent([Affirmation].self, forKey: .custom) ?? d.custom
        favoriteIDs = try c.decodeIfPresent(Set<String>.self, forKey: .favoriteIDs) ?? d.favoriteIDs
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? d.streak
        longestStreak = try c.decodeIfPresent(Int.self, forKey: .longestStreak) ?? d.longestStreak
        lastCheckIn = try c.decodeIfPresent(Date.self, forKey: .lastCheckIn)
        streakFreezes = try c.decodeIfPresent(Int.self, forKey: .streakFreezes) ?? d.streakFreezes
        celebratedMilestone = try c.decodeIfPresent(Int.self, forKey: .celebratedMilestone) ?? d.celebratedMilestone
        intention = try c.decodeIfPresent(String.self, forKey: .intention) ?? d.intention
        intentionDay = try c.decodeIfPresent(Int.self, forKey: .intentionDay) ?? d.intentionDay
        themeID = try c.decodeIfPresent(String.self, forKey: .themeID) ?? d.themeID
        appearance = try c.decodeIfPresent(AppearanceMode.self, forKey: .appearance) ?? d.appearance
        soundsOn = try c.decodeIfPresent(Bool.self, forKey: .soundsOn) ?? d.soundsOn
        soundscape = try c.decodeIfPresent(Soundscape.self, forKey: .soundscape) ?? d.soundscape
        healthEnabled = try c.decodeIfPresent(Bool.self, forKey: .healthEnabled) ?? d.healthEnabled
        moodLog = try c.decodeIfPresent([MoodEntry].self, forKey: .moodLog) ?? d.moodLog
        widgetTipDismissed = try c.decodeIfPresent(Bool.self, forKey: .widgetTipDismissed) ?? d.widgetTipDismissed
    }
}

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var data: UserData {
        didSet { persist(); scheduleSync() }
    }

    /// Mirrors StoreManager.isPremium (set from RootView).
    @Published var isPremium = false {
        didSet { if oldValue != isPremium { scheduleSync() } }
    }

    /// Set when a check-in reaches a streak milestone; Today shows the celebration.
    @Published var pendingMilestone: Int?
    /// Set when a streak freeze quietly saved the user's streak.
    @Published var freezeUsedMessage: String?
    /// Bumped when the app becomes active so time-based UI (evening mode) refreshes.
    @Published var clock = Date()

    private let storageKey = "lumina.userdata.v1"
    private var syncTask: Task<Void, Never>?

    private init() {
        if let raw = AppConfig.sharedDefaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(UserData.self, from: raw) {
            data = decoded
        } else {
            data = UserData()
        }
        if DemoMode.isOn { applyDemo() }
    }

    /// Realistic sample state for App Store screenshots (screenshot job only).
    private func applyDemo() {
        var d = UserData()
        let cal = Calendar.current
        d.hasOnboarded = true
        d.userName = DemoMode.name
        d.focusAreas = [.gratitude, .confidence, .abundance, .peace]
        d.reminders = [Reminder(hour: 7, minute: 30), Reminder(hour: 20, minute: 30)]
        d.custom = [
            Affirmation(id: "demo-1", text: "I am building a life I love, one calm morning at a time.", category: nil),
            Affirmation(id: "demo-2", text: "My business grows with ease and integrity.", category: nil)
        ]
        d.favoriteIDs = ["abundance-3", "peace-0", "love-0", "gratitude-5"]
        d.streak = DemoMode.streak
        d.longestStreak = 21
        d.lastCheckIn = cal.date(byAdding: .day, value: -1, to: .now)
        d.streakFreezes = 2
        d.celebratedMilestone = 7
        d.intention = "Show up with patience and warmth"
        d.intentionDay = DailyPicker.dayNumber(for: .now)
        d.themeID = DemoMode.screen == "library" ? "classic" : "moonlit"
        d.appearance = .automatic
        d.healthEnabled = true
        d.widgetTipDismissed = true
        data = d
    }

    // MARK: Today

    var pool: [Affirmation] {
        DailyPicker.pool(categories: data.focusAreas, isPremium: isPremium, custom: data.custom)
    }

    var today: Affirmation {
        if DemoMode.isOn, let demo = DemoMode.affirmation { return demo }
        return DailyPicker.affirmation(for: .now, pool: pool)
    }

    var firstName: String {
        data.userName.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ").first ?? ""
    }

    var greeting: String {
        let hour = DemoMode.isOn ? (DemoMode.evening ? 20 : 9) : Calendar.current.component(.hour, from: clock)
        let base = hour < 12 ? "Good morning" : (hour < 17 ? "Good afternoon" : "Good evening")
        return firstName.isEmpty ? base : "\(base), \(firstName)"
    }

    var isEvening: Bool {
        if DemoMode.isOn { return DemoMode.evening }
        let hour = Calendar.current.component(.hour, from: clock)
        return hour >= 19 || hour < 5
    }

    var preferredColorScheme: ColorScheme? {
        switch data.appearance {
        case .system: return nil
        case .light: return .light
        case .evening: return .dark
        case .automatic: return isEvening ? .dark : .light
        }
    }

    var theme: CardTheme {
        let t = CardTheme.with(id: data.themeID)
        return (t.isFree || isPremium) ? t : .classic
    }

    // MARK: Streaks (with gentle freezes and milestones)

    var checkedInToday: Bool {
        guard let last = data.lastCheckIn else { return false }
        return Calendar.current.isDateInToday(last)
    }

    private var missedDays: Int {
        guard let last = data.lastCheckIn else { return 0 }
        let cal = Calendar.current
        let gap = cal.dateComponents([.day], from: cal.startOfDay(for: last), to: cal.startOfDay(for: .now)).day ?? 0
        return max(gap - 1, 0)
    }

    var currentStreak: Int {
        guard data.lastCheckIn != nil else { return 0 }
        return missedDays <= data.streakFreezes ? data.streak : 0
    }

    var streakIsBroken: Bool { data.lastCheckIn != nil && data.streak > 1 && currentStreak == 0 && !checkedInToday }

    var freezeCap: Int { isPremium ? AppConfig.premiumFreezeCap : AppConfig.freeFreezeCap }

    var nextMilestone: Int? { AppConfig.streakMilestones.first { $0 > currentStreak } }

    func checkIn() {
        guard !checkedInToday else { return }
        var d = data
        let missed = missedDays
        if d.lastCheckIn == nil {
            d.streak = 1
        } else if missed == 0 {
            d.streak += 1
        } else if missed <= d.streakFreezes {
            d.streakFreezes -= missed
            d.streak += 1
            freezeUsedMessage = missed == 1
                ? "A streak freeze saved your streak. Welcome back."
                : "\(missed) streak freezes saved your streak. Welcome back."
        } else {
            d.streak = 1
            d.celebratedMilestone = 0
        }
        d.lastCheckIn = .now
        d.longestStreak = max(d.longestStreak, d.streak)

        if AppConfig.streakMilestones.contains(d.streak), d.streak > d.celebratedMilestone {
            d.celebratedMilestone = d.streak
            d.streakFreezes = min(d.streakFreezes + 1, freezeCap)
            pendingMilestone = d.streak
        }
        data = d
        SoundManager.shared.playComplete(enabled: d.soundsOn)
    }

    // MARK: Mood

    var moodLoggedToday: Bool {
        data.moodLog.contains { Calendar.current.isDateInToday($0.date) }
    }

    func logMood(_ level: Int) {
        var d = data
        d.moodLog.append(MoodEntry(date: .now, level: level))
        if d.moodLog.count > 120 { d.moodLog.removeFirst(d.moodLog.count - 120) }
        data = d
        if d.healthEnabled {
            Task { await HealthManager.shared.saveMood(level: level) }
        }
    }

    func logMindful(start: Date, end: Date) {
        guard data.healthEnabled else { return }
        Task { await HealthManager.shared.saveMindfulSession(start: start, end: end) }
    }

    // MARK: Today's intention

    var todayIntention: String {
        get { data.intentionDay == DailyPicker.dayNumber(for: .now) ? data.intention : "" }
        set {
            data.intention = newValue
            data.intentionDay = DailyPicker.dayNumber(for: .now)
        }
    }

    // MARK: Favorites & custom

    func isFavorite(_ a: Affirmation) -> Bool { data.favoriteIDs.contains(a.id) }

    func toggleFavorite(_ a: Affirmation) {
        if data.favoriteIDs.contains(a.id) { data.favoriteIDs.remove(a.id) } else { data.favoriteIDs.insert(a.id) }
    }

    var favorites: [Affirmation] {
        (AffirmationLibrary.all + data.custom).filter { data.favoriteIDs.contains($0.id) }
    }

    var canAddCustom: Bool { isPremium || data.custom.count < AppConfig.freeCustomLimit }

    func addCustom(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, canAddCustom else { return }
        data.custom.insert(Affirmation(text: String(trimmed.prefix(AppConfig.maxManifestationLength)), category: nil), at: 0)
    }

    func deleteCustom(_ a: Affirmation) {
        var d = data
        d.custom.removeAll { $0.id == a.id }
        d.favoriteIDs.remove(a.id)
        data = d
        VoiceRecorder.shared.delete(a.id)
    }

    func isCategoryAvailable(_ c: ManifestCategory) -> Bool { isPremium || c.isFree }

    // MARK: Reminders

    var reminderLimit: Int { isPremium ? AppConfig.premiumReminderLimit : AppConfig.freeReminderLimit }

    var canAddReminder: Bool { data.reminders.count < reminderLimit }

    func isReminderLocked(_ r: Reminder) -> Bool {
        guard !isPremium, let index = data.reminders.firstIndex(of: r) else { return false }
        return index >= AppConfig.freeReminderLimit
    }

    var activeReminders: [Reminder] {
        let usable = isPremium ? data.reminders : Array(data.reminders.prefix(AppConfig.freeReminderLimit))
        return usable.filter(\.isEnabled).sorted { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
    }

    func addReminder() {
        guard canAddReminder else { return }
        let last = data.reminders.last ?? Reminder(hour: 8, minute: 0)
        data.reminders.append(Reminder(hour: min(last.hour + 4, 21), minute: last.minute))
    }

    func deleteReminders(at offsets: IndexSet) {
        data.reminders.remove(atOffsets: offsets)
    }

    var nextReminderText: String? {
        let now = Date()
        let cal = Calendar.current
        let candidates = activeReminders.compactMap { r -> Date? in
            cal.nextDate(after: now, matching: DateComponents(hour: r.hour, minute: r.minute), matchingPolicy: .nextTime)
        }
        guard let next = candidates.min() else { return nil }
        let time = next.formatted(date: .omitted, time: .shortened)
        return cal.isDateInToday(next) ? "Today at \(time)" : "Tomorrow at \(time)"
    }

    // MARK: Sync (notifications, widgets, Apple Watch)

    func refresh() {
        clock = .now
        scheduleSync()
    }

    private func persist() {
        if let raw = try? JSONEncoder().encode(data) {
            AppConfig.sharedDefaults.set(raw, forKey: storageKey)
        }
    }

    private func scheduleSync() {
        syncTask?.cancel()
        syncTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled, let self else { return }
            await NotificationManager.shared.reschedule(reminders: self.activeReminders,
                                                        pool: self.pool,
                                                        name: self.firstName,
                                                        customSound: self.data.soundsOn)
            let snapshot = self.watchSnapshot()
            snapshot.save()                       // iPhone widgets read this
            WidgetCenter.shared.reloadAllTimelines()
            PhoneSessionManager.shared.push(snapshot)
        }
    }

    func watchSnapshot() -> WatchSnapshot {
        let cal = Calendar.current
        let start = cal.startOfDay(for: .now)
        let currentPool = pool
        let week: [WatchSnapshot.DayItem] = (0..<8).compactMap { offset in
            guard let day = cal.date(byAdding: .day, value: offset, to: start) else { return nil }
            let a = DailyPicker.affirmation(for: day, pool: currentPool)
            return .init(day: DailyPicker.dayNumber(for: day), text: a.text, category: a.categoryTitle)
        }
        return WatchSnapshot(name: firstName,
                             week: week,
                             favorites: favorites.map(\.text),
                             streak: currentStreak,
                             checkedInDay: checkedInToday ? DailyPicker.dayNumber(for: .now) : -1,
                             themeID: theme.id)
    }
}
