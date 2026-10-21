import SwiftUI

/// Five simple steps: Welcome → Name → Focus → Reminder time → Notifications → Premium trial.
struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager

    @State private var step = 0
    @State private var name = ""
    @State private var focus: Set<ManifestCategory> = [.gratitude, .confidence]
    @State private var reminderTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: .now) ?? .now
    @FocusState private var nameFocused: Bool

    private let questionSteps = 4

    var body: some View {
        ZStack {
            AppBackground()

            if step == 5 {
                PaywallView(onFinish: finish)
                    .transition(.opacity)
            } else {
                VStack(spacing: 0) {
                    if step > 0 { topBar }
                    Group {
                        switch step {
                        case 0: welcome
                        case 1: nameStep
                        case 2: focusStep
                        case 3: timeStep
                        default: notifyStep
                        }
                    }
                    .id(step)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity),
                                            removal: .move(edge: .leading).combined(with: .opacity)))
                }
                .padding(.horizontal, 24)
            }
        }
        .animation(.smooth(duration: 0.35), value: step)
    }

    // MARK: Steps

    private var topBar: some View {
        HStack(spacing: 14) {
            Button { step -= 1 } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Theme.surface))
            }
            .accessibilityLabel("Back")

            HStack(spacing: 6) {
                ForEach(1...questionSteps, id: \.self) { i in
                    Capsule()
                        .fill(i <= step ? Theme.accent : Theme.hairline)
                        .frame(height: 4)
                }
            }
            .accessibilityLabel("Step \(step) of \(questionSteps)")
        }
        .padding(.top, 8)
        .padding(.bottom, 28)
    }

    private var welcome: some View {
        VStack(spacing: 0) {
            Spacer()
            LogoMark(size: 88)
            Text("Lumina")
                .font(Theme.display(40, weight: .bold))
                .tracking(-0.8)
                .foregroundStyle(Theme.ink)
                .padding(.top, 28)
            Text("One daily manifestation.\nA calmer, clearer you.")
                .font(Theme.text(18))
                .foregroundStyle(Theme.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.top, 10)
            Spacer()
            Button("Get Started") { step = 1 }
                .buttonStyle(PrimaryButtonStyle())
            Text("Takes less than a minute")
                .font(Theme.text(13))
                .foregroundStyle(Theme.secondary)
                .padding(.top, 14)
                .padding(.bottom, 12)
        }
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            question("What should we call you?",
                     detail: "We'll use your first name in your reminders.")
            TextField("First name", text: $name)
                .font(Theme.text(20, weight: .medium))
                .foregroundStyle(Theme.ink)
                .textContentType(.givenName)
                .submitLabel(.continue)
                .focused($nameFocused)
                .onSubmit { step = 2 }
                .padding(.horizontal, 18)
                .frame(height: 58)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(nameFocused ? Theme.accent : Theme.hairline, lineWidth: nameFocused ? 1.5 : 0.5))
                .padding(.top, 28)
            Spacer()
            Button("Continue") { step = 2 }
                .buttonStyle(PrimaryButtonStyle())
            Button("Skip") { name = ""; step = 2 }
                .buttonStyle(QuietButtonStyle())
                .frame(maxWidth: .infinity)
        }
        .onAppear { nameFocused = true }
    }

    private var focusStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            question("What would you like to manifest?",
                     detail: "Choose as many as you like.")
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(ManifestCategory.allCases) { category in
                        CategoryTile(category: category,
                                     isSelected: focus.contains(category),
                                     isLocked: !category.isFree && !store.isPremium)
                            .onTapGesture {
                                if focus.contains(category) { focus.remove(category) } else { focus.insert(category) }
                            }
                    }
                }
                .padding(.vertical, 4)
                .sensoryFeedback(.selection, trigger: focus)
                Label("Locked categories are included in Premium.", systemImage: "lock.fill")
                    .font(Theme.text(13))
                    .foregroundStyle(Theme.secondary)
                    .padding(.top, 12)
            }
            .padding(.top, 24)
            Button("Continue") { step = 3 }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(focus.isEmpty)
                .padding(.top, 12)
                .padding(.bottom, 12)
        }
    }

    private var timeStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            question("When should we remind you?",
                     detail: "Pick a moment you usually have a quiet minute.")
            HStack(spacing: 8) {
                presetChip("Morning", hour: 7, minute: 30)
                presetChip("Midday", hour: 12, minute: 30)
                presetChip("Evening", hour: 20, minute: 30)
            }
            .padding(.top, 28)
            DatePicker("Reminder time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
            Spacer()
            Text("You can add more reminders later.")
                .font(Theme.text(13))
                .foregroundStyle(Theme.secondary)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 14)
            Button("Continue") { step = 4 }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.bottom, 12)
        }
    }

    private var notifyStep: some View {
        VStack(alignment: .leading, spacing: 0) {
            question("Stay on track, gently",
                     detail: "Your manifestation arrives at \(reminderTime.formatted(date: .omitted, time: .shortened)) on your iPhone and Apple Watch.")

            Card {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        LogoMark(size: 24)
                        Text("LUMINA")
                            .font(Theme.text(12, weight: .semibold))
                            .foregroundStyle(Theme.secondary)
                        Spacer()
                        Text("now")
                            .font(Theme.text(12))
                            .foregroundStyle(Theme.secondary)
                    }
                    Text(name.isEmpty ? "Good morning" : "Good morning, \(name)")
                        .font(Theme.text(15, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                    Text("I trust myself to make good decisions.")
                        .font(Theme.text(15))
                        .foregroundStyle(Theme.ink)
                }
            }
            .padding(.top, 32)
            .accessibilityHidden(true)

            Label("Tap \u{201C}I receive this\u{201D} right from the notification or your watch.", systemImage: "applewatch")
                .font(Theme.text(14))
                .foregroundStyle(Theme.secondary)
                .padding(.top, 16)

            Spacer()
            Button("Allow Reminders") {
                Task {
                    await NotificationManager.shared.requestAuthorization()
                    step = 5
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            Button("Not now") { step = 5 }
                .buttonStyle(QuietButtonStyle())
                .frame(maxWidth: .infinity)
        }
    }

    // MARK: Helpers

    private func question(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Theme.display(30, weight: .bold))
                .tracking(-0.6)
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(Theme.text(16))
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func presetChip(_ label: String, hour: Int, minute: Int) -> some View {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let isOn = comps.hour == hour && comps.minute == minute
        return Button {
            reminderTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? reminderTime
        } label: {
            Text(label)
                .font(Theme.text(15, weight: .semibold))
                .foregroundStyle(isOn ? Theme.bg : Theme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(isOn ? Theme.ink : Theme.surface))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(Theme.hairline, lineWidth: isOn ? 0 : 0.5))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isOn)
    }

    private func finish() {
        var d = appState.data
        d.userName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        d.focusAreas = focus.isEmpty ? [.gratitude, .confidence] : focus
        var reminder = Reminder(hour: 8, minute: 0)
        reminder.date = reminderTime
        d.reminders = [reminder]
        d.hasOnboarded = true
        appState.data = d
    }
}
