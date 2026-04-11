import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

enum ThreatLevel { safe, warning, danger, critical }

class HorrorService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  ThreatLevel _currentLevel = ThreatLevel.safe;
  int _horrorLevel = 3; // 1~5
  bool _ttsEnabled = true;
  bool _vibrationEnabled = true;
  bool _hasVibrator = false;

  ThreatLevel get currentLevel => _currentLevel;

  Future<void> initialize({
    int horrorLevel = 3,
    bool ttsEnabled = true,
    bool vibrationEnabled = true,
  }) async {
    _horrorLevel = horrorLevel;
    _ttsEnabled = ttsEnabled;
    _vibrationEnabled = vibrationEnabled;
    _hasVibrator = await Vibration.hasVibrator() ?? false;

    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(0.8);
  }

  /// 도플갱어와의 거리(미터)에 따라 위협 레벨 업데이트
  Future<void> updateThreat(double distanceM) async {
    ThreatLevel newLevel;
    if (distanceM > 200) {
      newLevel = ThreatLevel.safe;
    } else if (distanceM > 100) {
      newLevel = ThreatLevel.warning;
    } else if (distanceM > 0) {
      newLevel = ThreatLevel.danger;
    } else {
      newLevel = ThreatLevel.critical;
    }

    if (newLevel != _currentLevel) {
      _currentLevel = newLevel;
      await _onLevelChanged(newLevel, distanceM);
    }

    if (_vibrationEnabled && _hasVibrator && _horrorLevel >= 2) {
      _updateVibration(newLevel);
    }
  }

  Future<void> _onLevelChanged(ThreatLevel level, double distance) async {
    switch (level) {
      case ThreatLevel.safe:
        await _stopSfx();
        if (_ttsEnabled && _horrorLevel >= 2) {
          await _speak('좋은 페이스입니다.');
        }
        break;

      case ThreatLevel.warning:
        if (_horrorLevel >= 2) {
          // 심박 효과음은 에셋이 있을 때 재생
          // await _playSfx('heartbeat_slow.mp3');
        }
        if (_ttsEnabled) {
          await _speak('뒤에서 뭔가 다가옵니다.');
        }
        break;

      case ThreatLevel.danger:
        if (_horrorLevel >= 3) {
          // await _playSfx('breathing_heavy.mp3');
        }
        if (_ttsEnabled) {
          await _speak('잡히기 직전입니다! 속도를 올리세요!');
        }
        break;

      case ThreatLevel.critical:
        if (_horrorLevel >= 4) {
          // await _playSfx('jumpscare.mp3');
        }
        if (_ttsEnabled) {
          await _speak('잡혔습니다.');
        }
        break;
    }
  }

  void _updateVibration(ThreatLevel level) {
    switch (level) {
      case ThreatLevel.safe:
        break;
      case ThreatLevel.warning:
        if (_horrorLevel >= 3) {
          Vibration.vibrate(duration: 100);
        }
        break;
      case ThreatLevel.danger:
        Vibration.vibrate(duration: 300, amplitude: 200);
        break;
      case ThreatLevel.critical:
        Vibration.vibrate(pattern: [0, 500, 100, 500, 100, 500], intensities: [0, 255, 0, 255, 0, 255]);
        break;
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS 에러: $e');
    }
  }

  Future<void> _stopSfx() async {
    try {
      await _sfxPlayer.stop();
    } catch (_) {}
  }

  /// 위협 레벨에 따른 비네팅 강도 (0.0 ~ 1.0)
  double get vignetteIntensity {
    switch (_currentLevel) {
      case ThreatLevel.safe:
        return 0.0;
      case ThreatLevel.warning:
        return _horrorLevel >= 2 ? 0.3 : 0.0;
      case ThreatLevel.danger:
        return _horrorLevel >= 3 ? 0.6 : 0.3;
      case ThreatLevel.critical:
        return 1.0;
    }
  }

  void dispose() {
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _tts.stop();
  }
}
