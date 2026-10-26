import Foundation

/// Screenshot mode, used only by the cloud screenshot job.
/// Launch with `-LuminaDemo -LuminaScreen <name>` (and optionally `-LuminaEvening YES`).
/// Normal users never pass these arguments, so this has no effect on the real app.
enum DemoMode {
    static var isOn: Bool { ProcessInfo.processInfo.arguments.contains("-LuminaDemo") }

    /// today, library, mine, settings, winddown, milestone
    static var screen: String { UserDefaults.standard.string(forKey: "LuminaScreen") ?? "today" }

    static var evening: Bool { UserDefaults.standard.bool(forKey: "LuminaEvening") }

    static let name = "Maya"
    static let streak = 12
    static let affirmationID = "abundance-3"

    static var affirmation: Affirmation? {
        AffirmationLibrary.all.first { $0.id == affirmationID }
    }
}
