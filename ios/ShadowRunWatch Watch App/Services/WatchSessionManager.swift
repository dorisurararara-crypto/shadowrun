import Foundation
import WatchConnectivity
import WatchKit
import Combine

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate, WKExtendedRuntimeSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var isPhoneReachable = false
    @Published var runData = RunData()
    @Published var runState: RunState = .idle

    enum RunState: String {
        case idle, running, paused, result
    }

    private var heartRateTimer: Timer?
    // reachable=false 구간에 발생한 "중요 명령" (pause/resume/stop 등) 을 저장했다가
    // 연결 복구 시 일괄 전송. heartRate 같은 실시간 스냅샷은 큐잉하지 않음 (드롭).
    private var pendingMessages: [[String: Any]] = []
    // 러닝 중 Watch 앱이 백그라운드 suspend 되지 않도록 유지하는 세션.
    // start 후 보통 최소 15~30분 동안 화면·앱 활성 유지 (WKExtendedRuntimeSession).
    private var extendedSession: WKExtendedRuntimeSession?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    /// Watch → iPhone 명령 전송.
    /// - isImportant=true (기본): reachable=false 면 큐잉, 복구 시 자동 flush.
    /// - isImportant=false: 실시간 스냅샷(heartRate 등), 놓쳐도 다음 틱에 복구되는 데이터는 큐잉하지 않음.
    func sendCommand(_ command: String, data: [String: Any] = [:], isImportant: Bool = true) {
        var message = data
        message["command"] = command
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil) { [weak self] error in
                print("Watch send error: \(error.localizedDescription) cmd=\(command)")
                if isImportant {
                    DispatchQueue.main.async { self?.pendingMessages.append(message) }
                }
            }
        } else if isImportant {
            print("[WatchSession] not reachable — queuing cmd=\(command)")
            pendingMessages.append(message)
        }
    }

    private func flushPending() {
        guard WCSession.default.isReachable, !pendingMessages.isEmpty else { return }
        let snapshot = pendingMessages
        pendingMessages.removeAll()
        print("[WatchSession] flushing \(snapshot.count) pending messages")
        for m in snapshot {
            WCSession.default.sendMessage(m, replyHandler: nil) { [weak self] error in
                print("Watch flush send error: \(error.localizedDescription)")
                DispatchQueue.main.async { self?.pendingMessages.append(m) }
            }
        }
    }

    // MARK: - Extended Runtime Session (러닝 중 Watch 앱 keep-alive)

    private func startExtendedRuntime() {
        if let s = extendedSession, s.state == .running { return }
        let s = WKExtendedRuntimeSession()
        s.delegate = self
        s.start(at: Date())
        extendedSession = s
    }

    private func stopExtendedRuntime() {
        extendedSession?.invalidate()
        extendedSession = nil
    }

    func extendedRuntimeSessionDidStart(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("[ExtendedRuntime] started")
    }

    func extendedRuntimeSessionWillExpire(_ extendedRuntimeSession: WKExtendedRuntimeSession) {
        print("[ExtendedRuntime] will expire — running session may outlast keep-alive window")
    }

    func extendedRuntimeSession(_ extendedRuntimeSession: WKExtendedRuntimeSession,
                                didInvalidateWith reason: WKExtendedRuntimeSessionInvalidationReason,
                                error: Error?) {
        print("[ExtendedRuntime] invalidated reason=\(reason.rawValue) err=\(error?.localizedDescription ?? "-")")
        self.extendedSession = nil
    }

    func startHeartRateSync() {
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            let hr = HealthKitManager.shared.currentHeartRate
            if hr > 0 {
                self?.sendCommand("heartRate", data: ["heartRate": hr], isImportant: false)
            }
        }
    }

    func stopHeartRateSync() {
        heartRateTimer?.invalidate()
        heartRateTimer = nil
    }

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
            self.flushPending()
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.processMessage(message)
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        DispatchQueue.main.async {
            self.processMessage(applicationContext)
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isPhoneReachable = session.isReachable
            if session.isReachable { self.flushPending() }
        }
    }

    private func processMessage(_ message: [String: Any]) {
        if let stateStr = message["runState"] as? String,
           let state = RunState(rawValue: stateStr) {
            let previousState = runState
            runState = state
            if state == .running && previousState != .running {
                HealthKitManager.shared.requestAuthorization()
                startHeartRateSync()
                startExtendedRuntime()
            } else if state == .idle || state == .result {
                stopHeartRateSync()
                stopExtendedRuntime()
                if state == .idle {
                    HealthKitManager.shared.stopHeartRateQuery()
                }
            } else if state == .paused {
                stopHeartRateSync()
                // extendedSession 은 paused 에서 유지 — 곧 resume 가능하므로.
            }
        }

        if let dist = message["distanceM"] as? Double { runData.distanceM = dist }
        if let dur = message["durationS"] as? Int { runData.durationS = dur }
        if let pace = message["avgPace"] as? Double { runData.avgPace = pace }
        if let cal = message["calories"] as? Int { runData.calories = cal }
        if let hr = message["heartRate"] as? Int { runData.heartRate = hr }
        if let threat = message["threatLevel"] as? String { runData.threatLevel = threat }
        if let shadowDist = message["shadowDistanceM"] as? Double { runData.shadowDistanceM = shadowDist }
        if let threatPct = message["threatPercent"] as? Double { runData.threatPercent = threatPct }
        if let lat = message["latitude"] as? Double { runData.latitude = lat }
        if let lon = message["longitude"] as? Double { runData.longitude = lon }
        if let sLat = message["shadowLatitude"] as? Double { runData.shadowLatitude = sLat }
        if let sLon = message["shadowLongitude"] as? Double { runData.shadowLongitude = sLon }
        if let mode = message["runMode"] as? String { runData.runMode = mode }
        if let ttsOn = message["ttsOn"] as? Bool { runData.ttsOn = ttsOn }
        if let sfxOn = message["sfxOn"] as? Bool { runData.sfxOn = sfxOn }
        if let result = message["challengeResult"] as? String { runData.challengeResult = result }

        // RunData 중첩 변경이 SwiftUI를 갱신하도록 WatchSessionManager 자체도 변경 알림
        objectWillChange.send()
    }
}
