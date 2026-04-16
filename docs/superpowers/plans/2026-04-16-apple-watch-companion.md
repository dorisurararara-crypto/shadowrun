# Apple Watch Companion App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Shadow Run Flutter 앱의 Apple Watch 컴패니언 앱을 만들어, 러닝 중 실시간 데이터(거리/페이스/시간/칼로리/심박수/도플갱어 위협 레벨)를 워치에서 보고 조작할 수 있게 한다.

**Architecture:** Flutter(Dart) ↔ MethodChannel/EventChannel ↔ iOS AppDelegate(Swift) ↔ WatchConnectivity ↔ watchOS App(SwiftUI). 폰이 메인 로직을 실행하고, 워치는 컴패니언 디스플레이+리모컨 역할. 심박수는 HealthKit API 하나로 워치 센서와 AirPods Pro 3 모두 지원.

**Tech Stack:** SwiftUI (watchOS 10+), WatchConnectivity, HealthKit, MapKit, Flutter MethodChannel/EventChannel

---

## File Structure

### watchOS Side (새로 생성)
```
ios/
├── ShadowRunWatch/                    # watchOS App target
│   ├── ShadowRunWatchApp.swift        # App entry point
│   ├── ContentView.swift              # Root view (상태별 화면 전환)
│   ├── Views/
│   │   ├── WaitingView.swift          # 대기 화면 (START 버튼 또는 폰 연결 대기)
│   │   ├── RunningView.swift          # 러닝 중 메인 화면
│   │   ├── MiniMapView.swift          # MapKit 미니맵 (러너+도플갱어 위치)
│   │   ├── ThreatBarView.swift        # 위협 레벨 프로그레스 바
│   │   ├── ResultView.swift           # 결과 화면
│   │   └── JumpscareView.swift        # 점프스케어 (빨간 화면 + 진동)
│   ├── Services/
│   │   ├── WatchSessionManager.swift  # WatchConnectivity 수신/송신
│   │   └── HealthKitManager.swift     # 심박수 읽기 (워치센서 + AirPods)
│   ├── Models/
│   │   └── RunData.swift              # 폰에서 받은 데이터 모델
│   ├── Assets.xcassets/               # 워치 앱 아이콘
│   └── Info.plist                     # 워치 앱 설정
```

### iOS (Flutter) Side (수정)
```
ios/
├── Runner/
│   ├── AppDelegate.swift              # 수정: MethodChannel + WatchConnectivity 추가
│   ├── WatchSessionHandler.swift      # 새로 생성: WatchConnectivity iOS 측 핸들러
│   └── Info.plist                     # 수정: HealthKit 권한 추가
```

### Flutter (Dart) Side (수정/추가)
```
lib/
├── core/
│   ├── services/
│   │   ├── watch_connector_service.dart   # 새로 생성: MethodChannel로 워치 통신
│   │   ├── health_service.dart            # 새로 생성: HealthKit 심박수 읽기
│   │   └── running_service.dart           # 수정: 워치에 데이터 전송 연동
│   └── ...
├── features/
│   └── running/
│       └── presentation/
│           └── pages/
│               └── running_screen.dart    # 수정: 심박수 표시 + 워치 토글 수신
```

---

## Task 1: Xcode 프로젝트에 watchOS Target 추가

**Files:**
- Modify: `ios/Runner.xcodeproj/project.pbxproj`
- Create: `ios/ShadowRunWatch/ShadowRunWatchApp.swift`
- Create: `ios/ShadowRunWatch/ContentView.swift`
- Create: `ios/ShadowRunWatch/Info.plist`
- Create: `ios/ShadowRunWatch/Assets.xcassets/`

> **NOTE:** 이 태스크는 Mac의 Xcode에서 수행해야 합니다. `project.pbxproj`를 수동 편집하는 것은 위험하므로 Xcode GUI를 사용합니다.

- [ ] **Step 1: Mac에서 프로젝트 열기**

```bash
cd /path/to/shadowrun
open ios/Runner.xcworkspace
```

- [ ] **Step 2: watchOS Target 추가**

Xcode에서:
1. File → New → Target
2. watchOS → App 선택
3. 설정:
   - Product Name: `ShadowRunWatch`
   - Bundle Identifier: `com.ganziman.shadowrun.watch`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Watch App for Existing iOS App: **Runner** 선택
   - Include Notification Scene: 체크 해제
4. Finish 클릭
5. "Activate ShadowRunWatch scheme?" → Activate

- [ ] **Step 3: Deployment Target 설정**

Xcode에서 ShadowRunWatch 타겟 선택 → General:
- Minimum Deployments: **watchOS 10.0**
- (Apple Watch SE 2세대는 watchOS 10 지원)

- [ ] **Step 4: 기본 앱 코드 작성**

`ios/ShadowRunWatch/ShadowRunWatchApp.swift`:
```swift
import SwiftUI

@main
struct ShadowRunWatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

`ios/ShadowRunWatch/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("SHADOW RUN")
            .font(.headline)
            .foregroundColor(.green)
    }
}
```

- [ ] **Step 5: 빌드 테스트**

1. Xcode에서 ShadowRunWatch scheme 선택
2. 시뮬레이터: Apple Watch SE (44mm) 선택
3. Cmd+B로 빌드 확인
4. Cmd+R로 실행 → "SHADOW RUN" 텍스트 표시 확인

- [ ] **Step 6: 커밋**

```bash
git add ios/ShadowRunWatch/ ios/Runner.xcodeproj/
git commit -m "feat: add watchOS target skeleton for Apple Watch companion app"
```

---

## Task 2: WatchConnectivity 설정 (iOS ↔ watchOS 통신 채널)

**Files:**
- Create: `ios/Runner/WatchSessionHandler.swift`
- Modify: `ios/Runner/AppDelegate.swift`
- Create: `ios/ShadowRunWatch/Services/WatchSessionManager.swift`

- [ ] **Step 1: iOS 측 WatchConnectivity 핸들러 작성**

`ios/Runner/WatchSessionHandler.swift`:
```swift
import Foundation
import WatchConnectivity

class WatchSessionHandler: NSObject, WCSessionDelegate {
    static let shared = WatchSessionHandler()
    
    private var session: WCSession?
    private var flutterCallback: (([String: Any]) -> Void)?
    
    func startSession() {
        guard WCSession.isSupported() else { return }
        session = WCSession.default
        session?.delegate = self
        session?.activate()
    }
    
    func setFlutterCallback(_ callback: @escaping ([String: Any]) -> Void) {
        flutterCallback = callback
    }
    
    func sendRunData(_ data: [String: Any]) {
        guard let session = session, session.isReachable else { return }
        session.sendMessage(data, replyHandler: nil) { error in
            print("WatchSession send error: \(error.localizedDescription)")
            // Fallback to application context for non-urgent data
            try? session.updateApplicationContext(data)
        }
    }
    
    func sendAppContext(_ data: [String: Any]) {
        try? session?.updateApplicationContext(data)
    }
    
    // MARK: - WCSessionDelegate
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WatchSession activated: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        DispatchQueue.main.async {
            self.flutterCallback?(message)
        }
    }
}
```

- [ ] **Step 2: AppDelegate에 WatchSession + MethodChannel 연결**

`ios/Runner/AppDelegate.swift`를 다음으로 교체:
```swift
import Flutter
import UIKit
import WatchConnectivity

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var watchChannel: FlutterMethodChannel?
    private var watchEventSink: FlutterEventSink?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        let controller = window?.rootViewController as! FlutterViewController

        // MethodChannel: Flutter → iOS → Watch (commands)
        watchChannel = FlutterMethodChannel(
            name: "com.ganziman.shadowrun/watch",
            binaryMessenger: controller.binaryMessenger
        )
        watchChannel?.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }

        // EventChannel: Watch → iOS → Flutter (watch messages)
        let eventChannel = FlutterEventChannel(
            name: "com.ganziman.shadowrun/watch_events",
            binaryMessenger: controller.binaryMessenger
        )
        eventChannel.setStreamHandler(WatchEventStreamHandler.shared)

        // Start WatchConnectivity
        WatchSessionHandler.shared.startSession()
        WatchSessionHandler.shared.setFlutterCallback { message in
            WatchEventStreamHandler.shared.send(message)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
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
```

- [ ] **Step 3: watchOS 측 WatchSessionManager 작성**

`ios/ShadowRunWatch/Services/WatchSessionManager.swift`:
```swift
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
            runState = state
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
    }
}
```

- [ ] **Step 4: RunData 모델 작성**

`ios/ShadowRunWatch/Models/RunData.swift`:
```swift
import Foundation

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
    
    var threatColor: String {
        switch threatLevel {
        case "aheadFar", "aheadMid", "aheadClose": return "green"
        case "safe": return "blue"
        case "warningFar", "warningClose": return "yellow"
        case "dangerFar", "dangerClose": return "orange"
        case "critical": return "red"
        default: return "gray"
        }
    }
}
```

- [ ] **Step 5: 빌드 테스트**

1. iOS 타겟(Runner) 빌드 → 에러 없는지 확인
2. watchOS 타겟(ShadowRunWatch) 빌드 → 에러 없는지 확인

- [ ] **Step 6: 커밋**

```bash
git add ios/Runner/WatchSessionHandler.swift ios/Runner/AppDelegate.swift \
  ios/ShadowRunWatch/Services/ ios/ShadowRunWatch/Models/
git commit -m "feat: add WatchConnectivity communication layer between iOS and watchOS"
```

---

## Task 3: Flutter 측 워치 통신 서비스

**Files:**
- Create: `lib/core/services/watch_connector_service.dart`

- [ ] **Step 1: WatchConnectorService 작성**

`lib/core/services/watch_connector_service.dart`:
```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class WatchConnectorService {
  static final WatchConnectorService _instance = WatchConnectorService._();
  factory WatchConnectorService() => _instance;
  WatchConnectorService._();

  static const _methodChannel = MethodChannel('com.ganziman.shadowrun/watch');
  static const _eventChannel = EventChannel('com.ganziman.shadowrun/watch_events');

  StreamSubscription? _eventSub;
  void Function(String command, Map<String, dynamic> data)? onWatchCommand;

  bool get _isIOS => Platform.isIOS;

  void startListening() {
    if (!_isIOS) return;
    _eventSub = _eventChannel.receiveBroadcastStream().listen((event) {
      if (event is Map) {
        final data = Map<String, dynamic>.from(event);
        final command = data.remove('command') as String? ?? '';
        onWatchCommand?.call(command, data);
      }
    });
  }

  void stopListening() {
    _eventSub?.cancel();
    _eventSub = null;
  }

  Future<bool> get isWatchReachable async {
    if (!_isIOS) return false;
    try {
      return await _methodChannel.invokeMethod<bool>('isWatchReachable') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendRunData({
    required String runState,
    required double distanceM,
    required int durationS,
    required double avgPace,
    required int calories,
    int? heartRate,
    String? threatLevel,
    double? shadowDistanceM,
    double? threatPercent,
    double? latitude,
    double? longitude,
    double? shadowLatitude,
    double? shadowLongitude,
    String? runMode,
    bool? ttsOn,
    bool? sfxOn,
    String? challengeResult,
  }) async {
    if (!_isIOS) return;
    final data = <String, dynamic>{
      'runState': runState,
      'distanceM': distanceM,
      'durationS': durationS,
      'avgPace': avgPace,
      'calories': calories,
    };
    if (heartRate != null) data['heartRate'] = heartRate;
    if (threatLevel != null) data['threatLevel'] = threatLevel;
    if (shadowDistanceM != null) data['shadowDistanceM'] = shadowDistanceM;
    if (threatPercent != null) data['threatPercent'] = threatPercent;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (shadowLatitude != null) data['shadowLatitude'] = shadowLatitude;
    if (shadowLongitude != null) data['shadowLongitude'] = shadowLongitude;
    if (runMode != null) data['runMode'] = runMode;
    if (ttsOn != null) data['ttsOn'] = ttsOn;
    if (sfxOn != null) data['sfxOn'] = sfxOn;
    if (challengeResult != null) data['challengeResult'] = challengeResult;
    try {
      await _methodChannel.invokeMethod('sendRunData', data);
    } catch (_) {}
  }

  Future<void> sendResult({
    required double distanceM,
    required int durationS,
    required double avgPace,
    required int calories,
    int? heartRate,
    String? challengeResult,
  }) async {
    if (!_isIOS) return;
    await sendRunData(
      runState: 'result',
      distanceM: distanceM,
      durationS: durationS,
      avgPace: avgPace,
      calories: calories,
      heartRate: heartRate,
      challengeResult: challengeResult,
    );
  }

  Future<void> sendIdle() async {
    if (!_isIOS) return;
    try {
      await _methodChannel.invokeMethod('sendAppContext', {'runState': 'idle'});
    } catch (_) {}
  }
}
```

- [ ] **Step 2: 빌드 확인**

```bash
cd /path/to/shadowrun
flutter analyze lib/core/services/watch_connector_service.dart
```
Expected: No issues found

- [ ] **Step 3: 커밋**

```bash
git add lib/core/services/watch_connector_service.dart
git commit -m "feat: add Flutter WatchConnectorService for phone-watch communication"
```

---

## Task 4: RunningScreen에 워치 데이터 전송 연동

**Files:**
- Modify: `lib/features/running/presentation/pages/running_screen.dart`

- [ ] **Step 1: import 추가 + 서비스 초기화**

`running_screen.dart` 상단 import에 추가:
```dart
import 'package:shadowrun/core/services/watch_connector_service.dart';
```

State 클래스의 기존 서비스 선언부 근처에 추가:
```dart
final _watchConnector = WatchConnectorService();
```

- [ ] **Step 2: initState에서 워치 리스닝 시작 + 워치 커맨드 수신**

`initState()` 메서드 끝 부분(`super.initState()` 이후)에 추가:
```dart
_watchConnector.startListening();
_watchConnector.onWatchCommand = _handleWatchCommand;
```

새 메서드 추가:
```dart
void _handleWatchCommand(String command, Map<String, dynamic> data) {
  switch (command) {
    case 'toggleTts':
      setState(() => _ttsOn = !_ttsOn);
      _horrorService.ttsEnabled = _ttsOn;
      break;
    case 'toggleSfx':
      setState(() => _sfxOn = !_sfxOn);
      SfxService().enabled = _sfxOn;
      if (_sfxOn) {
        _horrorService.unmuteBgm();
        _marathonService?.unmuteBgm();
        _soloTtsService?.unmuteBgm();
      } else {
        _horrorService.muteBgm();
        _marathonService?.muteBgm();
        _soloTtsService?.muteBgm();
      }
      break;
    case 'pause':
      if (!_paused) _togglePause();
      break;
    case 'resume':
      if (_paused) _togglePause();
      break;
    case 'stop':
      _stopRun();
      break;
  }
}
```

- [ ] **Step 3: GPS 콜백에서 워치로 데이터 전송**

기존 `onPositionUpdate` 콜백 내부 또는 `_ticker` 타이머 콜백에서, `setState()` 호출 직후에 추가:
```dart
_sendDataToWatch();
```

새 메서드 추가:
```dart
void _sendDataToWatch() {
  final pos = _runService.currentPosition;
  final shadowPoint = _horrorService.currentShadowPoint;
  _watchConnector.sendRunData(
    runState: _paused ? 'paused' : 'running',
    distanceM: _runService.totalDistanceM,
    durationS: _runService.durationS,
    avgPace: _runService.totalDistanceM > 0
        ? (_runService.durationS / 60) / (_runService.totalDistanceM / 1000)
        : 0,
    calories: _runService.calories,
    threatLevel: _horrorService.currentLevel.name,
    shadowDistanceM: _horrorService.shadowDistanceM,
    threatPercent: _getThreatPercent(),
    latitude: pos?.latitude,
    longitude: pos?.longitude,
    shadowLatitude: shadowPoint?.latitude,
    shadowLongitude: shadowPoint?.longitude,
    runMode: widget.runMode,
    ttsOn: _ttsOn,
    sfxOn: _sfxOn,
  );
}

double _getThreatPercent() {
  switch (_horrorService.currentLevel) {
    case ThreatLevel.aheadFar: return 0.0;
    case ThreatLevel.aheadMid: return 0.05;
    case ThreatLevel.aheadClose: return 0.10;
    case ThreatLevel.safe: return 0.25;
    case ThreatLevel.warningFar: return 0.45;
    case ThreatLevel.warningClose: return 0.60;
    case ThreatLevel.dangerFar: return 0.75;
    case ThreatLevel.dangerClose: return 0.90;
    case ThreatLevel.critical: return 1.0;
  }
}
```

- [ ] **Step 4: dispose에서 워치 리스닝 중지 + idle 전송**

`dispose()` 메서드에 추가:
```dart
_watchConnector.stopListening();
_watchConnector.sendIdle();
```

- [ ] **Step 5: 결과 화면 이동 시 워치에 결과 전송**

러닝 종료 후 결과 화면으로 이동하는 코드 직전에 추가:
```dart
_watchConnector.sendResult(
  distanceM: _runService.totalDistanceM,
  durationS: _runService.durationS,
  avgPace: _runService.totalDistanceM > 0
      ? (_runService.durationS / 60) / (_runService.totalDistanceM / 1000)
      : 0,
  calories: _runService.calories,
  challengeResult: /* existing challenge result variable */,
);
```

- [ ] **Step 6: 빌드 확인**

```bash
flutter analyze
```

- [ ] **Step 7: 커밋**

```bash
git add lib/features/running/presentation/pages/running_screen.dart
git commit -m "feat: integrate watch data sync into running screen"
```

---

## Task 5: watchOS 대기 화면 (WaitingView)

**Files:**
- Create: `ios/ShadowRunWatch/Views/WaitingView.swift`
- Modify: `ios/ShadowRunWatch/ContentView.swift`

- [ ] **Step 1: WaitingView 작성**

`ios/ShadowRunWatch/Views/WaitingView.swift`:
```swift
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
```

- [ ] **Step 2: ContentView를 상태 기반 라우터로 변경**

`ios/ShadowRunWatch/ContentView.swift`:
```swift
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
```

- [ ] **Step 3: ShadowRunWatchApp에 WatchSessionManager 초기화**

`ios/ShadowRunWatch/ShadowRunWatchApp.swift`:
```swift
import SwiftUI

@main
struct ShadowRunWatchApp: App {
    @StateObject private var session = WatchSessionManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(session)
        }
    }
}
```

- [ ] **Step 4: 빈 RunningView, ResultView 스텁 작성**

`ios/ShadowRunWatch/Views/RunningView.swift`:
```swift
import SwiftUI

struct RunningView: View {
    var body: some View {
        Text("Running...")
            .foregroundColor(.green)
    }
}
```

`ios/ShadowRunWatch/Views/ResultView.swift`:
```swift
import SwiftUI

struct ResultView: View {
    var body: some View {
        Text("Result")
            .foregroundColor(.green)
    }
}
```

- [ ] **Step 5: watchOS 시뮬레이터에서 빌드 및 실행**

1. ShadowRunWatch scheme 선택 → Apple Watch SE 시뮬레이터
2. 빌드 + 실행
3. "SHADOW RUN" 로고 + "Open Shadow Run on your iPhone" 텍스트 확인

- [ ] **Step 6: 커밋**

```bash
git add ios/ShadowRunWatch/
git commit -m "feat: add watch waiting view with phone connection status"
```

---

## Task 6: watchOS 러닝 화면 (RunningView + ThreatBar + Controls)

**Files:**
- Modify: `ios/ShadowRunWatch/Views/RunningView.swift`
- Create: `ios/ShadowRunWatch/Views/ThreatBarView.swift`

- [ ] **Step 1: ThreatBarView 작성**

`ios/ShadowRunWatch/Views/ThreatBarView.swift`:
```swift
import SwiftUI

struct ThreatBarView: View {
    let threatLevel: String
    let percent: Double
    
    var threatColor: Color {
        switch threatLevel {
        case "aheadFar", "aheadMid", "aheadClose": return .green
        case "safe": return .blue
        case "warningFar", "warningClose": return .yellow
        case "dangerFar", "dangerClose": return .orange
        case "critical": return .red
        default: return .gray
        }
    }
    
    var threatLabel: String {
        switch threatLevel {
        case "aheadFar": return "SAFE"
        case "aheadMid": return "AHEAD"
        case "aheadClose": return "AHEAD"
        case "safe": return "SAFE"
        case "warningFar": return "WARNING"
        case "warningClose": return "WARNING"
        case "dangerFar": return "DANGER"
        case "dangerClose": return "DANGER!"
        case "critical": return "CRITICAL"
        default: return "---"
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(threatLabel)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(threatColor)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.gray.opacity(0.3))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(threatColor)
                        .frame(width: geo.size.width * min(max(percent, 0), 1))
                        .animation(.easeInOut(duration: 0.3), value: percent)
                }
            }
            .frame(height: 6)
        }
    }
}
```

- [ ] **Step 2: RunningView 전체 구현**

`ios/ShadowRunWatch/Views/RunningView.swift`:
```swift
import SwiftUI

struct RunningView: View {
    @ObservedObject var session = WatchSessionManager.shared
    @ObservedObject var healthKit = HealthKitManager.shared
    
    var body: some View {
        let data = session.runData
        
        ScrollView {
            VStack(spacing: 4) {
                // Threat bar (doppelganger mode only)
                if data.runMode == "doppelganger" {
                    ThreatBarView(
                        threatLevel: data.threatLevel,
                        percent: data.threatPercent
                    )
                    
                    // Shadow distance badge
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
                
                // Main stats
                VStack(spacing: 6) {
                    // Distance (large)
                    Text(data.formattedDistance)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Pace + Duration row
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
                    
                    // Heart rate + Calories row
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
                    // TTS toggle
                    Button(action: {
                        session.sendCommand("toggleTts")
                    }) {
                        Image(systemName: data.ttsOn ? "mic.fill" : "mic.slash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(data.ttsOn ? .green : .gray)
                    }
                    .buttonStyle(.plain)
                    .frame(width: 30, height: 30)
                    
                    // Pause/Resume
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
                    
                    // SFX toggle
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
                
                // Stop button
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
    }
}
```

- [ ] **Step 3: HealthKitManager 스텁 생성** (Task 8에서 완성)

`ios/ShadowRunWatch/Services/HealthKitManager.swift`:
```swift
import Foundation

class HealthKitManager: NSObject, ObservableObject {
    static let shared = HealthKitManager()
    @Published var currentHeartRate: Int = 0
}
```

- [ ] **Step 4: 빌드 확인**

watchOS 시뮬레이터에서 빌드 + 실행

- [ ] **Step 5: 커밋**

```bash
git add ios/ShadowRunWatch/Views/ ios/ShadowRunWatch/Services/HealthKitManager.swift
git commit -m "feat: add watch running view with stats, threat bar, and controls"
```

---

## Task 7: watchOS 미니맵 (MiniMapView)

**Files:**
- Create: `ios/ShadowRunWatch/Views/MiniMapView.swift`
- Modify: `ios/ShadowRunWatch/Views/RunningView.swift`

- [ ] **Step 1: MiniMapView 작성**

`ios/ShadowRunWatch/Views/MiniMapView.swift`:
```swift
import SwiftUI
import MapKit

struct MiniMapView: View {
    let runnerLat: Double
    let runnerLon: Double
    let shadowLat: Double?
    let shadowLon: Double?
    let showShadow: Bool
    
    var runnerCoord: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: runnerLat, longitude: runnerLon)
    }
    
    var body: some View {
        Map {
            // Runner marker
            Annotation("", coordinate: runnerCoord) {
                Circle()
                    .fill(.green)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(.green.opacity(0.4), lineWidth: 2)
                            .frame(width: 18, height: 18)
                    )
            }
            
            // Shadow marker
            if showShadow, let sLat = shadowLat, let sLon = shadowLon,
               sLat != 0, sLon != 0 {
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: sLat, longitude: sLon
                )) {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(.red.opacity(0.4), lineWidth: 2)
                                .frame(width: 18, height: 18)
                        )
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .mapControlVisibility(.hidden)
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .allowsHitTesting(false)
    }
}
```

- [ ] **Step 2: RunningView에 미니맵 삽입**

`RunningView.swift`의 VStack 내부, threat bar 아래/main stats 위에 추가:
```swift
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
```

- [ ] **Step 3: 빌드 확인**

watchOS 시뮬레이터에서 빌드 + 실행

- [ ] **Step 4: 커밋**

```bash
git add ios/ShadowRunWatch/Views/MiniMapView.swift ios/ShadowRunWatch/Views/RunningView.swift
git commit -m "feat: add mini map with runner and shadow markers on watch"
```

---

## Task 8: HealthKit 심박수 연동 (워치 센서 + AirPods)

**Files:**
- Modify: `ios/ShadowRunWatch/Services/HealthKitManager.swift`
- Modify: `ios/ShadowRunWatch/Info.plist` (Xcode에서 추가)

- [ ] **Step 1: watchOS 프로젝트에 HealthKit Capability 추가**

Xcode에서:
1. ShadowRunWatch 타겟 선택
2. Signing & Capabilities 탭
3. + Capability → HealthKit 추가

- [ ] **Step 2: Info.plist에 HealthKit 사용 설명 추가**

Xcode에서 ShadowRunWatch의 Info.plist에 추가:
- Key: `NSHealthShareUsageDescription`
- Value: `Shadow Run reads your heart rate during workouts to display on screen.`
- Key: `NSHealthUpdateUsageDescription`
- Value: `Shadow Run saves your workout data.`

- [ ] **Step 3: HealthKitManager 전체 구현**

`ios/ShadowRunWatch/Services/HealthKitManager.swift`:
```swift
import Foundation
import HealthKit

class HealthKitManager: NSObject, ObservableObject {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    
    @Published var currentHeartRate: Int = 0
    @Published var isAuthorized = false
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let readTypes: Set<HKObjectType> = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            DispatchQueue.main.async {
                self.isAuthorized = success
                if success {
                    self.startHeartRateQuery()
                }
            }
        }
    }
    
    func startHeartRateQuery() {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }
        
        stopHeartRateQuery()
        
        let query = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        
        query.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }
        
        healthStore.execute(query)
        heartRateQuery = query
    }
    
    func stopHeartRateQuery() {
        if let query = heartRateQuery {
            healthStore.stop(query)
            heartRateQuery = nil
        }
    }
    
    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample],
              let latest = samples.last else { return }
        
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let value = Int(latest.quantity.doubleValue(for: heartRateUnit))
        
        DispatchQueue.main.async {
            self.currentHeartRate = value
        }
    }
}
```

- [ ] **Step 4: WatchSessionManager에서 심박수를 폰으로 전송**

`WatchSessionManager.swift`의 `processMessage` 메서드 끝에 추가:
```swift
// Send heart rate back to phone periodically
if HealthKitManager.shared.currentHeartRate > 0 {
    // Heart rate is sent back via the next sendCommand or can be included
    // in periodic updates
}
```

`WatchSessionManager.swift`에 심박수 전송 타이머 추가:
```swift
private var heartRateTimer: Timer?

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
```

`processMessage`에서 runState 변경 시 심박수 동기화 시작/중지:
```swift
if let stateStr = message["runState"] as? String,
   let state = RunState(rawValue: stateStr) {
    runState = state
    if state == .running {
        HealthKitManager.shared.requestAuthorization()
        startHeartRateSync()
    } else if state == .idle {
        HealthKitManager.shared.stopHeartRateQuery()
        stopHeartRateSync()
    }
}
```

- [ ] **Step 5: 빌드 확인**

watchOS 시뮬레이터에서 빌드 (HealthKit은 실기기에서만 실제 동작)

- [ ] **Step 6: 커밋**

```bash
git add ios/ShadowRunWatch/Services/ ios/ShadowRunWatch/Info.plist
git commit -m "feat: add HealthKit heart rate monitoring on watch (sensor + AirPods)"
```

---

## Task 9: 폰 앱에 HealthKit 심박수 표시 (에어팟 전용 사용자)

**Files:**
- Create: `lib/core/services/health_service.dart`
- Modify: `lib/features/running/presentation/pages/running_screen.dart`
- Modify: `ios/Runner/Info.plist`

- [ ] **Step 1: iOS Info.plist에 HealthKit 권한 추가**

`ios/Runner/Info.plist`의 `</dict>` 직전에 추가:
```xml
<key>NSHealthShareUsageDescription</key>
<string>Shadow Run reads your heart rate from AirPods Pro or Apple Watch to display during runs.</string>
```

- [ ] **Step 2: Runner 타겟에 HealthKit Capability 추가**

Xcode에서:
1. Runner 타겟 선택
2. Signing & Capabilities → + Capability → HealthKit

- [ ] **Step 3: AppDelegate에 HealthKit MethodChannel 추가**

`ios/Runner/AppDelegate.swift`의 `application(_:didFinishLaunchingWithOptions:)` 메서드 내에 추가:
```swift
// HealthKit channel
let healthChannel = FlutterMethodChannel(
    name: "com.ganziman.shadowrun/health",
    binaryMessenger: controller.binaryMessenger
)
healthChannel.setMethodCallHandler { call, result in
    HealthKitHandler.shared.handle(call, result: result)
}
```

- [ ] **Step 4: HealthKitHandler (iOS) 작성**

`ios/Runner/HealthKitHandler.swift`:
```swift
import Foundation
import HealthKit
import Flutter

class HealthKitHandler: NSObject {
    static let shared = HealthKitHandler()
    
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    private var eventSink: FlutterEventSink?
    
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
        // Send via watch event channel (reuse existing)
        DispatchQueue.main.async {
            WatchEventStreamHandler.shared.send(["command": "heartRate", "heartRate": hr])
        }
    }
}
```

- [ ] **Step 5: Flutter HealthService 작성**

`lib/core/services/health_service.dart`:
```dart
import 'dart:io';
import 'package:flutter/services.dart';

class HealthService {
  static final HealthService _instance = HealthService._();
  factory HealthService() => _instance;
  HealthService._();

  static const _channel = MethodChannel('com.ganziman.shadowrun/health');

  int _currentHeartRate = 0;
  int get currentHeartRate => _currentHeartRate;

  void updateHeartRate(int hr) {
    _currentHeartRate = hr;
  }

  Future<bool> requestAuthorization() async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('requestAuthorization') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> startHeartRateStream() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('startHeartRateStream');
    } catch (_) {}
  }

  Future<void> stopHeartRateStream() async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('stopHeartRateStream');
    } catch (_) {}
  }
}
```

- [ ] **Step 6: RunningScreen에서 심박수 수신 + 표시**

`running_screen.dart`에 import 추가:
```dart
import 'package:shadowrun/core/services/health_service.dart';
```

State에 추가:
```dart
final _healthService = HealthService();
```

`_handleWatchCommand`에 심박수 케이스 추가:
```dart
case 'heartRate':
  final hr = data['heartRate'] as int? ?? 0;
  _healthService.updateHeartRate(hr);
  break;
```

`initState()`에서 HealthKit 초기화:
```dart
_healthService.requestAuthorization().then((_) {
  _healthService.startHeartRateStream();
});
```

`dispose()`에 추가:
```dart
_healthService.stopHeartRateStream();
```

러닝 화면 UI에서 심박수 표시 위젯 추가 (기존 칼로리 옆 등에):
```dart
// Heart rate display - add near calories display
if (_healthService.currentHeartRate > 0)
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.favorite, color: Colors.red, size: 14),
      SizedBox(width: 2),
      Text(
        '${_healthService.currentHeartRate}',
        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      ),
      Text(' bpm', style: TextStyle(color: Colors.grey, fontSize: 10)),
    ],
  ),
```

- [ ] **Step 7: 빌드 확인**

```bash
flutter analyze
```

- [ ] **Step 8: 커밋**

```bash
git add lib/core/services/health_service.dart \
  lib/features/running/presentation/pages/running_screen.dart \
  ios/Runner/HealthKitHandler.swift ios/Runner/Info.plist
git commit -m "feat: add heart rate display on phone via HealthKit (AirPods + Watch)"
```

---

## Task 10: watchOS 점프스케어 화면

**Files:**
- Create: `ios/ShadowRunWatch/Views/JumpscareView.swift`
- Modify: `ios/ShadowRunWatch/Views/RunningView.swift`

- [ ] **Step 1: JumpscareView 작성**

`ios/ShadowRunWatch/Views/JumpscareView.swift`:
```swift
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
            // Haptic burst
            let device = WKInterfaceDevice.current()
            for i in 0..<5 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                    device.play(.failure)
                }
            }
            
            // Flash animation
            withAnimation(.easeIn(duration: 0.1)) { opacity = 1.0 }
            withAnimation(.easeInOut(duration: 0.3).repeatCount(5, autoreverses: true)) {
                scale = 1.3
            }
            
            // Auto-dismiss after 1.5s
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                onComplete()
            }
        }
    }
}
```

- [ ] **Step 2: RunningView에 점프스케어 트리거 추가**

`RunningView.swift`에 State 추가:
```swift
@State private var showJumpscare = false
```

body를 ZStack으로 감싸고 점프스케어 오버레이 추가:
```swift
var body: some View {
    let data = session.runData
    
    ZStack {
        // ... 기존 ScrollView 코드 전체 ...
        
        if showJumpscare {
            JumpscareView {
                showJumpscare = false
            }
        }
    }
    .onChange(of: data.threatLevel) { newLevel in
        if newLevel == "critical" {
            showJumpscare = true
        }
    }
}
```

- [ ] **Step 3: 빌드 확인**

watchOS 시뮬레이터에서 빌드

- [ ] **Step 4: 커밋**

```bash
git add ios/ShadowRunWatch/Views/JumpscareView.swift ios/ShadowRunWatch/Views/RunningView.swift
git commit -m "feat: add jumpscare overlay with haptic feedback on watch"
```

---

## Task 11: watchOS 결과 화면

**Files:**
- Modify: `ios/ShadowRunWatch/Views/ResultView.swift`

- [ ] **Step 1: ResultView 전체 구현**

`ios/ShadowRunWatch/Views/ResultView.swift`:
```swift
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
                // Result status
                Text(resultTitle)
                    .font(.system(size: 20, weight: .black))
                    .foregroundColor(resultColor)
                
                Divider().background(Color.gray.opacity(0.5))
                
                // Stats grid
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
                
                // Return to home
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
            // Victory/defeat haptic
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
```

- [ ] **Step 2: 빌드 확인**

watchOS 시뮬레이터에서 빌드 + 실행

- [ ] **Step 3: 커밋**

```bash
git add ios/ShadowRunWatch/Views/ResultView.swift
git commit -m "feat: add watch result screen with stats and haptic feedback"
```

---

## Task 12: watchOS 앱 아이콘 + 위협 레벨 진동 패턴

**Files:**
- Modify: `ios/ShadowRunWatch/Assets.xcassets/`
- Modify: `ios/ShadowRunWatch/Views/RunningView.swift`

- [ ] **Step 1: 워치 앱 아이콘 설정**

Xcode에서:
1. ShadowRunWatch → Assets.xcassets → AppIcon 선택
2. 기존 앱 아이콘을 리사이즈하여 워치용 사이즈로 추가:
   - 40x40 (Watch 38mm 2x)
   - 44x44 (Watch 40mm 2x)
   - 50x50 (Watch 44mm 2x)
   - 86x86 (Short Look 38mm)
   - 98x98 (Short Look 42mm)
   - 108x108 (Short Look 44mm)
   - 1024x1024 (App Store)
3. 기존 `ios/Runner/Assets.xcassets/AppIcon.appiconset/`에서 가장 큰 아이콘을 리사이즈

- [ ] **Step 2: 위협 레벨 변경 시 진동 패턴 추가**

`RunningView.swift`의 `.onChange(of: data.threatLevel)` 수정:
```swift
.onChange(of: data.threatLevel) { newLevel in
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
```

- [ ] **Step 3: 빌드 확인**

watchOS 시뮬레이터에서 빌드

- [ ] **Step 4: 커밋**

```bash
git add ios/ShadowRunWatch/
git commit -m "feat: add watch app icon and threat-level haptic patterns"
```

---

## Task 13: 통합 테스트 (폰 + 워치 시뮬레이터)

- [ ] **Step 1: iOS + watchOS 시뮬레이터 동시 실행**

Xcode에서:
1. Runner scheme → iPhone 시뮬레이터 선택 → Run
2. ShadowRunWatch scheme → 페어링된 Watch 시뮬레이터 선택 → Run
3. 두 시뮬레이터가 자동 페어링됨

- [ ] **Step 2: 통신 테스트**

1. 폰 앱에서 러닝 시작 → 워치가 자동으로 러닝 화면으로 전환되는지 확인
2. 워치에서 일시정지 → 폰도 일시정지되는지 확인
3. 워치에서 TTS/SFX 토글 → 폰 오디오 변경 확인
4. 폰에서 러닝 종료 → 워치가 결과 화면으로 전환되는지 확인

- [ ] **Step 3: 도플갱어 모드 테스트**

1. 폰에서 도플갱어 챌린지 시작
2. 워치에 위협 레벨 바 표시 확인
3. 미니맵에 🟢(나) + 🔴(도플갱어) 표시 확인
4. 위협 레벨 변경 시 진동 확인

- [ ] **Step 4: 실기기 테스트 (Apple Watch SE)**

1. Mac에 iPhone + Apple Watch SE 연결
2. Xcode에서 실기기 선택 → 빌드 + 설치
3. 실제 달리면서 테스트:
   - GPS 데이터 워치 표시 확인
   - 심박수 표시 확인
   - 진동 체감 확인
   - 화면 가독성 확인

- [ ] **Step 5: 버그 수정 후 최종 커밋**

```bash
git add -A
git commit -m "feat: Apple Watch companion app complete - running data, map, threat, heart rate"
```

---

## Summary

| Task | 내용 | 예상 파일 수 |
|------|------|------------|
| 1 | Xcode watchOS Target 추가 | 3 (Xcode GUI) |
| 2 | WatchConnectivity 통신 레이어 | 4 |
| 3 | Flutter WatchConnectorService | 1 |
| 4 | RunningScreen 워치 연동 | 1 (수정) |
| 5 | 워치 대기 화면 | 4 |
| 6 | 워치 러닝 화면 + 컨트롤 | 2 |
| 7 | 미니맵 (MapKit) | 1 + 수정 |
| 8 | HealthKit 심박수 (워치) | 1 (수정) + plist |
| 9 | HealthKit 심박수 (폰/에어팟) | 3 |
| 10 | 점프스케어 | 1 + 수정 |
| 11 | 결과 화면 | 1 (수정) |
| 12 | 앱 아이콘 + 진동 패턴 | 수정 |
| 13 | 통합 테스트 | - |
