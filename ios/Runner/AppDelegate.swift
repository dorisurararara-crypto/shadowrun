import Flutter
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        // Start WatchConnectivity early (doesn't need Flutter channels yet)
        WatchSessionHandler.shared.startSession()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

class WatchEventStreamHandler: NSObject, FlutterStreamHandler {
    static let shared = WatchEventStreamHandler()
    private var eventSink: FlutterEventSink?

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }

    func send(_ data: [String: Any]) {
        DispatchQueue.main.async {
            self.eventSink?(data)
        }
    }
}
