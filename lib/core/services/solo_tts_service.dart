import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class SoloTtsService {
  final AudioPlayer _ttsPlayer = AudioPlayer();
  bool _isDisposed = false;
  String _voiceId = 'harry';
  final _rng = Random();

  Future<void> initialize({String voice = 'harry'}) async {
    _voiceId = voice;
  }

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
      _ttsPlayer.play();
    } catch (e) {
      debugPrint('Solo TTS error: $e');
    }
  }

  void dispose() {
    _isDisposed = true;
    _ttsPlayer.dispose();
  }
}
