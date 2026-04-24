import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/tts_coordinator.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';

class SoloTtsService {
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isDisposed = false;
  bool _isPlaying = false;
  String _voiceId = 'harry';
  final _rng = Random();

  // Pure Cinematic 테마 — ElevenLabs Music API 2026-04-23 생성, noir minimal piano ambient.
  static const _pureFreerunPool = [
    'themes/t1_freerun_v1.mp3', 'themes/t1_freerun_v2.mp3',
  ];

  // Korean Mystic 테마 — ElevenLabs Music API 2026-04-23 생성, 전통 zen ambient (gayageum + daegeum).
  static const _mysticFreerunPool = [
    'themes/t3_freerun_v1.mp3', 'themes/t3_freerun_v2.mp3',
  ];

  // Film Noir (T2) — 1940s jazz ambient walking.
  static const _noirFreerunPool = [
    'themes/t2_freerun_v1.mp3', 'themes/t2_freerun_v2.mp3',
  ];

  // Editorial (T4) — 모던 orchestral + electronic pulse ambient.
  static const _editorialFreerunPool = [
    'themes/t4_freerun_v1.mp3', 'themes/t4_freerun_v2.mp3',
  ];

  // Neo-Noir Cyber (T5) — chill synthwave flow.
  static const _cyberFreerunPool = [
    'themes/t5_freerun_v1.mp3', 'themes/t5_freerun_v2.mp3',
  ];

  /// 현재 테마에 맞는 자유러닝 BGM 파일 선택.
  String _pickBgm() {
    switch (ThemeManager.I.currentId) {
      case ThemeId.koreanMystic:
        return _mysticFreerunPool[_rng.nextInt(_mysticFreerunPool.length)];
      case ThemeId.pureCinematic:
        return _pureFreerunPool[_rng.nextInt(_pureFreerunPool.length)];
      case ThemeId.filmNoir:
        return _noirFreerunPool[_rng.nextInt(_noirFreerunPool.length)];
      case ThemeId.editorial:
        return _editorialFreerunPool[_rng.nextInt(_editorialFreerunPool.length)];
      case ThemeId.neoNoirCyber:
        return _cyberFreerunPool[_rng.nextInt(_cyberFreerunPool.length)];
    }
  }

  /// 테마별 고정 voice. 새 3테마는 캐릭터 보이스로 강제.
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

  Future<void> initialize({String voice = 'harry'}) async {
    _voiceId = voice;
    try {
      final bgm = _pickBgm();
      await _bgmPlayer.setAsset('assets/audio/$bgm');
      _bgmPlayer.setLoopMode(LoopMode.one);
      _bgmPlayer.setVolume(0.25);
      _bgmPlayer.play().catchError((_) {});
    } catch (e) {
      debugPrint('Solo BGM error: $e');
    }
  }

  void muteBgm() => _bgmPlayer.setVolume(0);
  void unmuteBgm() => _bgmPlayer.setVolume(0.25);

  Future<void> playStartTts() async {
    final variant = _rng.nextInt(6) + 1;
    await _playTts('tts_start_solo_$variant');
  }

  Future<void> playEndTts() async {
    final variant = _rng.nextInt(6) + 1;
    await _playTts('tts_end_solo_$variant');
  }

  Future<void> _playTts(String baseName) async {
    if (_isDisposed) return;
    if (_isPlaying) return;
    _isPlaying = true;
    try {
      // 언어 분기: 영어는 variant 번호 앞에 _en 삽입
      // 예) tts_start_solo_1 → tts_start_solo_en_1
      String langBase = baseName;
      if (!S.isKo) {
        final lastUnderscore = baseName.lastIndexOf('_');
        langBase = '${baseName.substring(0, lastUnderscore)}_en${baseName.substring(lastUnderscore)}';
      }

      // 음성 분기: harry는 기본 파일명, callum/drill은 접미사.
      // 새 3테마는 사용자 voice 설정 무시하고 테마 고정 voice (특색 강화).
      final voice = _effectiveVoice;
      String filename;
      if (voice == 'harry') {
        filename = '$langBase.mp3';
      } else {
        filename = '${langBase}_$voice.mp3';
      }

      TtsCoordinator.I.begin(() => _ttsPlayer.stop());
      await _ttsPlayer.setAsset('assets/audio/$filename');
      _ttsPlayer.setVolume(1.0);
      // ignore: unawaited_futures
      _ttsPlayer.play().catchError((_) {});
      await _ttsPlayer.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .timeout(const Duration(seconds: 10), onTimeout: () => _ttsPlayer.playerState);
    } catch (e) {
      debugPrint('Solo TTS error: $e');
    } finally {
      _isPlaying = false;
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _ttsPlayer.dispose();
    _bgmPlayer.dispose();
  }
}
