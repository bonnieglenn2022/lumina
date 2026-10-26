import SwiftUI

struct TodayView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @State private var showPaywall = false
    @State private var showBreathe = false
    @State private var showWindDown = false
    @State private var showWidgetGuide = false
    @State private var milestone: MilestoneItem?
    @FocusState private var intentionFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        if appState.streakIsBroken {
                            gentleWelcome
                        }
                        AffirmationCard(affirmation: appState.today)
                        receiveButton
                        if appState.checkedInToday && !appState.moodLoggedToday {
                            MoodCheckInCard()
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        PracticeCard(evening: appState.isEvening) {
                            if appState.isEvening { showWindDown = true } else { showBreathe = true }
                        }
                        if appState.checkedInToday && !appState.data.widgetTipDismissed {
                            WidgetTipCard(open: { showWidgetGuide = true },
                                          dismiss: { withAnimation { appState.data.widgetTipDismissed = true } })
                        }
                        intentionCard
                        reminderRow
                        if !appState.isPremium {
                            PremiumBanner { showPaywall = true }
                                .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                    .animation(.snappy, value: appState.checkedInToday)
                }
                .scrollDismissesKeyboard(.interactively)

                if let message = appState.freezeUsedMessage {
                    VStack {
                        Spacer()
                        Label(message, systemImage: "snowflake")
                            .font(Theme.text(15, weight: .semibold))
                            .foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 18).padding(.vertical, 14)
                            .background(Capsule().fill(Theme.accent))
                            .padding(.bottom, 24)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task {
                        try? await Task.sleep(for: .seconds(4))
                        withAnimation { appState.freezeUsedMessage = nil }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showWidgetGuide) { WidgetGuideView() }
            .sheet(item: $milestone) { MilestoneView(days: $0.id) }
            .fullScreenCover(isPresented: $showBreathe) { BreatheView(mode: .breathe) }
            .fullScreenCover(isPresented: $showWindDown) { BreatheView(mode: .windDown) }
            .task {
                guard DemoMode.isOn else { return }
                try? await Task.sleep(for: .milliseconds(600))
                switch DemoMode.screen {
                case "winddown": showWindDown = true
                case "breathe": showBreathe = true
                case "milestone": milestone = MilestoneItem(id: 30)
                default: break
                }
            }
            .onChange(of: appState.pendingMilestone) { _, value in
                if let value {
                    milestone = MilestoneItem(id: value)
                    appState.pendingMilestone = nil
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date.now, format: .dateTime.weekday(.wide).month(.wide).day())
                    .font(Theme.text(15, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                Text(appState.greeting)
                    .font(Theme.display(28, weight: .bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
            if appState.currentStreak > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill").foregroundStyle(Theme.glow)
                    Text("\(appState.currentStreak)")
                    if appState.data.streakFreezes > 0 {
                        Image(systemName: "snowflake")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.accent)
                            .padding(.leading, 2)
                    }
                }
                .font(Theme.text(15, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(Capsule().fill(Theme.glowSoft))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(appState.currentStreak) day streak, \(appState.data.streakFreezes) streak freezes")
            }
        }
        .padding(.top, 8)
    }

    /// Kind, non-shaming copy when a streak has lapsed.
    private var gentleWelcome: some View {
        Card(fill: Theme.glowSoft) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back")
                    .font(Theme.text(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text("Every day is a fresh start. Your longest streak is \(appState.data.longestStreak) days, and it's still yours.")
                    .font(Theme.text(14))
                    .foregroundStyle(Theme.secondary)
            }
        }
    }

    private var receiveButton: some View {
        Group {
            if appState.checkedInToday {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.accent)
                    Text("Received today")
                        .foregroundStyle(Theme.ink)
                    Spacer()
                    if let next = appState.nextMilestone {
                        Text("\(next - appState.currentStreak) to \(next)-day milestone")
                            .font(Theme.text(13))
                            .foregroundStyle(Theme.secondary)
                    }
                }
                .font(Theme.text(16, weight: .semibold))
                .padding(.horizontal, 18)
                .frame(height: 54)
                .background(Capsule().fill(Theme.accentSoft))
            } else {
                Button {
                    withAnimation(.snappy) { appState.checkIn() }
                } label: {
                    Text("I receive this")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
        .sensoryFeedback(.success, trigger: appState.checkedInToday)
    }

    private var intentionCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                Text("Today's intention")
                    .font(Theme.text(13, weight: .medium))
                    .foregroundStyle(Theme.secondary)
                TextField("Today I will…",
                          text: Binding(get: { appState.todayIntention },
                                        set: { appState.todayIntention = $0 }),
                          axis: .vertical)
                    .font(Theme.serif(19))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1...4)
                    .focused($intentionFocused)
                    .submitLabel(.done)
                    .onChange(of: appState.todayIntention) { _, value in
                        if value.contains("\n") {
                            appState.todayIntention = value.replacingOccurrences(of: "\n", with: "")
                            intentionFocused = false
                        }
                    }
            }
        }
    }

    private var reminderRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "bell")
            Text(appState.nextReminderText.map { "Next reminder · \($0)" } ?? "No reminders set — add one in Settings")
            Spacer()
        }
        .font(Theme.text(14))
        .foregroundStyle(Theme.secondary)
        .padding(.horizontal, 4)
    }
}

struct MilestoneItem: Identifiable {
    let id: Int
}
