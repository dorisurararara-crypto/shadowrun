import SwiftUI
import WatchKit

struct ResultView: View {
    @ObservedObject var session = WatchSessionManager.shared
    @ObservedObject var healthKit = HealthKitManager.shared

    var resultTitle: String {
        switch session.runData.challengeResult {
        case "win": return "SURVIVED"
        case "lose": return "CAUGHT"
        default: return "COMPLETE"
        }
    }

    var resultColor: Color {
        switch session.runData.challengeResult {
        case "win": return .green
        case "lose": return .red
        default: return .blue
        }
    }

    var body: some View {
        let data = session.runData

        ScrollView {
            VStack(spacing: 8) {
                Text(resultTitle)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(resultColor)

                Divider().background(Color.gray.opacity(0.5))

                VStack(spacing: 6) {
                    HStack {
                        statItem(value: data.formattedDistance, label: "distance")
                        statItem(value: data.formattedDuration, label: "time")
                    }
                    HStack {
                        statItem(value: data.formattedPace, label: "pace")
                        statItem(
                            value: healthKit.currentHeartRate > 0
                                ? "\(healthKit.currentHeartRate)" : "--",
                            label: "avg bpm",
                            icon: "heart.fill",
                            iconColor: .red
                        )
                    }
                }

                Divider().background(Color.gray.opacity(0.5))

                Button(action: {
                    session.sendCommand("dismiss")
                    session.runState = .idle
                    healthKit.stopHeartRateQuery()
                }) {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.system(size: 12))
                        Text("Home")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.green)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            let type: WKHapticType = session.runData.challengeResult == "win"
                ? .success : .failure
            WKInterfaceDevice.current().play(type)
        }
    }

    private func statItem(
        value: String, label: String,
        icon: String? = nil, iconColor: Color = .white
    ) -> some View {
        VStack(spacing: 2) {
            if let icon = icon {
                HStack(spacing: 2) {
                    Image(systemName: icon)
                        .font(.system(size: 8))
                        .foregroundColor(iconColor)
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            } else {
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}
