import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';

class SoloTtsService {
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final AudioPlayer _bgmPlayer = AudioPlayer();
  bool _isDisposed = false;
  bool _isPlaying = false;
  String _voiceId = 'harry';
  final _rng = Random();

  // v3/v4/zen3 제외 — ffmpeg 측정으로 삐이잉(v3 고주파 톤) / 클리핑(v4 0dBTP, zen3 -18 LUFS) 확정.
  // 모바일 BGM 기준 -23 LUFS 내외 + True Peak -2 dBTP 이하만 유지. default 테마 fallback.
  static const _bgmOptions = [
    'bgm_running_ambient.mp3', 'bgm_running_ambient_v2.mp3', 'bgm_running_ambient_v5.mp3',
    'bgm_freerun_zen1.mp3', 'bgm_freerun_zen2.mp3', 'bgm_freerun_zen4.mp3',
  ];

  // Pure Cinematic 테마 — ElevenLabs Music API 2026-04-23 생성, noir minimal piano ambient.
  static const _pureFreerunPool = [
    'themes/t1_freerun_v1.mp3', 'themes/t1_freerun_v2.mp3',
  ];

  // Korean Mystic 테마 — ElevenLabs Music API 2026-04-23 생성, 전통 zen ambient (gayageum + daegeum).
  static const _mysticFreerunPool = [
    'themes/t3_freerun_v1.mp3', 'themes/t3_freerun_v2.mp3',
  ];

  /// 현재 테마에 맞는 자유러닝 BGM 파일 선택.
  String _pickBgm() {
    final themeId = ThemeManager.I.currentId;
    if (themeId == ThemeId.koreanMystic) {
      return _mysticFreerunPool[_rng.nextInt(_mysticFreerunPool.length)];
    }
    if (themeId == ThemeId.pureCinematic) {
      return _pureFreerunPool[_rng.nextInt(_pureFreerunPool.length)];
    }
    return _bgmOptions[_rng.nextInt(_bgmOptions.length)];
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

      // 음성 분기: harry는 기본 파일명, callum/drill은 접미사
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
