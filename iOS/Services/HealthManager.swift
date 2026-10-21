import Foundation
import HealthKit

/// Optional Apple Health integration (user turns it on in Settings):
/// • Mindful Minutes after each Breathe / Wind-down session
/// • State of Mind (iOS 18+) from the daily mood check-in
/// Lumina only writes to Health; it never reads Health data.
final class HealthManager {
    static let shared = HealthManager()
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var shareTypes: Set<HKSampleType> {
        var types: Set<HKSampleType> = [HKCategoryType(.mindfulSession)]
        if #available(iOS 18.0, *) {
            types.insert(HKObjectType.stateOfMindType())
        }
        return types
    }

    func requestAuthorization() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await store.requestAuthorization(toShare: shareTypes, read: [])
            return true
        } catch {
            return false
        }
    }

    func saveMindfulSession(start: Date, end: Date) async {
        guard isAvailable, end.timeIntervalSince(start) >= 30 else { return }
        let sample = HKCategorySample(type: HKCategoryType(.mindfulSession),
                                      value: HKCategoryValue.notApplicable.rawValue,
                                      start: start,
                                      end: end)
        try? await store.save(sample)
    }

    /// `level` is 1 (low) … 5 (great).
    func saveMood(level: Int) async {
        guard isAvailable else { return }
        if #available(iOS 18.0, *) {
            let valence = Double(level - 3) / 2.0
            let label: HKStateOfMind.Label
            switch level {
            case 1: label = .sad
            case 2: label = .stressed
            case 3: label = .indifferent
            case 4: label = .calm
            default: label = .grateful
            }
            let sample = HKStateOfMind(date: .now,
                                       kind: .momentaryEmotion,
                                       valence: valence,
                                       labels: [label],
                                       associations: [.selfCare])
            try? await store.save(sample)
        }
    }
}
