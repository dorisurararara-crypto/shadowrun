import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class MarathonService {
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final Random _random = Random();

  String _voiceId = 'drill';
  bool _isDisposed = false;
  bool _isPlaying = false; // 재생 중 중복 호출 방지

  // km 마일스톤 재생 추적
  final Set<int> _playedKmMilestones = {};
  // 시간 마일스톤 재생 추적
  final Set<int> _playedTimeMinutes = {};
  // 마지막 랜덤 TTS 시간 (초)
  int _nextRandomTtsTime = 120; // 최초 2분 후부터

  // 사용 가능한 km 마일스톤
  static const List<int> _availableKmMilestones = [1, 2, 3, 4, 5, 7, 10, 15, 20];
  // 시간 마일스톤 (분)
  static const List<int> _timeMinutes = [5, 10, 15, 20, 30, 40, 50, 60];

  // 각 상황별 변형 개수
  static const int _startVariants = 6;
  static const int _endVariants = 6;
  static const int _kmVariants = 4;
  static const int _paceVariants = 4;
  // 시간별 변형
  static const Map<int, int> _timeVariants = {5: 2, 10: 2, 15: 2, 20: 2, 30: 2, 40: 1, 50: 1, 60: 1};
  // 명언/조언
  static const int _quoteCount = 12;
  static const int _tipCount = 8;
  // 랜덤 TTS 간격 (초) — 3~5분
  static const int _randomIntervalMin = 180;
  static const int _randomIntervalMax = 300;

  Future<void> initialize({String voice = 'drill'}) async {
    _voiceId = voice;
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
    final variant = _random.nextInt(_paceVariants) + 1;
    await _playTts('tts_pace_$category', variant: variant);
  }

  /// 시간 기반 격려 (5분, 10분, ... 60분)
  Future<void> playTimeTts(int elapsedSeconds) async {
    if (_isPlaying) return;
    final minutes = elapsedSeconds ~/ 60;
    for (final m in _timeMinutes) {
      if (minutes >= m && !_playedTimeMinutes.contains(m)) {
        final variants = _timeVariants[m] ?? 1;
        final variant = _random.nextInt(variants) + 1;
        final success = await _playTtsSimple('tts_time_${m}min', variant);
        if (success) _playedTimeMinutes.add(m); // 재생 성공 시에만 마킹
        return;
      }
    }
  }

  /// 랜덤 명언/조언 (3~5분 간격)
  Future<void> playRandomTts(int elapsedSeconds) async {
    if (_isPlaying) return;
    if (elapsedSeconds < 120) return;
    // 다음 재생 시간이 아직 안 됐으면 스킵
    if (elapsedSeconds < _nextRandomTtsTime) return;

    // 50% 명언, 50% 조언
    bool success;
    if (_random.nextBool()) {
      final n = _random.nextInt(_quoteCount) + 1;
      success = await _playTtsSimple('tts_quote', n);
    } else {
      final n = _random.nextInt(_tipCount) + 1;
      success = await _playTtsSimple('tts_tip', n);
    }
    // 재생 성공 시 다음 시간 스케줄 (3~5분 후)
    if (success) {
      _nextRandomTtsTime = elapsedSeconds + _randomIntervalMin + _random.nextInt(_randomIntervalMax - _randomIntervalMin);
    }
  }

  Future<void> playEndTts() async {
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

  /// km/pace용 (variant 포함 파일명: tts_marathon_1km_1)
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
      // ignore: unawaited_futures
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

  /// 명언/조언/시간용 (파일명: tts_quote_1, tts_tip_1, tts_time_5min_1)
  Future<bool> _playTtsSimple(String baseName, int number) async {
    if (_isDisposed || _isPlaying) return false;
    _isPlaying = true;
    try {
      String name;
      if (S.isKo) {
        name = '${baseName}_$number';
      } else {
        name = '${baseName}_en_$number';
      }

      String filename;
      if (_voiceId == 'harry') {
        filename = '$name.mp3';
      } else {
        filename = '${name}_$_voiceId.mp3';
      }

      await _ttsPlayer.setAsset('assets/audio/$filename');
      _ttsPlayer.setVolume(1.0);
      // ignore: unawaited_futures
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

  void resetMilestones() {
    _playedKmMilestones.clear();
    _playedTimeMinutes.clear();
    _nextRandomTtsTime = 120;
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _ttsPlayer.dispose();
  }
}
