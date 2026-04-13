import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/services/geocoding_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class RunningService extends ChangeNotifier {
  static const double minSpeedMps = 1.0; // 3.6 km/h
  static const double maxSpeedMps = 8.0; // 28.8 km/h
  static const int _shadowGracePeriodS = 10; // 시작 후 10초 유예
  bool kmSplitTtsEnabled = true; // 마라토너 모드에서는 false (MarathonService가 처리)

  // 백그라운드에서도 동작하는 GPS 콜백 (Timer 대체)
  void Function()? onPositionUpdate;

  StreamSubscription<Position>? _positionSub;
  final List<RunPoint> _points = [];
  List<RunPoint>? _shadowPoints;
  int? _shadowRunId;
  double _shadowSpeedMultiplier = 1.0; // 0.7 ~ 1.3

  bool _isRunning = false;
  bool _isPaused = false;
  DateTime? _startTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStart;
  double _totalDistanceM = 0;
  Position? _lastPosition;
  int _currentShadowIndex = 0;
  double _cachedShadowDist = 0;
  int _cachedShadowIdx = 0;
  double _currentSpeed = 0;
  double _heading = 0;
  int _lastAnnouncedKm = 0;
  final FlutterTts _tts = FlutterTts();
  bool _ttsReady = false;

  // Public getters
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  List<RunPoint> get points => List.unmodifiable(_points);
  List<RunPoint>? get shadowPoints => _shadowPoints;
  double get totalDistanceM => _totalDistanceM;
  int get durationS {
    if (_startTime == null) return 0;
    final total = DateTime.now().difference(_startTime!);
    final activePause = _pauseStart != null ? DateTime.now().difference(_pauseStart!) : Duration.zero;
    return (total - _pausedDuration - activePause).inSeconds;
  }

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
    final elapsed = durationS;
    // 시작 후 유예기간 동안은 안전 거리 반환
    if (elapsed < _shadowGracePeriodS) {
      return 200.0;
    }
    // 유예기간 이후 도플갱어 시간 계산 (배율 적용)
    final shadowElapsedS = (elapsed - _shadowGracePeriodS) * _shadowSpeedMultiplier;
    // 캐시된 인덱스부터 이어서 계산 (O(1) amortized)
    double shadowDist = _cachedShadowDist;
    int shadowIdx = _cachedShadowIdx;
    final startMs = _shadowPoints!.first.timestampMs;
    for (int i = shadowIdx + 1; i < _shadowPoints!.length; i++) {
      final elapsedMs = _shadowPoints![i].timestampMs - startMs;
      if (elapsedMs > shadowElapsedS * 1000) break;
      shadowDist += _distanceBetweenPoints(
        _shadowPoints![i - 1].latitude, _shadowPoints![i - 1].longitude,
        _shadowPoints![i].latitude, _shadowPoints![i].longitude,
      );
      shadowIdx = i;
    }
    _cachedShadowDist = shadowDist;
    _cachedShadowIdx = shadowIdx;
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

  void pauseRun() {
    if (!_isPaused) {
      _isPaused = true;
      _pauseStart = DateTime.now();
      notifyListeners();
    }
  }

  void resumeRun() {
    if (_isPaused && _pauseStart != null) {
      _pausedDuration += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
      _isPaused = false;
      notifyListeners();
    }
  }

  /// 러닝 시작
  Future<bool> startRun({int? shadowRunId, double shadowSpeedMultiplier = 1.0}) async {
    // GPS 서비스 활성화 확인
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return false;
    }

    _shadowRunId = shadowRunId;
    _shadowSpeedMultiplier = shadowSpeedMultiplier;
    if (shadowRunId != null) {
      _shadowPoints = await DatabaseHelper.getRunPoints(shadowRunId);
      debugPrint('SHADOW: loaded ${_shadowPoints?.length ?? 0} points for run $shadowRunId');
    } else {
      debugPrint('SHADOW: no shadow run (new run mode)');
    }

    // 기존 구독 누수 방지
    await _positionSub?.cancel();
    _positionSub = null;

    _points.clear();
    _totalDistanceM = 0;
    _lastPosition = null;
    _currentShadowIndex = 0;
    _cachedShadowDist = 0;
    _cachedShadowIdx = 0;
    _lastAnnouncedKm = 0;
    _isPaused = false;
    _pausedDuration = Duration.zero;
    _pauseStart = null;
    _isRunning = true;

    // km 스플릿 음성 알림용 TTS 초기화
    try {
      await _tts.setLanguage(S.isKo ? 'ko-KR' : 'en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _ttsReady = true;
    } catch (e) {
      debugPrint('TTS 초기화 실패: $e');
    }

    // Android: 포그라운드 서비스로 백그라운드 GPS 유지
    late LocationSettings locationSettings;
    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        forceLocationManager: false,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: 'SHADOW RUN이 러닝을 기록하고 있습니다',
          notificationTitle: 'SHADOW RUN',
          enableWakeLock: true,
          notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    } else {
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );
    }

    // GPS 스트림 시작 직전에 시간 설정 (정확한 러닝 시간 측정)
    _startTime = DateTime.now();

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPosition);

    notifyListeners();
    return true;
  }

  void _onPosition(Position pos) {
    if (!_isRunning) return;

    // 속도 계산: GPS 속도 우선, 없으면 위치 변화로 추정
    double speed = pos.speed >= 0 ? pos.speed : 0;
    if (speed <= 0 && _lastPosition != null) {
      final d = Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        pos.latitude, pos.longitude,
      );
      final dt = pos.timestamp.difference(
        DateTime.fromMillisecondsSinceEpoch(
          _points.isNotEmpty ? _points.last.timestampMs : pos.timestamp.millisecondsSinceEpoch,
        ),
      ).inSeconds;
      if (dt > 0) speed = d / dt;
    }
    _currentSpeed = speed;
    if (pos.heading >= 0) _heading = pos.heading;

    // 일시정지 중이면 위치만 갱신하고 거리/포인트는 안 함
    if (_isPaused) {
      _lastPosition = pos;
      notifyListeners();
      onPositionUpdate?.call(); // 차량 감지 자동 복귀 위해 콜백은 호출
      return;
    }

    if (_lastPosition != null && isValidSpeed) {
      _totalDistanceM += Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        pos.latitude, pos.longitude,
      );
    }

    // km 스플릿 음성 알림 (마라토너 모드에서는 비활성화)
    final currentKm = (_totalDistanceM / 1000).floor();
    if (currentKm > _lastAnnouncedKm && _ttsReady && kmSplitTtsEnabled) {
      _lastAnnouncedKm = currentKm;
      _announceKmSplit(currentKm);
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

    // 백그라운드에서도 동작하는 콜백 호출 (Timer 대체)
    onPositionUpdate?.call();
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

    // 시작 지점으로 역지오코딩
    String? location;
    if (_points.isNotEmpty) {
      location = await GeocodingService.reverseGeocode(
        _points.first.latitude,
        _points.first.longitude,
      );
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
      location: location,
    );

    final runId = await DatabaseHelper.insertRunWithPoints(
      run,
      _points,
      incrementChallenge: isChallenge,
    );

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
      location: run.location,
    );
  }

  Future<void> _announceKmSplit(int km) async {
    final paceMin = avgPace.floor();
    final paceSec = ((avgPace - paceMin) * 60).round();
    final paceStr = "$paceMin'${paceSec.toString().padLeft(2, '0')}\"";

    final text = S.isKo
        ? '${km}킬로미터. 페이스 $paceStr'
        : '$km kilometer. Pace $paceStr';

    await _tts.awaitSpeakCompletion(true);
    await _tts.speak(text);
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
    _tts.stop();
    super.dispose();
  }
}
