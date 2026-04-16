import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';

class WatchConnectorService {
  static final WatchConnectorService _instance = WatchConnectorService._();
  factory WatchConnectorService() => _instance;
  WatchConnectorService._();

  static const _methodChannel = MethodChannel('com.ganziman.shadowrun/watch');
  static const _eventChannel =
      EventChannel('com.ganziman.shadowrun/watch_events');

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
      return await _methodChannel.invokeMethod<bool>('isWatchReachable') ??
          false;
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
