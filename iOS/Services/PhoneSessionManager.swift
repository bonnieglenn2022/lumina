import Foundation
import WatchConnectivity

/// Sends today's manifestation, the coming week, favorites and streak to the Apple Watch,
/// and receives "I receive this" check-ins back from it.
final class PhoneSessionManager: NSObject, WCSessionDelegate {
    static let shared = PhoneSessionManager()
    private var pending: WatchSnapshot?

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func push(_ snapshot: WatchSnapshot) {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { pending = snapshot; return }
        guard session.isPaired, session.isWatchAppInstalled,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        try? session.updateApplicationContext(["snapshot": data, "ts": Date().timeIntervalSince1970])
    }

    // MARK: WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if activationState == .activated, let snapshot = pending {
            pending = nil
            push(snapshot)
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        handle(userInfo)
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        handle(message)
    }

    private func handle(_ info: [String: Any]) {
        switch info["action"] as? String {
        case "affirm":
            Task { @MainActor in AppState.shared.checkIn() }
        case "requestSync":
            Task { @MainActor in AppState.shared.refresh() }
        default:
            break
        }
    }
}
