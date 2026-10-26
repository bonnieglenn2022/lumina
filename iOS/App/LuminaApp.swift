import SwiftUI
import UserNotifications

@main
struct LuminaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState = AppState.shared
    @StateObject private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(store)
                .tint(Theme.accent)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        NotificationManager.shared.registerCategories()
        PhoneSessionManager.shared.activate()
        return true
    }

    // Show reminders even while the app is open.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // "I receive this" action from a notification (iPhone or Apple Watch).
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        if response.actionIdentifier == NotificationManager.affirmActionID {
            await MainActor.run { AppState.shared.checkIn() }
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if appState.data.hasOnboarded {
                MainTabView()
                    .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.data.hasOnboarded)
        .preferredColorScheme(appState.preferredColorScheme)
        .onChange(of: store.isPremium, initial: true) { _, newValue in
            appState.isPremium = DemoMode.isOn ? true : newValue
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                appState.refresh()
                Task { await store.refreshEntitlements() }
            }
        }
    }
}
