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
