import SwiftUI
import StoreKit

/// Premium upgrade screen with a transparent 7-day free trial timeline.
/// Includes everything App Review requires: price, period, auto-renew terms,
/// Restore Purchases, Terms of Use and Privacy Policy links, and a close button.
struct PaywallView: View {
    @EnvironmentObject private var store: StoreManager
    @Environment(\.dismiss) private var dismiss

    /// Used by onboarding; when nil the paywall dismisses itself as a sheet.
    var onFinish: (() -> Void)? = nil

    @State private var selectedID = AppConfig.yearlyProductID
    @State private var trialEligible = true
    @State private var isPurchasing = false
    @State private var errorMessage: String?

    private var selected: Product? { store.products.first { $0.id == selectedID } ?? store.products.first }
    private var showsTrial: Bool { trialEligible && !(selected?.isLifetime ?? false) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            AppBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    features
                    if showsTrial { trialTimeline }
                    plans
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom) { bottomBar }

            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.secondary)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Theme.surface))
            }
            .padding(.trailing, 20)
            .padding(.top, 12)
            .accessibilityLabel("Close")
        }
        .task {
            await store.loadProducts()
            trialEligible = await store.isTrialEligible(for: store.yearly ?? store.products.first)
        }
        .alert("Something went wrong", isPresented: .constant(errorMessage != nil)) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            LogoMark(size: 60)
            VStack(alignment: .leading, spacing: 8) {
                Text("Lumina Premium")
                    .font(Theme.display(34, weight: .bold))
                    .tracking(-0.8)
                    .foregroundStyle(Theme.ink)
                Text("Everything you need for a daily practice that sticks.")
                    .font(Theme.text(17))
                    .foregroundStyle(Theme.secondary)
            }
        }
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 14) {
            feature("All 7 categories and all 12 card themes")
            feature("Record affirmations in your own voice")
            feature("Every soundscape for breathing and wind-down")
            feature("Up to 6 reminders a day and 3 streak freezes")
            feature("Unlimited personal manifestations")
        }
    }

    private func feature(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: "checkmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Theme.accent)
            Text(text)
                .font(Theme.text(16))
                .foregroundStyle(Theme.ink)
        }
    }

    private var trialTimeline: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                Text("How your free trial works")
                    .font(Theme.text(15, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .padding(.bottom, 16)
                timelineRow("Today", "Unlock everything in Premium.", isLast: false)
                timelineRow("Day 5", "We'll remind you the trial is ending.", isLast: false)
                timelineRow("Day 7", "Subscription starts. Cancel anytime before.", isLast: true)
            }
        }
    }

    private func timelineRow(_ title: String, _ detail: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(Theme.accent)
                    .frame(width: 10, height: 10)
                    .padding(.top, 5)
                if !isLast {
                    Rectangle().fill(Theme.hairline).frame(width: 2).frame(maxHeight: .infinity)
                }
            }
            .frame(width: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(Theme.text(15, weight: .semibold)).foregroundStyle(Theme.ink)
                Text(detail).font(Theme.text(14)).foregroundStyle(Theme.secondary)
            }
            .padding(.bottom, isLast ? 0 : 16)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var plans: some View {
        if store.products.isEmpty {
            HStack {
                Spacer()
                ProgressView()
                Spacer()
            }
            .frame(height: 140)
        } else {
            VStack(spacing: 10) {
                ForEach(store.products) { product in
                    planRow(product)
                }
            }
        }
    }

    private func planRow(_ product: Product) -> some View {
        let isSelected = product.id == selected?.id
        let isYearly = product.id == AppConfig.yearlyProductID
        let title = product.isLifetime ? "Lifetime" : (isYearly ? "Yearly" : "Monthly")
        return Button {
            selectedID = product.id
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Theme.accent : Theme.hairline)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(Theme.text(17, weight: .semibold))
                            .foregroundStyle(Theme.ink)
                        if isYearly, let savings = store.yearlySavingsPercent {
                            Text("Save \(savings)%")
                                .font(Theme.text(12, weight: .semibold))
                                .foregroundStyle(Theme.accent)
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(Capsule().fill(Theme.accentSoft))
                        }
                    }
                    Text(product.isLifetime ? "Pay once, keep forever"
                         : (product.monthlyEquivalent.map { "\($0) / month, 7 days free" } ?? "7 days free, cancel anytime"))
                        .font(Theme.text(14))
                        .foregroundStyle(Theme.secondary)
                }
                Spacer()
                Text(product.isLifetime ? product.displayPrice
                     : "\(product.displayPrice) / \(product.periodWord == "year" ? "yr" : "mo")")
                    .font(Theme.text(16, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                    .monospacedDigit()
            }
            .padding(18)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Theme.surface))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(isSelected ? Theme.accent : Theme.hairline, lineWidth: isSelected ? 2 : 0.5))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedID)
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Button {
                Task { await buy() }
            } label: {
                if isPurchasing {
                    ProgressView().tint(Theme.bg)
                } else {
                    Text(showsTrial ? "Start 7-Day Free Trial" : (selected?.isLifetime == true ? "Unlock Forever" : "Continue"))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selected == nil || isPurchasing)

            finePrint

            HStack(spacing: 16) {
                Button("Restore") { Task { await restore() } }
                Link("Terms", destination: AppConfig.termsURL)
                Link("Privacy", destination: AppConfig.privacyURL)
            }
            .font(Theme.text(13, weight: .medium))
            .foregroundStyle(Theme.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 8)
        .background(Theme.bg.opacity(0.96).ignoresSafeArea())
        .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 0.5) }
    }

    private var finePrint: some View {
        Group {
            if let product = selected {
                if product.isLifetime {
                    Text("One-time purchase of \(product.displayPrice). No subscription, no renewals. Yours forever on this Apple ID.")
                } else if trialEligible {
                    Text("Free for 7 days, then \(product.displayPrice)/\(product.periodWord). Charged to your Apple ID when the trial ends. Renews automatically unless canceled at least 24 hours before the period ends. Cancel anytime in Settings.")
                } else {
                    Text("\(product.displayPrice)/\(product.periodWord), charged to your Apple ID at confirmation. Renews automatically unless canceled at least 24 hours before the period ends. Cancel anytime in Settings.")
                }
            }
        }
        .font(Theme.text(11))
        .foregroundStyle(Theme.secondary)
        .multilineTextAlignment(.center)
    }

    // MARK: Actions

    private func buy() async {
        guard let product = selected else { return }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let startedTrial = showsTrial
            if try await store.purchase(product) {
                if startedTrial { NotificationManager.shared.scheduleTrialEndingReminder() }
                close()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func restore() async {
        do {
            try await store.restore()
            if store.isPremium { close() } else { errorMessage = "We didn't find an active Lumina Premium subscription for this Apple ID." }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func close() {
        if let onFinish { onFinish() } else { dismiss() }
    }
}
