import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class RunningService extends ChangeNotifier {
  static const double minSpeedMps = 1.0; // 3.6 km/h
  static const double maxSpeedMps = 8.0; // 28.8 km/h

  StreamSubscription<Position>? _positionSub;
  final List<RunPoint> _points = [];
  List<RunPoint>? _shadowPoints;
  int? _shadowRunId;

  bool _isRunning = false;
  DateTime? _startTime;
  double _totalDistanceM = 0;
  Position? _lastPosition;
  int _currentShadowIndex = 0;
  double _currentSpeed = 0;
  double _heading = 0;

  // Public getters
  bool get isRunning => _isRunning;
  List<RunPoint> get points => List.unmodifiable(_points);
  List<RunPoint>? get shadowPoints => _shadowPoints;
  double get totalDistanceM => _totalDistanceM;
  int get durationS => _startTime == null ? 0 : DateTime.now().difference(_startTime!).inSeconds;

  double get avgPace {
    if (_totalDistanceM < 10 || durationS < 1) return 0;
    return (durationS / 60) / (_totalDistanceM / 1000); // min/km
  }

  int get calories => (_totalDistanceM * 0.06).round(); // 대략적 계산

  double get currentSpeed => _currentSpeed;
  double get heading => _heading;

  bool get isValidSpeed => _currentSpeed >= minSpeedMps && _currentSpeed <= maxSpeedMps;

  String? get speedWarning {
    if (_currentSpeed < minSpeedMps) return S.tooSlow;
    if (_currentSpeed > maxSpeedMps) return S.tooFast;
    return null;
  }

  Position? get currentPosition => _lastPosition;
  int get currentShadowIndex => _currentShadowIndex;

  RunPoint? get currentShadowPoint {
    if (_shadowPoints == null || _currentShadowIndex >= _shadowPoints!.length) return null;
    return _shadowPoints![_currentShadowIndex];
  }

  /// 도플갱어와의 거리 (양수 = 앞서는 중, 음수 = 뒤처지는 중)
  double get shadowDistanceM {
    if (_shadowPoints == null || _lastPosition == null || currentShadowPoint == null) {
      return double.infinity;
    }
    // 내 총 거리 vs 도플갱어의 해당 시점 거리
    final elapsed = durationS;
    double shadowDist = 0;
    int shadowIdx = 0;
    final startMs = _shadowPoints!.first.timestampMs;
    for (int i = 1; i < _shadowPoints!.length; i++) {
      final elapsedMs = _shadowPoints![i].timestampMs - startMs;
      if (elapsedMs > elapsed * 1000) break;
      shadowDist += _distanceBetweenPoints(
        _shadowPoints![i - 1].latitude, _shadowPoints![i - 1].longitude,
        _shadowPoints![i].latitude, _shadowPoints![i].longitude,
      );
      shadowIdx = i;
    }
    _currentShadowIndex = shadowIdx;
    return _totalDistanceM - shadowDist;
  }

  String get formattedPace {
    if (avgPace <= 0 || avgPace.isInfinite) return "--'--\"";
    final min = avgPace.floor();
    final sec = ((avgPace - min) * 60).round();
    return "$min'${sec.toString().padLeft(2, '0')}\"";
  }

  String get formattedDuration {
    final s = durationS;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  /// 러닝 시작
  Future<bool> startRun({int? shadowRunId}) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final req = await Geolocator.requestPermission();
      if (req == LocationPermission.denied || req == LocationPermission.deniedForever) {
        return false;
      }
    }

    _shadowRunId = shadowRunId;
    if (shadowRunId != null) {
      _shadowPoints = await DatabaseHelper.getRunPoints(shadowRunId);
      debugPrint('SHADOW: loaded ${_shadowPoints?.length ?? 0} points for run $shadowRunId');
    } else {
      debugPrint('SHADOW: no shadow run (new run mode)');
    }

    _points.clear();
    _totalDistanceM = 0;
    _lastPosition = null;
    _currentShadowIndex = 0;
    _startTime = DateTime.now();
    _isRunning = true;

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);

    notifyListeners();
    return true;
  }

  void _onPosition(Position pos) {
    if (!_isRunning) return;

    _currentSpeed = pos.speed >= 0 ? pos.speed : 0;
    if (pos.heading >= 0) _heading = pos.heading;

    if (_lastPosition != null && isValidSpeed) {
      _totalDistanceM += Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        pos.latitude, pos.longitude,
      );
    }

    _lastPosition = pos;
    _points.add(RunPoint(
      runId: 0,
      latitude: pos.latitude,
      longitude: pos.longitude,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      speedMps: pos.speed,
    ));

    notifyListeners();
  }

  /// 러닝 종료 및 저장
  Future<RunModel?> stopRun() async {
    _isRunning = false;
    await _positionSub?.cancel();
    _positionSub = null;

    if (_points.length < 2 || _totalDistanceM < 10) {
      notifyListeners();
      return null;
    }

    final isChallenge = _shadowRunId != null;
    String? result;
    if (isChallenge) {
      result = shadowDistanceM >= 0 ? 'win' : 'lose';
    }

    final run = RunModel(
      date: DateTime.now().toIso8601String(),
      distanceM: _totalDistanceM,
      durationS: durationS,
      avgPace: avgPace,
      calories: calories,
      isChallenge: isChallenge,
      challengeResult: result,
      shadowRunId: _shadowRunId,
    );

    final runId = await DatabaseHelper.insertRun(run);
    final savedPoints = _points.map((p) => RunPoint(
      runId: runId,
      latitude: p.latitude,
      longitude: p.longitude,
      timestampMs: p.timestampMs,
      speedMps: p.speedMps,
      heartRate: p.heartRate,
    )).toList();
    await DatabaseHelper.insertPoints(savedPoints);

    if (isChallenge) {
      await DatabaseHelper.incrementDailyChallenge();
    }

    notifyListeners();
    return RunModel(
      id: runId,
      date: run.date,
      distanceM: run.distanceM,
      durationS: run.durationS,
      avgPace: run.avgPace,
      calories: run.calories,
      isChallenge: run.isChallenge,
      challengeResult: run.challengeResult,
      shadowRunId: run.shadowRunId,
    );
  }

  double _distanceBetweenPoints(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
}
