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
    // 음수/극단값만 거부. 0은 dropout 신호로 허용 (이전 값이 stale한 채 남지 않도록).
    if (hr < 0 || hr > 260) return;
    _currentHeartRate = hr;
  }

  /// 새 런 시작/종료 시 직전 런의 HR 잔존값 제거
  void reset() {
    _currentHeartRate = 0;
  }

  // start/stop을 직렬화. 매 호출 시 세대 토큰을 증가시켜 마지막 호출만 권위 있도록.
  int _gen = 0;
  Future<void>? _inflight;

  Future<bool> requestAuthorization() async {
    if (!Platform.isIOS) return false;
    try {
      return await _channel.invokeMethod<bool>('requestAuthorization') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> startHeartRateStream() => _runExclusive(++_gen, 'startHeartRateStream');

  Future<void> stopHeartRateStream() => _runExclusive(++_gen, 'stopHeartRateStream');

  Future<void> _runExclusive(int myGen, String method) async {
    if (!Platform.isIOS) return;
    // 이전 호출이 진행 중이면 완료 대기 (네이티브 측 경합 방지)
    final prev = _inflight;
    if (prev != null) {
      try { await prev; } catch (_) {}
    }
    if (myGen != _gen) return; // 더 최근 호출이 들어왔음 → 이번 호출은 무의미
    final future = _invoke(method);
    _inflight = future;
    try {
      await future;
    } finally {
      if (identical(_inflight, future)) _inflight = null;
    }
  }

  Future<void> _invoke(String method) async {
    try {
      await _channel.invokeMethod(method);
    } catch (_) {}
  }
}
