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

    // Watch 쪽 reachable 상태 변화 콜백. 미구현 상태에선 WCSession 프레임워크가
    // "delegate does not implement" 경고를 찍는다. 로깅만으로도 경고 제거됨.
    // WCSession 은 application context / user info 를 자동 큐잉·재전송 하므로
    // 여기서 수동 재전송은 불필요. 향후 custom 큐가 생기면 여기서 flush.
    func sessionReachabilityDidChange(_ session: WCSession) {
        print("WatchSession reachability changed: isReachable=\(session.isReachable)")
    }
}
