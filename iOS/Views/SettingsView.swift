import SwiftUI
import StoreKit
import UserNotifications

/// Native inset-grouped settings — the cleanest, most familiar pattern on iOS.
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    @State private var showPaywall = false
    @State private var showManage = false
    @State private var notificationStatus: UNAuthorizationStatus = .authorized
    @State private var restoreMessage: String?
    @State private var showThemes = false
    @State private var showWidgetGuide = false

    var body: some View {
        NavigationStack {
            Form {
                premiumSection
                profileSection
                streakSection
                remindersSection
                lookSection
                soundSection
                focusSection
                healthSection
                widgetsSection
                watchSection
                supportSection
                footer
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(isPresented: $showThemes) { ThemePickerView() }
            .sheet(isPresented: $showWidgetGuide) { WidgetGuideView() }
            .manageSubscriptionsSheet(isPresented: $showManage)
            .task { notificationStatus = await NotificationManager.shared.authorizationStatus() }
            .alert("Restore Purchases", isPresented: .constant(restoreMessage != nil)) {
                Button("OK") { restoreMessage = nil }
            } message: { Text(restoreMessage ?? "") }
        }
    }

    // MARK: Sections

    private var premiumSection: some View {
        Section {
            if appState.isPremium {
                HStack(spacing: 14) {
                    LogoMark(size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lumina Premium").font(Theme.text(16, weight: .semibold))
                        Text(store.isInTrial ? "Free trial active" : "Active")
                            .font(Theme.text(13)).foregroundStyle(Theme.secondary)
                    }
                }
                Button("Manage Subscription") { showManage = true }
            } else {
                PremiumBanner { showPaywall = true }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
    }

    private var profileSection: some View {
        Section("Profile") {
            TextField("First name", text: $appState.data.userName)
                .textContentType(.givenName)
        }
    }

    private var remindersSection: some View {
        Section {
            if notificationStatus == .denied {
                Button {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                } label: {
                    Label("Notifications are off — turn on", systemImage: "bell.slash")
                }
            } else if notificationStatus == .notDetermined {
                Button {
                    Task {
                        await NotificationManager.shared.requestAuthorization()
                        notificationStatus = await NotificationManager.shared.authorizationStatus()
                        appState.refresh()
                    }
                } label: {
                    Label("Allow reminders", systemImage: "bell.badge")
                }
            }

            ForEach($appState.data.reminders) { $reminder in
                let locked = appState.isReminderLocked(reminder)
                HStack {
                    DatePicker("Reminder", selection: $reminder.date, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .disabled(locked)
                    Spacer()
                    if locked {
                        Button { showPaywall = true } label: {
                            Label("Premium", systemImage: "lock.fill")
                                .font(Theme.text(13, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Toggle("Enabled", isOn: $reminder.isEnabled)
                            .labelsHidden()
                    }
                }
            }
            .onDelete { offsets in
                if appState.data.reminders.count - offsets.count >= 1 { appState.deleteReminders(at: offsets) }
            }

            Button {
                if appState.canAddReminder { withAnimation { appState.addReminder() } } else { showPaywall = true }
            } label: {
                Label("Add Reminder", systemImage: "plus")
            }
        } header: {
            Text("Daily Reminders")
        } footer: {
            Text(appState.isPremium
                 ? "Up to \(AppConfig.premiumReminderLimit) a day. Reminders also appear on your Apple Watch."
                 : "Free includes 1 reminder a day; Premium allows up to \(AppConfig.premiumReminderLimit). Reminders also appear on your Apple Watch.")
        }
    }


    private var streakSection: some View {
        Section {
            LabeledContent("Current streak", value: "\(appState.currentStreak) days")
            LabeledContent("Longest streak", value: "\(appState.data.longestStreak) days")
            LabeledContent {
                Text("\(appState.data.streakFreezes) of \(appState.freezeCap)")
            } label: {
                Label("Streak freezes", systemImage: "snowflake")
            }
        } header: {
            Text("Streak")
        } footer: {
            Text("A freeze quietly protects your streak if you miss a day. Earn one at each milestone (7, 30, 100 and 365 days).")
        }
    }

    private var lookSection: some View {
        Section {
            Picker("Appearance", selection: $appState.data.appearance) {
                ForEach(AppearanceMode.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Button {
                showThemes = true
            } label: {
                LabeledContent("Card theme", value: appState.theme.name)
            }
            .foregroundStyle(Theme.ink)
        } header: {
            Text("Look")
        } footer: {
            Text("Auto switches to calm evening colors from 7 PM to 5 AM.")
        }
    }

    private var soundSection: some View {
        Section("Sound") {
            Toggle("Chimes and reminder sound", isOn: $appState.data.soundsOn)
            Picker("Default soundscape", selection: $appState.data.soundscape) {
                ForEach(Soundscape.allCases.filter { $0.isFree || appState.isPremium }) { s in
                    Label(s.title, systemImage: s.symbol).tag(s)
                }
            }
            Button("Preview chime") { SoundManager.shared.playChime(enabled: true) }
        }
    }

    private var healthSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { appState.data.healthEnabled },
                set: { on in
                    if on {
                        Task {
                            let ok = await HealthManager.shared.requestAuthorization()
                            appState.data.healthEnabled = ok
                        }
                    } else {
                        appState.data.healthEnabled = false
                    }
                })) {
                Label("Save to Apple Health", systemImage: "heart.text.square")
            }
            .disabled(!HealthManager.shared.isAvailable)
        } header: {
            Text("Apple Health")
        } footer: {
            Text("Logs Mindful Minutes from breathing sessions and your mood check-ins (iOS 18 and later). Lumina only writes to Health; it never reads your health data.")
        }
    }

    private var widgetsSection: some View {
        Section("Widgets") {
            Button {
                showWidgetGuide = true
            } label: {
                Label("Add Lumina to your Lock Screen or Home Screen", systemImage: "lock.rectangle.on.rectangle")
            }
        }
    }

    private var focusSection: some View {
        Section("Manifesting") {
            NavigationLink {
                FocusAreasView()
            } label: {
                LabeledContent("Focus Areas", value: "\(appState.data.focusAreas.count) selected")
            }
        }
    }

    private var watchSection: some View {
        Section {
            Label {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Add Lumina to your watch face")
                    Text("Touch and hold the watch face → Edit → Complications → Lumina.")
                        .font(Theme.text(13))
                        .foregroundStyle(Theme.secondary)
                }
            } icon: {
                Image(systemName: "applewatch")
            }
            .padding(.vertical, 2)
        } header: {
            Text("Apple Watch")
        }
    }

    private var supportSection: some View {
        Section("Support") {
            Button("Restore Purchases") {
                Task {
                    do {
                        try await store.restore()
                        restoreMessage = store.isPremium ? "Lumina Premium has been restored." : "No active subscription was found for this Apple ID."
                    } catch {
                        restoreMessage = error.localizedDescription
                    }
                }
            }
            Button("Rate Lumina") { requestReview() }
            Link("Help & Support", destination: AppConfig.supportURL)
            Link("Privacy Policy", destination: AppConfig.privacyURL)
            Link("Terms of Use", destination: AppConfig.termsURL)
        }
    }

    private var footer: some View {
        Section {
            EmptyView()
        } footer: {
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
            Text("Lumina \(version)")
                .frame(maxWidth: .infinity)
        }
    }
}

struct FocusAreasView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showPaywall = false

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Today and your reminders draw from the areas you choose.")
                        .font(Theme.text(15))
                        .foregroundStyle(Theme.secondary)
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(ManifestCategory.allCases) { category in
                            let available = appState.isCategoryAvailable(category)
                            CategoryTile(category: category,
                                         isSelected: available && appState.data.focusAreas.contains(category),
                                         isLocked: !available)
                                .onTapGesture { toggle(category, available: available) }
                        }
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Focus Areas")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) { PaywallView() }
    }

    private func toggle(_ category: ManifestCategory, available: Bool) {
        guard available else { showPaywall = true; return }
        if appState.data.focusAreas.contains(category) {
            if appState.data.focusAreas.count > 1 { appState.data.focusAreas.remove(category) }
        } else {
            appState.data.focusAreas.insert(category)
        }
    }
}
