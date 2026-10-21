import SwiftUI
import WatchKit

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            TabView {
                WatchTodayPage()
                WatchBreathePage()
                WatchFavoritesPage()
            }
            .tabViewStyle(.verticalPage)
            .containerBackground(Theme.accent.opacity(0.35).gradient, for: .tabView)
        }
    }
}

// MARK: Today

struct WatchTodayPage: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(session.today.category)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)

                Text(session.today.text)
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if session.checkedInToday {
                    Label("Received · \(session.snapshot.streak)-day streak", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } else {
                    Button("I receive this") { session.affirm() }
                        .font(.system(size: 16, weight: .semibold))
                        .buttonStyle(.borderedProminent)
                        .tint(Theme.accent)
                        .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(session.snapshot.name.isEmpty ? "Today" : "Hi, \(session.snapshot.name)")
    }
}

// MARK: Breathe & repeat

struct WatchBreathePage: View {
    @EnvironmentObject private var session: WatchSessionManager

    private enum Phase { case idle, inhale, exhale, done }
    @State private var phase: Phase = .idle
    @State private var scale: CGFloat = 0.5
    @State private var task: Task<Void, Never>?
    private let cycles = 3

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Theme.accent.gradient)
                    .scaleEffect(scale)
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(height: 110)

            if phase == .idle || phase == .done {
                Button(phase == .done ? "Again" : "Breathe & repeat") { start() }
                    .buttonStyle(.bordered)
            } else {
                Text(session.today.text)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.8)
            }
        }
        .navigationTitle("Breathe")
        .onDisappear { task?.cancel(); phase = .idle; scale = 0.5 }
    }

    private var label: String {
        switch phase {
        case .idle: return ""
        case .inhale: return "In"
        case .exhale: return "Out"
        case .done: return "Done"
        }
    }

    private func start() {
        task?.cancel()
        task = Task { @MainActor in
            for _ in 1...cycles {
                phase = .inhale
                WKInterfaceDevice.current().play(.directionUp)
                withAnimation(.easeInOut(duration: 4)) { scale = 1.0 }
                try? await Task.sleep(for: .seconds(4))
                if Task.isCancelled { return }
                phase = .exhale
                WKInterfaceDevice.current().play(.directionDown)
                withAnimation(.easeInOut(duration: 6)) { scale = 0.5 }
                try? await Task.sleep(for: .seconds(6))
                if Task.isCancelled { return }
            }
            phase = .done
            WKInterfaceDevice.current().play(.success)
        }
    }
}

// MARK: Favorites

struct WatchFavoritesPage: View {
    @EnvironmentObject private var session: WatchSessionManager

    var body: some View {
        Group {
            if session.snapshot.favorites.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "heart")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                    Text("Heart a manifestation on your iPhone to see it here.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                List(session.snapshot.favorites, id: \.self) { text in
                    Text(text)
                        .font(.system(size: 16, weight: .medium))
                        .padding(.vertical, 4)
                }
                .listStyle(.carousel)
            }
        }
        .navigationTitle("Favorites")
    }
}
