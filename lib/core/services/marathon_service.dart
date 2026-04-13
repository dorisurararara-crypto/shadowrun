import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class MarathonService {
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final Random _random = Random();

  String _voiceId = 'drill';
  bool _isDisposed = false;

  // km 마일스톤 재생 추적
  final Set<int> _playedKmMilestones = {};

  // 사용 가능한 km 마일스톤
  static const List<int> _availableKmMilestones = [1, 2, 3, 4, 5, 7, 10, 15, 20];

  // 각 상황별 변형 개수
  static const int _startVariants = 6;
  static const int _endVariants = 6;
  static const int _kmVariants = 4;
  static const int _paceVariants = 4;

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
    _playedKmMilestones.add(km);
    final variant = _random.nextInt(_kmVariants) + 1;
    await _playTts('tts_marathon_${km}km', variant: variant);
  }

  Future<void> playPaceTts(
    double currentPace,
    double avgHistoricalPace,
    double? previousKmPace,
  ) async {
    final category = _determinePaceCategory(
      currentPace,
      avgHistoricalPace,
      previousKmPace,
    );
    final variant = _random.nextInt(_paceVariants) + 1;
    await _playTts('tts_pace_$category', variant: variant);
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
    // pace는 min/km — 낮을수록 빠름
    // fast: 현재 페이스가 평균보다 20%+ 빠름 (값이 20%+ 낮음)
    if (currentPace < avgHistoricalPace * 0.8) return 'fast';

    // veryslow: 현재 페이스가 평균보다 20%+ 느림 (값이 20%+ 높음)
    if (currentPace > avgHistoricalPace * 1.2) return 'veryslow';

    // slow: 이전 km 대비 페이스 하락 (값 증가)
    if (previousKmPace != null && currentPace > previousKmPace) return 'slow';

    // good: 평균의 ±20% 이내이거나 약간 빠름
    return 'good';
  }

  Future<void> _playTts(String baseName, {required int variant}) async {
    if (_isDisposed) return;
    try {
      // 언어 분기: 마라톤 파일은 모두 영어 버전 있음
      String langBase;
      if (S.isKo) {
        langBase = '${baseName}_$variant';
      } else {
        langBase = '${baseName}_en_$variant';
      }

      // 음성 분기: harry는 기본 파일명, callum/drill은 접미사
      String filename;
      if (_voiceId == 'harry') {
        filename = '$langBase.mp3';
      } else {
        filename = '${langBase}_$_voiceId.mp3';
      }

      await _ttsPlayer.setAsset('assets/audio/$filename');
      _ttsPlayer.setVolume(1.0);
      _ttsPlayer.play();
    } catch (e) {
      debugPrint('Marathon TTS 재생 에러: $e');
    }
  }

  void resetMilestones() {
    _playedKmMilestones.clear();
  }

  void dispose() {
    _isDisposed = true;
    _ttsPlayer.dispose();
  }
}
