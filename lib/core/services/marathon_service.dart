import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/bgm_preferences.dart';
import 'package:shadowrun/core/services/watch_connector_service.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';
import 'package:shadowrun/features/running/data/legend_runners.dart';

class MarathonService {
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final Random _random = Random();

  String _voiceId = 'drill';
  bool _isDisposed = false;
  bool _isPlaying = false;

  /// 테마별 고정 voice (새 3테마). 사용자 설정 무시, 캐릭터 보이스 강제.
  String get _effectiveVoice {
    switch (ThemeManager.I.currentId) {
      case ThemeId.filmNoir:
        return 'drill';
      case ThemeId.editorial:
        return 'harry';
      case ThemeId.neoNoirCyber:
        return 'callum';
      case ThemeId.pureCinematic:
      case ThemeId.koreanMystic:
        return _voiceId;
    }
  }

  final Set<int> _playedKmMilestones = {};
  final Set<int> _playedTimeMinutes = {};
  int _nextRandomTtsTime = 90; // 1.5분 후부터 (기존 2분 → 단축)
  int _nextEncourageTtsTime = 60; // 1분 후부터 격려 시작

  // === Legend (전설 러너) 트래커 ===
  LegendRunner? _legend;
  FlutterTts? _flutterTts;
  bool _legendVibrationEnabled = true;
  bool _hasVibrator = false;
  bool _isLegendSpeaking = false; // flutter_tts 재생 중
  int _lastLegendAnnounceSec = -9999; // 마지막 legend 안내 경과초
  int? _lastBehindBucket; // 뒤처짐 250m 버킷 (1=250m, 2=500m, ...)
  int? _lastAheadBucket; // 앞섬 250m 버킷
  final Set<int> _announcedLegendKm = {}; // 이미 안내한 km (사용자 기준)
  bool? _wasAheadOfLegend; // 마지막 tick 기준 앞섰는지 (null = 초기)
  int _lastBehindBucketSeen = 0; // 뒤처짐 버킷 최고점 — "계속 벌어짐" 감지용
  static const int _legendMinIntervalSec = 25; // legend 안내 최소 간격

  static const List<int> _availableKmMilestones = [1, 2, 3, 4, 5, 7, 10, 15, 20];
  static const List<int> _timeMinutes = [5, 10, 15, 20, 30, 40, 50, 60];

  static const int _startVariants = 6;
  static const int _endVariants = 6;
  static const int _kmVariants = 4;
  static const int _paceVariants = 4;
  static const Map<int, int> _timeVariants = {5: 2, 10: 2, 15: 2, 20: 2, 30: 2, 40: 1, 50: 1, 60: 1};
  static const int _quoteCount = 12;
  static const int _tipCount = 8;

  // 새 격려 대사 변형 수
  static const int _earlyVariants = 8;
  static const int _midVariants = 12;
  static const int _lateVariants = 12;
  static const int _newTipVariants = 12;
  static const int _newPaceFastVariants = 4;
  static const int _newPaceSlowVariants = 4;
  // 재미 요소
  static const int _funfactCount = 10;
  static const int _athleteCount = 10;

  // 격려 간격 (초) — 1.5~2.5분
  static const int _encourageIntervalMin = 90;
  static const int _encourageIntervalMax = 150;
  // 랜덤 TTS 간격 (초) — 2~4분 (기존 3~5분 → 단축)
  static const int _randomIntervalMin = 120;
  static const int _randomIntervalMax = 240;

  static const _bgmOptions = [
    'bgm_running_ambient.mp3', 'bgm_running_ambient_v2.mp3',
    'bgm_running_ambient_v3.mp3', 'bgm_running_ambient_v4.mp3', 'bgm_running_ambient_v5.mp3',
  ];

  Future<void> initialize({
    String voice = 'drill',
    LegendRunner? legend,
    bool vibrationEnabled = true,
  }) async {
    _voiceId = voice;
    _legend = legend;
    _legendVibrationEnabled = vibrationEnabled;

    // flutter_tts 초기화 (legend가 있을 때만) — 동적 문장용.
    if (_legend != null) {
      try {
        final tts = FlutterTts();
        await tts.setLanguage(S.isKo ? 'ko-KR' : 'en-US');
        await tts.setVolume(0.8);
        await tts.setSpeechRate(0.5);
        await tts.setPitch(1.0);
        _flutterTts = tts;
      } catch (e) {
        debugPrint('Legend flutter_tts 초기화 에러: $e');
      }
      try {
        _hasVibrator = (await Vibration.hasVibrator()) == true;
      } catch (_) {
        _hasVibrator = false;
      }
    }

    final prefs = BgmPreferences.I;
    // 사용자가 BGM off 또는 외부 음악 모드면 재생 안 함.
    if (!prefs.enabled.value || prefs.externalMusicMode.value) {
      return;
    }
    try {
      // 테마별 BGM 풀 우선 사용, 없으면 기존 running_ambient 폴백
      final themePool = ThemeManager.I.current.bgmRunningPool;
      final pool = themePool.isNotEmpty ? themePool : _bgmOptions;
      final bgm = pool[_random.nextInt(pool.length)];
      await _bgmPlayer.setAsset('assets/audio/$bgm');
      _bgmPlayer.setLoopMode(LoopMode.one);
      _bgmPlayer.setVolume(prefs.effectiveVolume(0.25));
      _bgmPlayer.play().catchError((_) {});

      // 사용자가 볼륨 바꾸면 실시간 반영.
      prefs.volume.addListener(_onVolumeChanged);
      prefs.enabled.addListener(_onEnabledChanged);
    } catch (e) {
      debugPrint('Marathon BGM 에러: $e');
    }
  }

  void _onVolumeChanged() {
    if (_isDisposed) return;
    _bgmPlayer.setVolume(BgmPreferences.I.effectiveVolume(0.25));
  }

  void _onEnabledChanged() {
    if (_isDisposed) return;
    final on = BgmPreferences.I.enabled.value && !BgmPreferences.I.externalMusicMode.value;
    if (on) {
      _bgmPlayer.play().catchError((_) {});
    } else {
      _bgmPlayer.pause().catchError((_) {});
    }
  }

  Future<void> playStartTts() async {
    final variant = _random.nextInt(_startVariants) + 1;
    await _playTts('tts_marathon_start', variant: variant);
  }

  /// km 마일스톤 TTS.
  /// 반환값 의미:
  /// - true: 이 km 처리됨 (재생 성공/실패 무관, 또는 자산 없음) → 다음 km으로 진행
  /// - false: 다른 TTS 재생 중이라 지금 drop → 호출자가 다음 tick에서 재시도
  /// 재생 시도 자체는 1회만 — 파일 missing/타임아웃 등 영구 실패는 무한 retry하지 않음.
  Future<bool> playKmTts(int km) async {
    if (_playedKmMilestones.contains(km)) return true;
    if (!_availableKmMilestones.contains(km)) return true;
    if (_isPlaying) return false; // drop — retry 가능
    _playedKmMilestones.add(km); // 재생 시도했으면 마킹 (성공/실패 무관)
    final variant = _random.nextInt(_kmVariants) + 1;
    await _playTts('tts_marathon_${km}km', variant: variant);
    return true;
  }

  Future<void> playPaceTts(
    double currentPace,
    double avgHistoricalPace,
    double? previousKmPace,
  ) async {
    if (_isPlaying) return;
    final category = _determinePaceCategory(currentPace, avgHistoricalPace, previousKmPace);

    // 새 페이스 대사 50% 확률로 사용
    if (_random.nextBool()) {
      if (category == 'fast') {
        final n = _random.nextInt(_newPaceFastVariants) + 1;
        await _playTtsSimple('tts_pace_fast_new', n);
        return;
      } else if (category == 'slow' || category == 'veryslow') {
        final n = _random.nextInt(_newPaceSlowVariants) + 1;
        await _playTtsSimple('tts_pace_slow_new', n);
        return;
      }
    }

    final variant = _random.nextInt(_paceVariants) + 1;
    await _playTts('tts_pace_$category', variant: variant);
  }

  Future<void> playTimeTts(int elapsedSeconds) async {
    if (_isPlaying) return;
    final minutes = elapsedSeconds ~/ 60;
    for (final m in _timeMinutes) {
      if (minutes >= m && !_playedTimeMinutes.contains(m)) {
        final variants = _timeVariants[m] ?? 1;
        final variant = _random.nextInt(variants) + 1;
        final success = await _playTtsSimple('tts_time_${m}min', variant);
        if (success) _playedTimeMinutes.add(m);
        return;
      }
    }
  }

  /// 시간대별 격려 대사 (1.5~2.5분 간격)
  Future<void> playEncourageTts(int elapsedSeconds) async {
    if (_isPlaying) return;
    if (elapsedSeconds < 60) return;
    if (elapsedSeconds < _nextEncourageTtsTime) return;

    bool success;
    if (elapsedSeconds < 300) {
      // 0~5분: 초반 격려
      final n = _random.nextInt(_earlyVariants) + 1;
      success = await _playTtsSimple('tts_marathon_early', n);
    } else if (elapsedSeconds < 900) {
      // 5~15분: 중반 격려
      final n = _random.nextInt(_midVariants) + 1;
      success = await _playTtsSimple('tts_marathon_mid', n);
    } else {
      // 15분+: 후반 격려
      final n = _random.nextInt(_lateVariants) + 1;
      success = await _playTtsSimple('tts_marathon_late', n);
    }

    if (success) {
      _nextEncourageTtsTime = elapsedSeconds + _encourageIntervalMin +
          _random.nextInt(_encourageIntervalMax - _encourageIntervalMin);
    }
  }

  /// 랜덤 명언/조언/팁 (2~4분 간격)
  Future<void> playRandomTts(int elapsedSeconds) async {
    if (_isPlaying) return;
    if (elapsedSeconds < 120) return;
    if (elapsedSeconds < _nextRandomTtsTime) return;

    bool success;
    final roll = _random.nextInt(5);
    if (roll == 0) {
      final n = _random.nextInt(_quoteCount) + 1;
      success = await _playTtsSimple('tts_quote', n);
    } else if (roll == 1) {
      final n = _random.nextInt(_tipCount) + 1;
      success = await _playTtsSimple('tts_tip', n);
    } else if (roll == 2) {
      final n = _random.nextInt(_newTipVariants) + 1;
      success = await _playTtsSimple('tts_marathon_tip', n);
    } else if (roll == 3) {
      // 재미있는 러닝 팩트
      final n = _random.nextInt(_funfactCount) + 1;
      success = await _playTtsSimple('tts_funfact', n);
    } else {
      // 유명인 명언
      final n = _random.nextInt(_athleteCount) + 1;
      success = await _playTtsSimple('tts_athlete', n);
    }

    if (success) {
      _nextRandomTtsTime = elapsedSeconds + _randomIntervalMin +
          _random.nextInt(_randomIntervalMax - _randomIntervalMin);
    }
  }

  Future<void> playEndTts() async {
    await _stopBgm();
    final variant = _random.nextInt(_endVariants) + 1;
    await _playTts('tts_marathon_end', variant: variant);
  }

  String _determinePaceCategory(
    double currentPace,
    double avgHistoricalPace,
    double? previousKmPace,
  ) {
    if (avgHistoricalPace <= 0 || currentPace <= 0) return 'good';
    if (currentPace < avgHistoricalPace * 0.8) return 'fast';
    if (currentPace > avgHistoricalPace * 1.2) return 'veryslow';
    if (previousKmPace != null && currentPace > previousKmPace) return 'slow';
    return 'good';
  }

  Future<bool> _playTts(String baseName, {required int variant}) async {
    if (_isDisposed || _isPlaying) return false;
    _isPlaying = true;
    try {
      String langBase;
      if (S.isKo) {
        langBase = '${baseName}_$variant';
      } else {
        langBase = '${baseName}_en_$variant';
      }

      final voice = _effectiveVoice;
      String filename;
      if (voice == 'harry') {
        filename = '$langBase.mp3';
      } else {
        filename = '${langBase}_$voice.mp3';
      }

      await _ttsPlayer.setAsset('assets/audio/$filename');
      _ttsPlayer.setVolume(1.0);
      _ttsPlayer.play().catchError((_) {});
      await _ttsPlayer.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .timeout(const Duration(seconds: 10), onTimeout: () => _ttsPlayer.playerState);
      return true;
    } catch (e) {
      debugPrint('Marathon TTS 재생 에러: $e');
      return false;
    } finally {
      _isPlaying = false;
    }
  }

  // 영어 버전이 있는 기존 대사 목록
  static const _hasEnglishSimple = {
    'tts_time_5min', 'tts_time_10min', 'tts_time_15min', 'tts_time_20min',
    'tts_time_30min', 'tts_time_40min', 'tts_time_50min', 'tts_time_60min',
    'tts_quote', 'tts_tip',
    'tts_pace_fast', 'tts_pace_slow', 'tts_pace_good', 'tts_pace_veryslow',
    'tts_marathon_early', 'tts_marathon_mid', 'tts_marathon_late',
    'tts_marathon_tip', 'tts_pace_fast_new', 'tts_pace_slow_new',
    'tts_funfact', 'tts_athlete',
  };

  Future<bool> _playTtsSimple(String baseName, int number) async {
    if (_isDisposed || _isPlaying) return false;
    _isPlaying = true;
    try {
      String name;
      if (!S.isKo && _hasEnglishSimple.contains(baseName)) {
        name = '${baseName}_en_$number';
      } else {
        name = '${baseName}_$number';
      }

      final voice = _effectiveVoice;
      String filename;
      if (voice == 'harry') {
        filename = '$name.mp3';
      } else {
        filename = '${name}_$voice.mp3';
      }

      await _ttsPlayer.setAsset('assets/audio/$filename');
      _ttsPlayer.setVolume(1.0);
      _ttsPlayer.play().catchError((_) {});
      await _ttsPlayer.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .timeout(const Duration(seconds: 10), onTimeout: () => _ttsPlayer.playerState);
      return true;
    } catch (e) {
      debugPrint('Marathon TTS 재생 에러: $e');
      return false;
    } finally {
      _isPlaying = false;
    }
  }

  Future<void> _stopBgm() async {
    try { await _bgmPlayer.stop(); } catch (_) {}
  }

  Future<void> muteBgm() async {
    try { await _bgmPlayer.pause(); } catch (_) {}
  }

  Future<void> unmuteBgm() async {
    try { await _bgmPlayer.play(); } catch (_) {}
  }

  void resetMilestones() {
    _playedKmMilestones.clear();
    _playedTimeMinutes.clear();
    _nextRandomTtsTime = 90;
    _nextEncourageTtsTime = 60;
    _announcedLegendKm.clear();
    _lastBehindBucket = null;
    _lastAheadBucket = null;
    _wasAheadOfLegend = null;
    _lastBehindBucketSeen = 0;
    _lastLegendAnnounceSec = -9999;
  }

  // ============================================================
  // Legend(전설 러너) 트래커
  // ============================================================

  /// 매 GPS tick 또는 1초 tick에서 호출.
  /// 이벤트 판정 우선순위: 역전 > 새 km 도달 > 250m 버킷 변화.
  /// legend 이벤트가 발생하면 기존 km/시간 격려 TTS는 자연스럽게 밀림 (_isPlaying 체크).
  Future<void> updateProgress({
    required int elapsedSeconds,
    required double userDistanceKm,
  }) async {
    final legend = _legend;
    if (legend == null || _isDisposed) return;

    final legendKm = legend.virtualDistanceKmAt(elapsedSeconds);
    final diffKm = userDistanceKm - legendKm; // 양수 = 앞섬
    final diffMeters = (diffKm * 1000).round();
    final nowAhead = diffMeters >= 0;

    // 워치 전달 (silent, iOS 외에는 no-op)
    // ignore: unawaited_futures
    WatchConnectorService().sendLegendDiff(
      diffMeters.toDouble(),
      legendName: legend.displayName,
    );

    // 역전 이벤트 판정 (가장 우선순위 높음).
    if (_wasAheadOfLegend != null && _wasAheadOfLegend != nowAhead) {
      final passed = nowAhead; // true: 방금 추월, false: 방금 추월당함
      _wasAheadOfLegend = nowAhead;
      _resetLegendBucketsOnCross();
      await _announceLegendPass(legend, passed: passed, elapsedSec: elapsedSeconds);
      return;
    }
    _wasAheadOfLegend = nowAhead;

    // 새로운 km 도달 이벤트 (사용자 기준 1, 2, 3km …)
    final userWholeKm = userDistanceKm.floor();
    if (userWholeKm >= 1 && !_announcedLegendKm.contains(userWholeKm)) {
      _announcedLegendKm.add(userWholeKm);
      if (_canAnnounceLegend(elapsedSeconds)) {
        await _announceKmReached(legend, userWholeKm, legendKm, elapsedSeconds);
        return;
      }
    }

    // 250m 단위 버킷 변화 이벤트
    final absMeters = diffMeters.abs();
    final bucket = absMeters ~/ 250; // 0=<250m, 1=250~499, ...
    if (nowAhead) {
      if (bucket >= 1 && bucket != _lastAheadBucket) {
        _lastAheadBucket = bucket;
        _lastBehindBucket = null;
        // 사용자 앞섬 상태 — 햅틱 없음, TTS만 드물게
        if (_canAnnounceLegend(elapsedSeconds) && bucket >= 1 && bucket <= 4) {
          await _announceAhead(legend, absMeters, elapsedSeconds);
        }
      }
    } else {
      if (bucket >= 1 && bucket != _lastBehindBucket) {
        final widening = bucket > _lastBehindBucketSeen;
        _lastBehindBucket = bucket;
        _lastAheadBucket = null;
        if (bucket > _lastBehindBucketSeen) _lastBehindBucketSeen = bucket;
        // 햅틱은 간격 상관없이 (짧고 정보량 높음)
        _legendVibrateBehind(bucket, widening: widening);
        if (_canAnnounceLegend(elapsedSeconds)) {
          await _announceBehind(legend, absMeters, elapsedSeconds);
        }
      }
    }
  }

  bool _canAnnounceLegend(int elapsedSec) {
    if (_isLegendSpeaking) return false;
    if (_isPlaying) return false; // 기존 km/시간 TTS와 충돌 방지
    return (elapsedSec - _lastLegendAnnounceSec) >= _legendMinIntervalSec;
  }

  void _resetLegendBucketsOnCross() {
    _lastAheadBucket = null;
    _lastBehindBucket = null;
    _lastBehindBucketSeen = 0;
  }

  Future<void> _announceLegendPass(
    LegendRunner legend, {
    required bool passed,
    required int elapsedSec,
  }) async {
    final name = legend.displayName;
    final text = passed
        ? (S.isKo ? '$name을 앞섰습니다!' : 'You just passed $name!')
        : (S.isKo ? '$name가 다시 앞섰습니다' : '$name is back in front');
    if (passed) {
      _legendVibratePassed();
    } else {
      _legendVibrateOvertaken();
    }
    await _speakLegend(text, elapsedSec);
  }

  Future<void> _announceKmReached(
    LegendRunner legend,
    int userKm,
    double legendKm,
    int elapsedSec,
  ) async {
    final name = legend.displayName;
    final legendKmRounded = legendKm.toStringAsFixed(1);
    final text = S.isKo
        ? '${userKm}km 도달. $name는 ${legendKmRounded}km'
        : '$userKm km reached. $name at $legendKmRounded km';
    await _speakLegend(text, elapsedSec);
  }

  Future<void> _announceBehind(LegendRunner legend, int diffMeters, int elapsedSec) async {
    final name = legend.displayName;
    final text = S.isKo
        ? '$name과 $diffMeters미터 차이'
        : '$name is ${diffMeters}m ahead';
    await _speakLegend(text, elapsedSec);
  }

  Future<void> _announceAhead(LegendRunner legend, int diffMeters, int elapsedSec) async {
    final name = legend.displayName;
    final text = S.isKo
        ? '$name를 $diffMeters미터 앞서가고 있어요'
        : 'You are ${diffMeters}m ahead of $name';
    await _speakLegend(text, elapsedSec);
  }

  Future<void> _speakLegend(String text, int elapsedSec) async {
    final tts = _flutterTts;
    if (tts == null || _isDisposed) return;
    _isLegendSpeaking = true;
    _lastLegendAnnounceSec = elapsedSec;
    try {
      await tts.stop();
      await tts.speak(text);
    } catch (e) {
      debugPrint('Legend TTS 에러: $e');
    } finally {
      // 비동기 완료 대기 — flutter_tts는 awaitSpeakCompletion 지원이 플랫폼별이라
      // 보수적으로 짧은 지연 후 플래그 해제.
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        _isLegendSpeaking = false;
      });
    }
  }

  void _legendVibrateBehind(int bucket, {required bool widening}) {
    if (!_legendVibrationEnabled || !_hasVibrator || _isDisposed) return;
    try {
      if (bucket >= 2 && widening) {
        // 500m+ && 계속 벌어짐 → 길게 2번 (300ms × 2, 150ms 간격)
        Vibration.vibrate(pattern: [0, 300, 150, 300]);
      } else {
        // 250m 버킷 전환 → 짧게 1번
        Vibration.vibrate(duration: 100);
      }
    } catch (_) {}
  }

  void _legendVibratePassed() {
    if (!_legendVibrationEnabled || !_hasVibrator || _isDisposed) return;
    try {
      // 빠른 3번
      Vibration.vibrate(pattern: [0, 80, 80, 80, 80, 80]);
    } catch (_) {}
  }

  void _legendVibrateOvertaken() {
    if (!_legendVibrationEnabled || !_hasVibrator || _isDisposed) return;
    try {
      Vibration.vibrate(duration: 500);
    } catch (_) {}
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    BgmPreferences.I.volume.removeListener(_onVolumeChanged);
    BgmPreferences.I.enabled.removeListener(_onEnabledChanged);
    _ttsPlayer.dispose();
    _bgmPlayer.dispose();
    try {
      _flutterTts?.stop();
    } catch (_) {}
    _flutterTts = null;
    try {
      Vibration.cancel();
    } catch (_) {}
  }
}
