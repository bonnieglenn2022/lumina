import SwiftUI

/// Standard iOS tab bar and navigation bars — they look modern and adapt to light/dark automatically.
struct MainTabView: View {
    enum Tab: Hashable { case today, library, mine, settings }

    @State private var tab: Tab = MainTabView.initialTab

    private static var initialTab: Tab {
        guard DemoMode.isOn else { return .today }
        switch DemoMode.screen {
        case "library": return .library
        case "mine": return .mine
        case "settings": return .settings
        default: return .today
        }
    }

    var body: some View {
        TabView(selection: $tab) {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(Tab.today)
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.grid.2x2") }
                .tag(Tab.library)
            MyManifestationsView()
                .tabItem { Label("Mine", systemImage: "sparkles") }
                .tag(Tab.mine)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }
}
