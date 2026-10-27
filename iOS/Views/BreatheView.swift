import SwiftUI

/// Guided breathing (4s in, 6s out) with a soundscape.
/// `.windDown` is the evening routine: navy screen, today's affirmation,
/// longer session, and a soundscape that keeps playing until the timer ends.
struct BreatheView: View {
    enum Mode { case breathe, windDown }

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    let mode: Mode
    @State private var minutes: Int
    @State private var soundscape: Soundscape = .rain
    @State private var running = false
    @State private var inhale = false
    @State private var phaseText = "Ready when you are"
    @State private var remaining: Int = 0
    @State private var startedAt: Date?
    @State private var task: Task<Void, Never>?
    @State private var showPaywall = false
    @State private var finished = false

    private let inhaleSeconds = 4.0
    private let exhaleSeconds = 6.0

    init(mode: Mode) {
        self.mode = mode
        _minutes = State(initialValue: mode == .windDown ? 5 : 1)
    }

    var body: some View {
        ZStack {
            Theme.navy.ignoresSafeArea()
            RadialGradient(colors: [Color(hex: 0x2F4F8F).opacity(0.55), .clear],
                           center: .center, startRadius: 10, endRadius: 360)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { end() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.cream.opacity(0.8))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(.white.opacity(0.08)))
                    }
                    .accessibilityLabel("Close")
                    Spacer()
                    Text(mode == .windDown ? "Wind down" : "Breathe & repeat")
                        .font(Theme.text(15, weight: .semibold))
                        .foregroundStyle(Theme.cream.opacity(0.8))
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color(hex: 0x9DB5F0).opacity(0.10))
                        .frame(width: 280, height: 280)
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: 0x9DB5F0), Color(hex: 0x3B5BA5)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 280, height: 280)
                        .scaleEffect(inhale ? 1.0 : 0.45)
                        .opacity(inhale ? 0.95 : 0.7)
                    Text(finished ? "Beautiful" : phaseText)
                        .font(Theme.display(20, weight: .medium))
                        .foregroundStyle(Theme.cream)
                }
                .accessibilityElement(children: .combine)

                Text(appState.today.text)
                    .font(Theme.serif(22))
                    .foregroundStyle(Theme.cream)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 40)

                if running {
                    Text(timeLeft)
                        .font(Theme.text(15))
                        .monospacedDigit()
                        .foregroundStyle(Theme.cream.opacity(0.6))
                        .padding(.top, 16)
                }

                Spacer()

                if !running {
                    controls
                }
            }
        }
        .preferredColorScheme(.dark)
        .sensoryFeedback(.impact(weight: .light), trigger: inhale)
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .onAppear { soundscape = appState.data.soundscape }
        .onDisappear { stopAll() }
    }

    private var controls: some View {
        VStack(spacing: 18) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Soundscape.allCases) { s in
                        let locked = !s.isFree && !appState.isPremium
                        Button {
                            if locked { showPaywall = true } else { soundscape = s; appState.data.soundscape = s }
                        } label: {
                            Label(s.title, systemImage: locked ? "lock.fill" : s.symbol)
                                .font(Theme.text(14, weight: .medium))
                                .foregroundStyle(soundscape == s ? Theme.navy : Theme.cream)
                                .padding(.horizontal, 14).padding(.vertical, 9)
                                .background(Capsule().fill(soundscape == s ? Theme.cream : .white.opacity(0.10)))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 24)
            }

            HStack(spacing: 8) {
                ForEach(mode == .windDown ? [5, 10, 15] : [1, 3, 5], id: \.self) { m in
                    Button { minutes = m } label: {
                        Text("\(m) min")
                            .font(Theme.text(14, weight: .semibold))
                            .foregroundStyle(minutes == m ? Theme.navy : Theme.cream)
                            .frame(maxWidth: .infinity).frame(height: 40)
                            .background(Capsule().fill(minutes == m ? Theme.cream : .white.opacity(0.10)))
                            .contentShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)

            Button { start() } label: {
                Text(finished ? "Again" : "Begin")
                    .font(Theme.text(17, weight: .semibold))
                    .foregroundStyle(Theme.navy)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Capsule().fill(Theme.cream))
                    .contentShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .sensoryFeedback(.impact(weight: .medium), trigger: running)
        }
    }

    private var timeLeft: String {
        String(format: "%d:%02d remaining", remaining / 60, remaining % 60)
    }

    private func start() {
        finished = false
        running = true
        startedAt = .now
        remaining = minutes * 60
        SoundManager.shared.start(soundscape)
        UIApplication.shared.isIdleTimerDisabled = true
        task?.cancel()
        task = Task { @MainActor in
            let end = Date().addingTimeInterval(Double(minutes * 60))
            while Date() < end, !Task.isCancelled {
                phaseText = "Breathe in"
                withAnimation(.easeInOut(duration: inhaleSeconds)) { inhale = true }
                try? await Task.sleep(for: .seconds(inhaleSeconds))
                guard !Task.isCancelled else { return }
                phaseText = "Breathe out"
                withAnimation(.easeInOut(duration: exhaleSeconds)) { inhale = false }
                try? await Task.sleep(for: .seconds(exhaleSeconds))
                remaining = max(Int(end.timeIntervalSinceNow.rounded()), 0)
            }
            guard !Task.isCancelled else { return }
            complete()
        }
    }

    private func complete() {
        running = false
        finished = true
        phaseText = "Ready when you are"
        if let startedAt { appState.logMindful(start: startedAt, end: .now) }
        startedAt = nil
        SoundManager.shared.stop()
        SoundManager.shared.playChime(enabled: appState.data.soundsOn)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func stopAll() {
        task?.cancel()
        if let startedAt { appState.logMindful(start: startedAt, end: .now) }
        startedAt = nil
        SoundManager.shared.stop()
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func end() {
        stopAll()
        dismiss()
    }
}
