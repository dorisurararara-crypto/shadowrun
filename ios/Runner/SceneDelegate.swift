import Flutter
import UIKit
import WatchConnectivity

class SceneDelegate: FlutterSceneDelegate {
    private var watchChannel: FlutterMethodChannel?

    override func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        super.scene(scene, willConnectTo: session, options: connectionOptions)

        guard let windowScene = scene as? UIWindowScene,
              let controller = windowScene.keyWindow?.rootViewController as? FlutterViewController else {
            return
        }

        setupChannels(with: controller)
    }

    private func setupChannels(with controller: FlutterViewController) {
        // MethodChannel: Flutter -> iOS -> Watch (commands)
        watchChannel = FlutterMethodChannel(
            name: "com.ganziman.shadowrun/watch",
            binaryMessenger: controller.binaryMessenger
        )
        watchChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }

        // EventChannel: Watch -> iOS -> Flutter (watch messages)
        let eventChannel = FlutterEventChannel(
            name: "com.ganziman.shadowrun/watch_events",
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel.setStreamHandler(WatchEventStreamHandler.shared)

        // HealthKit channel
        let healthChannel = FlutterMethodChannel(
            name: "com.ganziman.shadowrun/health",
            binaryMessenger: controller.binaryMessenger
        )
        healthChannel.setMethodCallHandler { call, result in
            HealthKitHandler.shared.handle(call, result: result)
        }

        // Connect watch callback to Flutter event stream
        WatchSessionHandler.shared.setFlutterCallback { message in
            WatchEventStreamHandler.shared.send(message)
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "sendRunData":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "ARGS", message: "Invalid arguments", details: nil))
                return
            }
            WatchSessionHandler.shared.sendRunData(args)
            result(nil)
        case "sendAppContext":
            guard let args = call.arguments as? [String: Any] else {
                result(FlutterError(code: "ARGS", message: "Invalid arguments", details: nil))
                return
            }
            WatchSessionHandler.shared.sendAppContext(args)
            result(nil)
        case "isWatchReachable":
            result(WCSession.default.isReachable)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
