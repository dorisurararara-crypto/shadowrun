import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

enum ThreatLevel { safe, warning, danger, critical, aheadClose, aheadMid, aheadFar }

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
  bool _wasAhead = false;
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
    if (distanceM < 0) {
      newLevel = ThreatLevel.critical; // 음수 = 도플갱어가 앞서감
    } else if (distanceM < 50) {
      newLevel = ThreatLevel.danger; // 0~50m: 도플갱어 바로 뒤
    } else if (distanceM < 150) {
      newLevel = ThreatLevel.warning; // 50~150m: 도플갱어 추격 중
    } else if (distanceM < 200) {
      newLevel = ThreatLevel.safe; // 150~200m: 안전권 진입
    } else if (distanceM < 250) {
      newLevel = ThreatLevel.aheadClose; // 200~250m: 막 앞서나가기 시작
    } else if (distanceM < 400) {
      newLevel = ThreatLevel.aheadMid; // 250~400m: 여유 있는 리드
    } else {
      newLevel = ThreatLevel.aheadFar; // 400m+: 압도적 리드
    }

    // 전환 감지: 앞서 있다가 다시 추격당하기 시작
    final isNowAhead = distanceM >= 200;
    if (_wasAhead && !isNowAhead && _ttsEnabled) {
      await _playTts('tts_losing_lead');
    }
    _wasAhead = isNowAhead;

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
          // 레벨 5: 2차 대사 사용
          await _playTts(_horrorLevel >= 5 ? 'tts_warning2' : 'tts_warning');
        }
        break;

      case ThreatLevel.danger:
        if (_horrorLevel >= 3) {
          await _playBgm('breathing.mp3');
          // 레벨 5: BGM 볼륨 증가
          _bgmPlayer.setVolume(_horrorLevel >= 5 ? 0.9 : 0.6);
        }
        if (_ttsEnabled) {
          await _playTts(_horrorLevel >= 5 ? 'tts_danger2' : 'tts_danger');
        }
        break;

      case ThreatLevel.critical:
        await _stopBgm();
        if (_horrorLevel >= 4) {
          await _playSfx(_horrorLevel >= 5 ? 'jumpscare2.mp3' : 'jumpscare.mp3');
        }
        if (_ttsEnabled) {
          await _playTts('tts_critical');
        }
        break;

      case ThreatLevel.aheadClose:
        await _stopBgm();
        if (_ttsEnabled) {
          await _playTts('tts_ahead_close');
        }
        break;

      case ThreatLevel.aheadMid:
        await _stopBgm();
        if (_ttsEnabled) {
          await _playTts('tts_ahead_mid');
        }
        break;

      case ThreatLevel.aheadFar:
        await _stopBgm();
        if (_ttsEnabled) {
          await _playTts('tts_ahead_far');
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

  Future<void> playDefeatedTts() async {
    if (_ttsEnabled) {
      await _playTts('tts_defeated');
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
        const hasEnglish = {
          'tts_safe', 'tts_warning', 'tts_danger', 'tts_critical',
          'tts_ahead_close', 'tts_ahead_mid', 'tts_ahead_far',
          'tts_losing_lead', 'tts_defeated',
          'tts_start', 'tts_survived', 'tts_warning2', 'tts_danger2',
        };
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
      case ThreatLevel.aheadClose:
      case ThreatLevel.aheadMid:
      case ThreatLevel.aheadFar:
        break; // 앞서가는 중엔 진동 없음
    }
  }

  double get vignetteIntensity {
    switch (_currentLevel) {
      case ThreatLevel.safe:
        return 0.0;
      case ThreatLevel.warning:
        if (_horrorLevel >= 5) return 0.5;
        return _horrorLevel >= 2 ? 0.4 : 0.0;
      case ThreatLevel.danger:
        if (_horrorLevel >= 5) return 0.9;
        return _horrorLevel >= 3 ? 0.7 : 0.3;
      case ThreatLevel.critical:
        return 1.0;
      case ThreatLevel.aheadClose:
      case ThreatLevel.aheadMid:
      case ThreatLevel.aheadFar:
        return 0.0; // 앞서가는 중엔 비네트 없음
    }
  }

  void dispose() {
    _isDisposed = true;
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _ttsPlayer.dispose();
  }
}
