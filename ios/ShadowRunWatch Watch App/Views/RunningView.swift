import SwiftUI
import WatchKit

struct RunningView: View {
    @ObservedObject var session = WatchSessionManager.shared
    @ObservedObject var healthKit = HealthKitManager.shared
    @State private var showJumpscare = false

    var body: some View {
        let data = session.runData

        ZStack {
            ScrollView {
                VStack(spacing: 4) {
                    // Threat bar (doppelganger mode only)
                    if data.runMode == "doppelganger" {
                        ThreatBarView(
                            threatLevel: data.threatLevel,
                            percent: data.threatPercent
                        )

                        Text(data.formattedShadowDistance)
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(data.shadowDistanceM >= 0 ? .green : .red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.5))
                            )
                    }

                    // Mini map
                    if data.latitude != 0 && data.longitude != 0 {
                        MiniMapView(
                            runnerLat: data.latitude,
                            runnerLon: data.longitude,
                            shadowLat: data.shadowLatitude,
                            shadowLon: data.shadowLongitude,
                            showShadow: data.runMode == "doppelganger"
                        )
                    }

                    // Main stats
                    VStack(spacing: 6) {
                        Text(data.formattedDistance)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        HStack(spacing: 16) {
                            VStack(spacing: 1) {
                                Text(data.formattedPace)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("pace")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }

                            VStack(spacing: 1) {
                                Text(data.formattedDuration)
                                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("time")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                        }

                        HStack(spacing: 16) {
                            VStack(spacing: 1) {
                                HStack(spacing: 2) {
                                    Image(systemName: "heart.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.red)
                                    Text(healthKit.currentHeartRate > 0
                                         ? "\(healthKit.currentHeartRate)"
                                         : "--")
                                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.white)
                                }
                                Text("bpm")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }

                            VStack(spacing: 1) {
                                Text("\(data.calories)")
                                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.white)
                                Text("kcal")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gray)
                            }
                        }
                    }

                    Spacer().frame(height: 4)

                    // Control buttons
                    HStack(spacing: 20) {
                        Button(action: {
                            session.sendCommand("toggleTts")
                        }) {
                            Image(systemName: data.ttsOn ? "mic.fill" : "mic.slash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(data.ttsOn ? .green : .gray)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 30, height: 30)

                        Button(action: {
                            session.sendCommand(
                                session.runState == .paused ? "resume" : "pause"
                            )
                        }) {
                            Image(systemName: session.runState == .paused
                                  ? "play.fill" : "pause.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.gray.opacity(0.3)))

                        Button(action: {
                            session.sendCommand("toggleSfx")
                        }) {
                            Image(systemName: data.sfxOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.system(size: 14))
                                .foregroundColor(data.sfxOn ? .green : .gray)
                        }
                        .buttonStyle(.plain)
                        .frame(width: 30, height: 30)
                    }

                    Button(action: {
                        session.sendCommand("stop")
                    }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.red.opacity(0.8)))
                    .padding(.top, 4)
                }
                .padding(.horizontal, 4)
            }

            if showJumpscare {
                JumpscareView {
                    showJumpscare = false
                }
            }
        }
        .onChange(of: data.threatLevel) { _, newLevel in
            if newLevel == "critical" {
                showJumpscare = true
                return
            }

            let device = WKInterfaceDevice.current()
            switch newLevel {
            case "dangerClose":
                device.play(.directionUp)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    device.play(.directionUp)
                }
            case "dangerFar":
                device.play(.directionUp)
            case "warningClose":
                device.play(.notification)
            case "warningFar":
                device.play(.click)
            default:
                break
            }
        }
    }
}
