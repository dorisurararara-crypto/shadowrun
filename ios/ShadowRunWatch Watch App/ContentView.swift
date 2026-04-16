import SwiftUI

struct ContentView: View {
    @ObservedObject var session = WatchSessionManager.shared

    var body: some View {
        switch session.runState {
        case .idle:
            WaitingView()
        case .running, .paused:
            RunningView()
        case .result:
            ResultView()
        }
    }
}
