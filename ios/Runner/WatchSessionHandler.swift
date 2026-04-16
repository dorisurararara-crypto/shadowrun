import Foundation
import WatchConnectivity

class WatchSessionHandler: NSObject, WCSessionDelegate {
    static let shared = WatchSessionHandler()

    private var session: WCSession?
    private var flutterCallback: (([String: Any]) -> Void)?

    func startSession() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }

    func setFlutterCallback(_ callback: @escaping ([String: Any]) -> Void) {
        flutterCallback = callback
    }

    func sendRunData(_ data: [String: Any]) {
        guard let session = session, session.isReachable else {
            // Fallback to application context for non-urgent data
            try? session?.updateApplicationContext(data)
            return
        }
        session.sendMessage(data, replyHandler: nil) { error in
            print("WatchSession send error: \(error.localizedDescription)")
            try? self.session?.updateApplicationContext(data)
        }
    }

    func sendAppContext(_ data: [String: Any]) {
        try? session?.updateApplicationContext(data)
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WatchSession activated: \(activationState.rawValue)")
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.flutterCallback?(message)
        }
    }
}
