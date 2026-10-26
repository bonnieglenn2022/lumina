import Foundation
import WatchConnectivity
import WatchKit
import WidgetKit

/// Receives the daily package from iPhone and sends "I receive this" check-ins back.
final class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published private(set) var snapshot: WatchSnapshot

    override init() {
        if DemoMode.isOn, let demo = DemoMode.affirmation {
            let day = DailyPicker.dayNumber(for: .now)
            snapshot = WatchSnapshot(name: DemoMode.name,
                                     week: [.init(day: day, text: demo.text, category: demo.categoryTitle)],
                                     favorites: ["I am calm, centered, and grounded.", "I find something beautiful in every moment."],
                                     streak: DemoMode.streak,
                                     checkedInDay: -1,
                                     themeID: "moonlit")
        } else {
            snapshot = WatchSnapshot.load()
        }
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    var today: WatchSnapshot.DayItem { snapshot.item(for: .now) }

    var checkedInToday: Bool { snapshot.checkedInDay == DailyPicker.dayNumber(for: .now) }

    func affirm() {
        guard !checkedInToday else { return }
        var updated = snapshot
        updated.checkedInDay = DailyPicker.dayNumber(for: .now)
        updated.streak = max(updated.streak, 0) + 1
        apply(updated)
        WKInterfaceDevice.current().play(.success)
        if WCSession.default.activationState == .activated {
            WCSession.default.transferUserInfo(["action": "affirm", "ts": Date().timeIntervalSince1970])
        }
    }

    private func apply(_ new: WatchSnapshot) {
        new.save()
        DispatchQueue.main.async {
            self.snapshot = new
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func ingest(_ context: [String: Any]) {
        guard let data = context["snapshot"] as? Data,
              let decoded = try? JSONDecoder().decode(WatchSnapshot.self, from: data) else { return }
        apply(decoded)
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        guard activationState == .activated else { return }
        if !session.receivedApplicationContext.isEmpty {
            ingest(session.receivedApplicationContext)
        }
        if session.isReachable {
            session.sendMessage(["action": "requestSync"], replyHandler: nil, errorHandler: nil)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        ingest(applicationContext)
    }
}
