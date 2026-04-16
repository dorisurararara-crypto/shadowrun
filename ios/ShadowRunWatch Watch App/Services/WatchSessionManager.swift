import Foundation
import WatchConnectivity
import Combine

class WatchSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    @Published var isPhoneReachable = false
    @Published var runData = RunData()
    @Published var runState: RunState = .idle

    enum RunState: String {
        case idle, running, paused, result
    }

    private var heartRateTimer: Timer?

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendCommand(_ command: String, data: [String: Any] = [:]) {
        var message = data
        message["command"] = command
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(message, replyHandler: nil) { error in
            print("Watch send error: \(error.localizedDescription)")
        }
    }

    func startHeartRateSync() {
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            let hr = HealthKitManager.shared.currentHeartRate
            if hr > 0 {
                self?.sendCommand("heartRate", data: ["heartRate": hr])
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
            } else if state == .idle || state == .result {
                stopHeartRateSync()
                if state == .idle {
                    HealthKitManager.shared.stopHeartRateQuery()
                }
            } else if state == .paused {
                stopHeartRateSync()
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
