import Foundation
import Combine

class RunData: ObservableObject {
    @Published var distanceM: Double = 0
    @Published var durationS: Int = 0
    @Published var avgPace: Double = 0
    @Published var calories: Int = 0
    @Published var heartRate: Int = 0
    @Published var threatLevel: String = "safe"
    @Published var shadowDistanceM: Double = 0
    @Published var threatPercent: Double = 0
    @Published var latitude: Double = 0
    @Published var longitude: Double = 0
    @Published var shadowLatitude: Double = 0
    @Published var shadowLongitude: Double = 0
    @Published var runMode: String = "doppelganger"
    @Published var ttsOn: Bool = true
    @Published var sfxOn: Bool = true
    @Published var challengeResult: String? = nil

    var formattedDistance: String {
        if distanceM >= 1000 {
            return String(format: "%.2f km", distanceM / 1000)
        }
        return String(format: "%.0f m", distanceM)
    }

    var formattedPace: String {
        guard distanceM > 0 else { return "--'--\"" }
        let paceSeconds = Double(durationS) / (distanceM / 1000)
        let minutes = Int(paceSeconds) / 60
        let seconds = Int(paceSeconds) % 60
        return String(format: "%d'%02d\"", minutes, seconds)
    }

    var formattedDuration: String {
        let h = durationS / 3600
        let m = (durationS % 3600) / 60
        let s = durationS % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%02d:%02d", m, s)
    }

    var formattedShadowDistance: String {
        let absDist = abs(shadowDistanceM)
        if shadowDistanceM >= 0 {
            return String(format: "+%.0fm", absDist)
        }
        return String(format: "-%.0fm", absDist)
    }
}
