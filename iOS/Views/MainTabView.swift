import SwiftUI

/// Standard iOS tab bar and navigation bars — they look modern and adapt to light/dark automatically.
struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem { Label("Today", systemImage: "sun.max") }
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.grid.2x2") }
            MyManifestationsView()
                .tabItem { Label("Mine", systemImage: "sparkles") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
