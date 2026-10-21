import SwiftUI

@main
struct LuminaWatchApp: App {
    @StateObject private var session = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
                .environmentObject(session)
        }
    }
}
