import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/services/geocoding_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class RunningService extends ChangeNotifier {
  static const double minSpeedMps = 1.0; // 3.6 km/h
  static const double maxSpeedMps = 8.0; // 28.8 km/h
  static const int _shadowGracePeriodS = 15; // 시작 후 15초 유예
  // GPS 지연/정지 방어: grace 후에도 사용자 움직임이 적으면 60초까지 도플갱어 대기
  static const int _shadowStartupMaxS = 60;
  static const double _shadowStartupMinM = 20;
  bool kmSplitTtsEnabled = true; // 마라토너 모드에서는 false (MarathonService가 처리)

  // 백그라운드에서도 동작하는 GPS 콜백 (Timer 대체)
  void Function()? onPositionUpdate;

  StreamSubscription<Position>? _positionSub;

  // TtsLineBank 훅: 마일스톤/페이스 변화 이벤트 (호출자가 모드별로 처리)
  void Function(int km)? onMilestoneKm;
  void Function(String category)? onPaceCategory; // 'speedup' / 'slowdown' / 'hold'
  int _lastPaceCheckS = 0;
  double _prevAvgPace = 0;
  int _lastMilestoneNotified = 0;
  static const int _paceCheckIntervalS = 60;
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
  bool _isDisposed = false;

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
    final result = (total - _pausedDuration - activePause).inSeconds;
    return result < 0 ? 0 : result;
  }

  double get avgPace {
    if (_totalDistanceM < 10 || durationS < 1) return 0;
    return (durationS / 60) / (_totalDistanceM / 1000); // min/km
  }

  int get calories => (_totalDistanceM * 0.06).round(); // 대략적 계산

  double get currentSpeed => _currentSpeed;
  double get heading => _heading;

  bool get isValidSpeed => _currentSpeed >= minSpeedMps && _currentSpeed <= maxSpeedMps;

  /// "너무 느려" 판정은 **누적 평균**, "너무 빨라(차량)" 판정은 **순간 속도**.
  /// 순간 속도만 쓰면 GPS 튐/건물 반사/에뮬 mock 에서 경고가 잘못 뜸.
  String? get speedWarning {
    // 초반 15초는 GPS 안정화 유예
    if (durationS < 15) {
      if (_currentSpeed > maxSpeedMps) return S.tooFast;
      return null;
    }
    // 30초 지났는데 100m 못 움직임 → 진짜 느림
    if (durationS >= 30 && _totalDistanceM < 100) return S.tooSlow;
    // 평균 페이스 20분/km 이상 = 3km/h 미만(걷기 이하)
    if (_totalDistanceM > 50 && avgPace > 0 && avgPace > 20) return S.tooSlow;
    // 차량 감지는 순간 속도 기준 유지
    if (_currentSpeed > maxSpeedMps) return S.tooFast;
    return null;
  }

  /// TTS 자연어 페이스 포맷 — 화면용 3'59" 기호 대신 "3분 59초" 발음.
  String get _paceForTts {
    if (avgPace <= 0) return '';
    final m = avgPace.floor();
    final s = ((avgPace - m) * 60).round();
    if (S.isKo) {
      return s == 0 ? '$m분' : '$m분 $s초';
    }
    return s == 0
        ? '$m minute${m == 1 ? '' : 's'}'
        : '$m min $s sec';
  }

  Position? get currentPosition => _lastPosition;
  int get currentShadowIndex => _currentShadowIndex;

  RunPoint? get currentShadowPoint {
    if (_shadowPoints == null || _currentShadowIndex >= _shadowPoints!.length) return null;
    return _shadowPoints![_currentShadowIndex];
  }

  /// 도플갱어와의 거리 (양수 = 앞서는 중, 음수 = 뒤처지는 중)
  /// 도플갱어 위치 업데이트 (GPS 콜백에서 1번만 호출)
  void updateShadowPosition() {
    if (_shadowPoints == null || _lastPosition == null) return;
    final elapsed = durationS;
    if (elapsed < _shadowGracePeriodS) return;
    // GPS 지연/정지 방어: 유의미한 움직임 없으면 60초까지 도플갱어도 대기
    if (_totalDistanceM < _shadowStartupMinM && elapsed < _shadowStartupMaxS) return;
    final shadowElapsedS = (elapsed - _shadowGracePeriodS) * _shadowSpeedMultiplier;
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
  }

  /// 도플갱어와의 거리 (읽기 전용, 몇 번 읽어도 같은 값)
  double get shadowDistanceM {
    if (_shadowPoints == null || _lastPosition == null || currentShadowPoint == null) {
      return double.infinity;
    }
    if (durationS < _shadowGracePeriodS) return 200.0;
    // GPS 지연/정지 동안은 +200m 유지 (도플갱어도 움직이지 않으니 일관성 있게)
    if (_totalDistanceM < _shadowStartupMinM && durationS < _shadowStartupMaxS) return 200.0;
    return _totalDistanceM - _cachedShadowDist;
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
      _safeNotify();
    }
  }

  void resumeRun() {
    if (_isPaused && _pauseStart != null) {
      _pausedDuration += DateTime.now().difference(_pauseStart!);
      _pauseStart = null;
      _isPaused = false;
      _safeNotify();
    }
  }

  /// 러닝 시작
  Future<bool> startRun({int? shadowRunId, double shadowSpeedMultiplier = 1.0}) async {
    if (_isDisposed) return false;
    // GPS 서비스 활성화 확인
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (_isDisposed) return false;
    if (!serviceEnabled) return false;

    var permission = await Geolocator.checkPermission();
    if (_isDisposed) return false;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (_isDisposed) return false;
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return false;
    }

    _shadowRunId = shadowRunId;
    _shadowSpeedMultiplier = shadowSpeedMultiplier;
    if (shadowRunId != null) {
      _shadowPoints = await DatabaseHelper.getRunPoints(shadowRunId);
      if (_isDisposed) return false;
      debugPrint('SHADOW: loaded ${_shadowPoints?.length ?? 0} points for run $shadowRunId');

      // UI 라벨(느림 6:30 / 보통 5:30 / 빠름 4:30)에 맞춰 실제 multiplier 재계산.
      // shadowSpeedMultiplier(0.8/1.0/1.2)는 UI level을 나타내는 값이므로 목표 페이스로 매핑 후
      // 원본 기록 평균 페이스와 비율로 실제 시간 배수 산출.
      if (_shadowPoints != null && _shadowPoints!.length >= 2) {
        double origDist = 0;
        for (int i = 1; i < _shadowPoints!.length; i++) {
          origDist += _distanceBetweenPoints(
            _shadowPoints![i - 1].latitude, _shadowPoints![i - 1].longitude,
            _shadowPoints![i].latitude, _shadowPoints![i].longitude,
          );
        }
        final origDurS = (_shadowPoints!.last.timestampMs - _shadowPoints!.first.timestampMs) / 1000.0;
        if (origDist > 0 && origDurS > 0) {
          final origPaceSecPerKm = origDurS / (origDist / 1000);
          final targetPaceSecPerKm = shadowSpeedMultiplier < 0.9
              ? 390.0
              : shadowSpeedMultiplier > 1.1
                  ? 270.0
                  : 330.0;
          _shadowSpeedMultiplier = origPaceSecPerKm / targetPaceSecPerKm;
          debugPrint('SHADOW: orig=${origPaceSecPerKm.toStringAsFixed(1)}s/km '
              'target=${targetPaceSecPerKm.toStringAsFixed(0)}s/km '
              'mult=${_shadowSpeedMultiplier.toStringAsFixed(3)}');
        }
      }
    } else {
      debugPrint('SHADOW: no shadow run (new run mode)');
    }

    // 기존 구독 누수 방지
    await _positionSub?.cancel();
    if (_isDisposed) return false;
    _positionSub = null;

    _points.clear();
    _totalDistanceM = 0;
    _lastPosition = null;
    _currentShadowIndex = 0;
    _cachedShadowDist = 0;
    _cachedShadowIdx = 0;
    _lastAnnouncedKm = 0;
    _lastMilestoneNotified = 0;
    _lastPaceCheckS = 0;
    _prevAvgPace = 0;
    _isPaused = false;
    _pausedDuration = Duration.zero;
    _pauseStart = null;
    _isRunning = true;

    // km 스플릿 음성 알림용 TTS 초기화
    try {
      await _tts.setLanguage(S.isKo ? 'ko-KR' : 'en-US');
      if (_isDisposed) return false;
      await _tts.setSpeechRate(0.5);
      if (_isDisposed) return false;
      await _tts.setPitch(1.0);
      if (_isDisposed) return false;
      await _tts.setVolume(1.0);
      if (_isDisposed) return false;
      _ttsReady = true;
    } catch (e) {
      debugPrint('TTS 초기화 실패: $e');
    }
    if (_isDisposed) return false;

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

    if (_isDisposed) return false;
    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onPosition);

    _safeNotify();
    return true;
  }

  void _safeNotify() {
    if (_isDisposed) return;
    notifyListeners();
  }

  void _onPosition(Position pos) {
    if (_isDisposed || !_isRunning) return;

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
      _safeNotify();
      onPositionUpdate?.call(); // 차량 감지 자동 복귀 위해 콜백은 호출
      return;
    }

    if (_lastPosition != null) {
      // 거리 기반 필터 (isValidSpeed 순간속도 의존 제거):
      // iOS 백그라운드·건물 반사·뺑뺑 회전 시 순간 speed가 0 또는 튐 값으로 잡혀
      // 거리 누적이 중단되던 버그 수정 (2026-04 사용자 리포트).
      //
      // 판정 기준:
      //  - 한 샘플 점프 > 150m  → GPS drift로 간주, 드롭
      //    (샘플 간격 1~3초 가정, 150m = 180~540 km/h 불가능)
      //  - 점프 < 1.5m           → GPS 노이즈, 드롭 (제자리에서 마커 흔들림)
      //  - 그 사이                 → 정상 이동으로 인정
      final deltaM = Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        pos.latitude, pos.longitude,
      );

      if (deltaM >= 1.5 && deltaM <= 150) {
        _totalDistanceM += deltaM;
        _points.add(RunPoint(
          runId: 0,
          latitude: pos.latitude,
          longitude: pos.longitude,
          timestampMs: DateTime.now().millisecondsSinceEpoch,
          speedMps: pos.speed,
        ));
      }
      // 점프 > 150m은 위치·거리 모두 무시 (다음 샘플과 비교)
      // 점프 < 1.5m는 위치만 갱신 (마지막 부분에서 _lastPosition = pos)
    } else if (_lastPosition == null) {
      // 첫 포인트는 항상 추가 (시작 위치)
      _points.add(RunPoint(
        runId: 0,
        latitude: pos.latitude,
        longitude: pos.longitude,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
        speedMps: pos.speed,
      ));
    }

    // km 스플릿 음성 알림 (마라토너 모드에서는 비활성화)
    final currentKm = (_totalDistanceM / 1000).floor();
    if (currentKm > _lastAnnouncedKm && _ttsReady && kmSplitTtsEnabled) {
      _lastAnnouncedKm = currentKm;
      _announceKmSplit(currentKm);
    }

    // TtsLineBank 훅 — 마일스톤 콜백 (kmSplitTts 플래그와 무관)
    if (currentKm > 0 && onMilestoneKm != null) {
      // 같은 km 중복 호출 방지: _lastAnnouncedKm 를 재활용하되 kmSplit 비활성 시에도 동작하도록
      // 별도 추적 필드 없이 currentKm 증가 시점에만 호출.
      // _lastAnnouncedKm 은 kmSplitTtsEnabled 분기에서만 갱신되므로, 비활성 시에는 매 tick 호출될 수 있음.
      // 그래서 자체 추적:
      if (currentKm != _lastMilestoneNotified) {
        _lastMilestoneNotified = currentKm;
        onMilestoneKm!(currentKm);
      }
    }

    // TtsLineBank 훅 — 페이스 카테고리 (60초마다, 50m 이상 달린 후)
    if (durationS - _lastPaceCheckS >= _paceCheckIntervalS && _totalDistanceM > 50) {
      _lastPaceCheckS = durationS;
      final curr = avgPace;
      if (_prevAvgPace > 0 && curr > 0 && onPaceCategory != null) {
        final diff = (curr - _prevAvgPace) / _prevAvgPace;
        final cat = diff < -0.05 ? 'speedup' : diff > 0.05 ? 'slowdown' : 'hold';
        onPaceCategory!(cat);
      }
      _prevAvgPace = curr;
    }

    // GPS drift(150m+) 상황에선 _lastPosition을 덮어쓰지 않고 원래 위치 유지 →
    // 다음 샘플이 정상이면 drift 위치 건너뛰고 정상 차이로 누적.
    // _lastPosition == null 이면(첫 샘플) 반드시 세팅.
    if (_lastPosition == null) {
      _lastPosition = pos;
    } else {
      final deltaM = Geolocator.distanceBetween(
        _lastPosition!.latitude, _lastPosition!.longitude,
        pos.latitude, pos.longitude,
      );
      // 정상 범위이면 업데이트 (0~150m). 큰 점프는 다음 샘플과 비교할 수 있게 유지.
      if (deltaM <= 150) {
        _lastPosition = pos;
      }
    }

    _safeNotify();

    // 백그라운드에서도 동작하는 콜백 호출 (Timer 대체)
    if (!_isDisposed) onPositionUpdate?.call();
  }

  /// 러닝 종료 및 저장
  Future<RunModel?> stopRun() async {
    if (_isDisposed) return null;
    _isRunning = false;
    _tts.stop();
    await _positionSub?.cancel();
    if (_isDisposed) return null;
    _positionSub = null;

    if (_points.length < 2 || _totalDistanceM < 10) {
      _safeNotify();
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
      if (_isDisposed) return null;
    }

    // 도플갱어 모드 최종 간격 — multiplier 반영된 실시간 값을 그대로 저장.
    // 결과 화면/홈 카피가 DB에서 읽어 재계산 없이 쓸 수 있도록.
    final double? finalGap = isChallenge ? shadowDistanceM : null;

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
      finalShadowGapM: finalGap,
    );

    final runId = await DatabaseHelper.insertRunWithPoints(
      run,
      _points,
      incrementChallenge: isChallenge,
    );
    if (_isDisposed) {
      // DB 저장은 완료됐으니 결과는 반환하되, notify는 skip.
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
        finalShadowGapM: run.finalShadowGapM,
      );
    }

    _safeNotify();
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
      finalShadowGapM: run.finalShadowGapM,
    );
  }

  Future<void> _announceKmSplit(int km) async {
    if (_isDisposed || !_isRunning) return;
    // TTS는 자연어 ("3분 59초"). 화면용 3'59" 기호는 TTS가 피트/인치로 오독.
    final text = S.isKo
        ? '$km킬로미터. 페이스 $_paceForTts'
        : '$km kilometer${km == 1 ? '' : 's'}. Pace $_paceForTts';

    await _tts.awaitSpeakCompletion(true);
    if (_isDisposed || !_isRunning) return;
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

  /// startup 중 abort 시 호출: GPS 구독만 정리. dispose()는 widget 쪽에서.
  Future<void> abortStartup() async {
    _isRunning = false;
    onPositionUpdate = null;
    final sub = _positionSub;
    _positionSub = null;
    await sub?.cancel();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _isRunning = false;
    onPositionUpdate = null;
    _positionSub?.cancel();
    _positionSub = null;
    _tts.stop();
    super.dispose();
  }
}
