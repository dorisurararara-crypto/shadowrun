import SwiftUI
import WatchKit

struct JumpscareView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 1.0
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            Color.red
                .opacity(opacity)
                .ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.black)
                    .scaleEffect(scale)

                Text("CAUGHT")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.black)
            }
        }
        .onAppear {
            let device = WKInterfaceDevice.current()
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                    device.play(.failure)
                }
            }

            withAnimation(.easeIn(duration: 0.1)) { opacity = 1.0 }
            withAnimation(.easeInOut(duration: 0.3).repeatCount(5, autoreverses: true)) {
                scale = 1.3
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}
