import SwiftUI

struct WaitingView: View {
    @ObservedObject var session = WatchSessionManager.shared
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 12) {
            Text("SHADOW")
                .font(.system(size: 20, weight: .black))
                .foregroundColor(.green)
            Text("RUN")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(.white)

            Spacer().frame(height: 8)

            if session.isPhoneReachable {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.title3)
                    .foregroundColor(.green)
                Text("Phone Connected")
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text("Start run on phone")
                    .font(.caption2)
                    .foregroundColor(.gray)
            } else {
                Image(systemName: "iphone.slash")
                    .font(.title3)
                    .foregroundColor(.red)
                    .scaleEffect(pulseScale)
                    .animation(
                        .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                        value: pulseScale
                    )
                    .onAppear { pulseScale = 1.2 }
                Text("Open Shadow Run\non your iPhone")
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
