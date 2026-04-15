import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class MarathonService {
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final Random _random = Random();

  String _voiceId = 'drill';
  bool _isDisposed = false;
  bool _isPlaying = false;

  final Set<int> _playedKmMilestones = {};
  final Set<int> _playedTimeMinutes = {};
  int _nextRandomTtsTime = 90; // 1.5분 후부터 (기존 2분 → 단축)
  int _nextEncourageTtsTime = 60; // 1분 후부터 격려 시작

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
  static const int _earlyVariants = 5;
  static const int _midVariants = 7;
  static const int _lateVariants = 7;
  static const int _newTipVariants = 8;
  static const int _newPaceFastVariants = 4;
  static const int _newPaceSlowVariants = 4;

  // 격려 간격 (초) — 1.5~2.5분
  static const int _encourageIntervalMin = 90;
  static const int _encourageIntervalMax = 150;
  // 랜덤 TTS 간격 (초) — 2~4분 (기존 3~5분 → 단축)
  static const int _randomIntervalMin = 120;
  static const int _randomIntervalMax = 240;

  Future<void> initialize({String voice = 'drill'}) async {
    _voiceId = voice;
    // 배경음 시작 (새소리 + 러닝 백색소음)
    try {
      await _bgmPlayer.setAsset('assets/audio/bgm_running_ambient.mp3');
      _bgmPlayer.setLoopMode(LoopMode.one);
      _bgmPlayer.setVolume(0.25);
      _bgmPlayer.play().catchError((_) {});
    } catch (e) {
      debugPrint('Marathon BGM 에러: $e');
    }
  }

  Future<void> playStartTts() async {
    final variant = _random.nextInt(_startVariants) + 1;
    await _playTts('tts_marathon_start', variant: variant);
  }

  Future<void> playKmTts(int km) async {
    if (!_availableKmMilestones.contains(km)) return;
    if (_playedKmMilestones.contains(km)) return;
    if (_isPlaying) return;
    final variant = _random.nextInt(_kmVariants) + 1;
    final success = await _playTts('tts_marathon_${km}km', variant: variant);
    if (success) _playedKmMilestones.add(km);
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
    final roll = _random.nextInt(3);
    if (roll == 0) {
      final n = _random.nextInt(_quoteCount) + 1;
      success = await _playTtsSimple('tts_quote', n);
    } else if (roll == 1) {
      final n = _random.nextInt(_tipCount) + 1;
      success = await _playTtsSimple('tts_tip', n);
    } else {
      // 새 팁 대사
      final n = _random.nextInt(_newTipVariants) + 1;
      success = await _playTtsSimple('tts_marathon_tip', n);
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

      String filename;
      if (_voiceId == 'harry') {
        filename = '$langBase.mp3';
      } else {
        filename = '${langBase}_$_voiceId.mp3';
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

  Future<bool> _playTtsSimple(String baseName, int number) async {
    if (_isDisposed || _isPlaying) return false;
    _isPlaying = true;
    try {
      String name = '${baseName}_$number';

      String filename;
      if (_voiceId == 'harry') {
        filename = '$name.mp3';
      } else {
        filename = '${name}_$_voiceId.mp3';
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
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _ttsPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
