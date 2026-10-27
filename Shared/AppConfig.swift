import Foundation

/// Central place for everything you may need to change before publishing.
/// `setup.sh` replaces "com.luminamanifestation" with your own bundle prefix automatically.
enum AppConfig {
    static let appName = "Lumina"

    // App Group shared by the iPhone app, Watch app and watch-face complication.
    static let appGroupID = "group.com.luminamanifestation.lumina"

    // Auto-renewable subscriptions (create these in App Store Connect with a 1-week free trial).
    static let yearlyProductID = "com.luminamanifestation.lumina.premium.yearly"
    static let monthlyProductID = "com.luminamanifestation.lumina.premium.monthly"
    static let lifetimeProductID = "com.luminamanifestation.lumina.premium.lifetime"
    static var subscriptionIDs: [String] { [yearlyProductID, monthlyProductID] }
    static var allProductIDs: [String] { [yearlyProductID, monthlyProductID, lifetimeProductID] }

    // Required by App Review on any screen that sells a subscription.
    // Set these to the published support site before release (see PUBLISHING.md).
    static let privacyURL = URL(string: "https://bonnieglenn2022.github.io/lumina-site/privacy.html")!
    static let supportEmail = "info@yourlumina.app"
    static let supportMailURL = URL(string: "mailto:info@yourlumina.app")!
    static let supportURL =URL(string: "https://bonnieglenn2022.github.io/lumina-site/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    // Free vs Premium limits.
    static let freeCustomLimit = 3
    static let freeReminderLimit = 1
    static let premiumReminderLimit = 6
    static let maxManifestationLength = 180
    static let freeFreezeCap = 2
    static let premiumFreezeCap = 3
    static let streakMilestones = [7, 30, 100, 365]

    static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }
}
