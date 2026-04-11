import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

enum ThreatLevel { safe, warning, danger, critical }

class HorrorService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _ttsPlayer = AudioPlayer();

  ThreatLevel _currentLevel = ThreatLevel.safe;
  int _horrorLevel = 3;
  bool _ttsEnabled = true;
  bool _vibrationEnabled = true;
  bool _hasVibrator = false;
  bool _isDisposed = false;
  String _voiceId = 'harry'; // harry, callum, drill

  ThreatLevel get currentLevel => _currentLevel;

  Future<void> initialize({
    int horrorLevel = 3,
    bool ttsEnabled = true,
    bool vibrationEnabled = true,
    String voice = 'harry',
  }) async {
    _horrorLevel = horrorLevel;
    _ttsEnabled = ttsEnabled;
    _vibrationEnabled = vibrationEnabled;
    _voiceId = voice;
    _hasVibrator = (await Vibration.hasVibrator()) == true;
  }

  Future<void> updateThreat(double distanceM) async {
    ThreatLevel newLevel;
    if (distanceM > 200) {
      newLevel = ThreatLevel.safe;
    } else if (distanceM > 100) {
      newLevel = ThreatLevel.warning;
    } else if (distanceM >= 0) {
      newLevel = ThreatLevel.danger;
    } else {
      newLevel = ThreatLevel.critical; // 음수 = 도플갱어가 앞서감
    }

    if (newLevel != _currentLevel) {
      _currentLevel = newLevel;
      await _onLevelChanged(newLevel);
    }

    if (_vibrationEnabled && _hasVibrator && _horrorLevel >= 2) {
      _updateVibration(newLevel);
    }
  }

  Future<void> _onLevelChanged(ThreatLevel level) async {
    switch (level) {
      case ThreatLevel.safe:
        await _stopBgm();
        if (_ttsEnabled && _horrorLevel >= 2) {
          await _playTts('tts_safe');
        }
        break;

      case ThreatLevel.warning:
        if (_horrorLevel >= 2) {
          await _playBgm('heartbeat.mp3');
        }
        if (_ttsEnabled) {
          await _playTts('tts_warning');
        }
        break;

      case ThreatLevel.danger:
        if (_horrorLevel >= 3) {
          await _playBgm('breathing.mp3');
        }
        if (_ttsEnabled) {
          await _playTts('tts_danger');
        }
        break;

      case ThreatLevel.critical:
        await _stopBgm();
        if (_horrorLevel >= 4) {
          await _playSfx('jumpscare.mp3');
        }
        if (_ttsEnabled) {
          await _playTts('tts_critical');
        }
        break;
    }
  }

  Future<void> playStartTts() async {
    if (_ttsEnabled) {
      await _playTts('tts_start');
    }
  }

  Future<void> playSurvivedTts() async {
    if (_ttsEnabled) {
      await _playTts('tts_survived');
    }
  }

  Future<void> _playBgm(String filename) async {
    if (_isDisposed) return;
    try {
      await _bgmPlayer.setAsset('assets/audio/$filename');
      _bgmPlayer.setLoopMode(LoopMode.one);
      _bgmPlayer.setVolume(0.6);
      _bgmPlayer.play();
    } catch (e) {
      debugPrint('BGM 재생 에러: $e');
    }
  }

  Future<void> _playSfx(String filename) async {
    if (_isDisposed) return;
    try {
      await _sfxPlayer.setAsset('assets/audio/$filename');
      _sfxPlayer.setVolume(1.0);
      _sfxPlayer.play();
    } catch (e) {
      debugPrint('SFX 재생 에러: $e');
    }
  }

  Future<void> _playTts(String baseName) async {
    if (_isDisposed) return;
    try {
      // 언어 분기: 영어 버전이 있는 대사
      String langBase = baseName;
      if (!S.isKo) {
        const hasEnglish = {'tts_safe', 'tts_warning', 'tts_danger', 'tts_critical'};
        if (hasEnglish.contains(baseName)) {
          langBase = '${baseName}_en';
        }
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
      debugPrint('TTS 재생 에러: $e');
    }
  }

  Future<void> _stopBgm() async {
    try {
      await _bgmPlayer.stop();
    } catch (_) {}
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
        Vibration.vibrate(
          pattern: [0, 500, 100, 500, 100, 500],
          intensities: [0, 255, 0, 255, 0, 255],
        );
        break;
    }
  }

  double get vignetteIntensity {
    switch (_currentLevel) {
      case ThreatLevel.safe:
        return 0.0;
      case ThreatLevel.warning:
        return _horrorLevel >= 2 ? 0.4 : 0.0;
      case ThreatLevel.danger:
        return _horrorLevel >= 3 ? 0.7 : 0.3;
      case ThreatLevel.critical:
        return 1.0;
    }
  }

  void dispose() {
    _isDisposed = true;
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _ttsPlayer.dispose();
  }
}
