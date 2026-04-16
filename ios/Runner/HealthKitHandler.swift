import Foundation
import HealthKit
import Flutter

class HealthKitHandler: NSObject {
    static let shared = HealthKitHandler()

    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestAuthorization":
            requestAuth(result: result)
        case "startHeartRateStream":
            startStream(result: result)
        case "stopHeartRateStream":
            stopStream()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func requestAuth(result: @escaping FlutterResult) {
        guard HKHealthStore.isHealthDataAvailable() else {
            result(false)
            return
        }
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, _ in
            DispatchQueue.main.async { result(success) }
        }
    }

    private func startStream(result: @escaping FlutterResult) {
        guard let hrType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            result(nil)
            return
        }
        stopStream()

        let query = HKAnchoredObjectQuery(
            type: hrType, predicate: nil, anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.sendLatestHR(samples)
        }
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.sendLatestHR(samples)
        }
        healthStore.execute(query)
        heartRateQuery = query
        result(nil)
    }

    private func stopStream() {
        if let q = heartRateQuery {
            healthStore.stop(q)
            heartRateQuery = nil
        }
    }

    private func sendLatestHR(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample],
              let latest = samples.last else { return }
        let unit = HKUnit.count().unitDivided(by: .minute())
        let hr = Int(latest.quantity.doubleValue(for: unit))
        DispatchQueue.main.async {
            WatchEventStreamHandler.shared.send(["command": "heartRate", "heartRate": hr])
        }
    }
}
