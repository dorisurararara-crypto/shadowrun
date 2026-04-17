import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/core/services/bgm_preferences.dart';

enum ThreatLevel { safe, warningFar, warningClose, dangerFar, dangerClose, critical, aheadClose, aheadMid, aheadFar }

class HorrorService {
  final AudioPlayer _bgmPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _ttsPlayer = AudioPlayer();
  final _rng = Random();

  ThreatLevel _currentLevel = ThreatLevel.aheadFar;
  int _horrorLevel = 3;
  bool _ttsEnabled = true;
  bool _vibrationEnabled = true;
  bool _hasVibrator = false;
  bool _isDisposed = false;
  bool _isTtsPlaying = false;
  bool _wasAhead = false;
  String _voiceId = 'harry';
  DateTime? _lastPeriodicTts;

  ThreatLevel get currentLevel => _currentLevel;

  set ttsEnabled(bool value) => _ttsEnabled = value;

  Future<void> muteBgm() async {
    try { await _bgmPlayer.pause(); } catch (_) {}
  }

  Future<void> unmuteBgm() async {
    try { await _bgmPlayer.play(); } catch (_) {}
  }

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

  // 구간별 TTS 변형 (10개씩)
  static const _ttsVariants = {
    ThreatLevel.aheadFar: ['tts_ahead_far_1', 'tts_ahead_far_2', 'tts_ahead_far_3', 'tts_ahead_far_4', 'tts_ahead_far_5', 'tts_ahead_far_6', 'tts_ahead_far_7', 'tts_ahead_far_8', 'tts_ahead_far_9', 'tts_ahead_far_10'],
    ThreatLevel.aheadMid: ['tts_ahead_mid_1', 'tts_ahead_mid_2', 'tts_ahead_mid_3', 'tts_ahead_mid_4', 'tts_ahead_mid_5', 'tts_ahead_mid_6', 'tts_ahead_mid_7', 'tts_ahead_mid_8', 'tts_ahead_mid_9', 'tts_ahead_mid_10'],
    ThreatLevel.aheadClose: ['tts_ahead_close_1', 'tts_ahead_close_2', 'tts_ahead_close_3', 'tts_ahead_close_4', 'tts_ahead_close_5', 'tts_ahead_close_6', 'tts_ahead_close_7', 'tts_ahead_close_8', 'tts_ahead_close_9', 'tts_ahead_close_10'],
    ThreatLevel.safe: ['tts_safe_1', 'tts_safe_2', 'tts_safe_3', 'tts_safe_4', 'tts_safe_5', 'tts_safe_6', 'tts_safe_7', 'tts_safe_8', 'tts_safe_9', 'tts_safe_10'],
    ThreatLevel.warningFar: ['tts_warning_1', 'tts_warning_2', 'tts_warning_3', 'tts_warning_4', 'tts_warning_5', 'tts_warning_6', 'tts_warning_7', 'tts_warning_8', 'tts_warning_9', 'tts_warning_10'],
    ThreatLevel.warningClose: ['tts_warning_close_1', 'tts_warning_close_2', 'tts_warning_close_3', 'tts_warning_close_4', 'tts_warning_close_5', 'tts_warning_close_6', 'tts_warning_close_7', 'tts_warning_close_8', 'tts_warning_close_9', 'tts_warning_close_10'],
    ThreatLevel.dangerFar: ['tts_danger_1', 'tts_danger_2', 'tts_danger_3', 'tts_danger_4', 'tts_danger_5', 'tts_danger_6', 'tts_danger_7', 'tts_danger_8', 'tts_danger_9', 'tts_danger_10'],
    ThreatLevel.dangerClose: ['tts_critical_1', 'tts_critical_2', 'tts_critical_3', 'tts_critical_4', 'tts_critical_5', 'tts_critical_6', 'tts_critical_7', 'tts_critical_8', 'tts_critical_9', 'tts_critical_10'],
    ThreatLevel.critical: ['tts_critical_1', 'tts_critical_2', 'tts_critical_3', 'tts_critical_4', 'tts_critical_5', 'tts_critical_6', 'tts_critical_7', 'tts_critical_8', 'tts_critical_9', 'tts_critical_10'],
  };

  // 리드 잃을 때 변형
  static const _losingLeadVariants = [
    'tts_losing_lead_1', 'tts_losing_lead_2', 'tts_losing_lead_3', 'tts_losing_lead_4', 'tts_losing_lead_5',
    'tts_losing_lead_6', 'tts_losing_lead_7', 'tts_losing_lead_8', 'tts_losing_lead_9', 'tts_losing_lead_10',
  ];

  // 구간별 배경음 (3개 변형 중 랜덤)
  static const _bgmVariants = {
    ThreatLevel.aheadFar: ['bgm_peaceful.mp3', 'bgm_peaceful_v2.mp3', 'bgm_peaceful_v3.mp3'],
    ThreatLevel.aheadMid: ['bgm_calm_wind.mp3', 'bgm_calm_wind_v2.mp3', 'bgm_calm_wind_v3.mp3'],
    ThreatLevel.aheadClose: ['bgm_tension_low.mp3', 'bgm_tension_low_v2.mp3', 'bgm_tension_low_v3.mp3'],
    ThreatLevel.safe: ['bgm_dark_ambient.mp3', 'bgm_dark_ambient_v2.mp3', 'bgm_dark_ambient_v3.mp3'],
    ThreatLevel.warningFar: ['bgm_chase_far.mp3', 'bgm_chase_far_v2.mp3', 'bgm_chase_far_v3.mp3'],
    ThreatLevel.warningClose: ['bgm_chase_mid.mp3', 'bgm_chase_mid_v2.mp3', 'bgm_chase_mid_v3.mp3'],
    ThreatLevel.dangerFar: ['bgm_chase_close.mp3', 'bgm_chase_close_v2.mp3', 'bgm_chase_close_v3.mp3'],
    ThreatLevel.dangerClose: ['bgm_chase_critical.mp3', 'bgm_chase_critical_v2.mp3', 'bgm_chase_critical_v3.mp3'],
  };

  // 구간별 배경음 볼륨
  static const _bgmVolume = {
    ThreatLevel.aheadFar: 0.3,
    ThreatLevel.aheadMid: 0.35,
    ThreatLevel.aheadClose: 0.4,
    ThreatLevel.safe: 0.45,
    ThreatLevel.warningFar: 0.5,
    ThreatLevel.warningClose: 0.6,
    ThreatLevel.dangerFar: 0.7,
    ThreatLevel.dangerClose: 0.8,
  };

  // 주기적 TTS 간격 (초) — 위험할수록 더 자주
  static const _periodicInterval = {
    ThreatLevel.aheadFar: 45,
    ThreatLevel.aheadMid: 40,
    ThreatLevel.aheadClose: 35,
    ThreatLevel.safe: 35,
    ThreatLevel.warningFar: 30,
    ThreatLevel.warningClose: 25,
    ThreatLevel.dangerFar: 20,
    ThreatLevel.dangerClose: 15,
  };

  Future<void> updateThreat(double distanceM) async {
    ThreatLevel newLevel;
    if (distanceM < 0) {
      newLevel = ThreatLevel.critical;
    } else if (distanceM < 20) {
      newLevel = ThreatLevel.dangerClose; // 0~20m: 코앞
    } else if (distanceM < 50) {
      newLevel = ThreatLevel.dangerFar; // 20~50m: 바로 뒤
    } else if (distanceM < 100) {
      newLevel = ThreatLevel.warningClose; // 50~100m: 추격 근접
    } else if (distanceM < 150) {
      newLevel = ThreatLevel.warningFar; // 100~150m: 추격 중
    } else if (distanceM < 200) {
      newLevel = ThreatLevel.safe; // 150~200m: 안전권
    } else if (distanceM < 250) {
      newLevel = ThreatLevel.aheadClose; // 200~250m: 막 벗어남
    } else if (distanceM < 400) {
      newLevel = ThreatLevel.aheadMid; // 250~400m: 여유 리드
    } else {
      newLevel = ThreatLevel.aheadFar; // 400m+: 압도적 리드
    }

    // 리드 잃을 때 감지
    final isNowAhead = _wasAhead ? distanceM >= 190 : distanceM >= 210;
    if (_wasAhead && !isNowAhead && _ttsEnabled) {
      SfxService().glassBreak();
      final variant = _losingLeadVariants[_rng.nextInt(_losingLeadVariants.length)];
      await _playTts(variant);
    }
    _wasAhead = isNowAhead;

    if (newLevel != _currentLevel) {
      _currentLevel = newLevel;
      _lastPeriodicTts = DateTime.now();
      await _onLevelChanged(newLevel);
    } else {
      // 같은 레벨에 머물면 주기적 TTS
      await _playPeriodicTts(newLevel);
    }

    if (_vibrationEnabled && _hasVibrator && _horrorLevel >= 2) {
      _updateVibration(newLevel);
    }
  }

  Future<void> _playPeriodicTts(ThreatLevel level) async {
    if (!_ttsEnabled || level == ThreatLevel.critical) return;
    final interval = _periodicInterval[level] ?? 40;
    final now = DateTime.now();
    if (_lastPeriodicTts != null && now.difference(_lastPeriodicTts!).inSeconds < interval) return;
    _lastPeriodicTts = now;
    final variants = _ttsVariants[level];
    if (variants == null || variants.isEmpty) return;
    await _playTts(variants[_rng.nextInt(variants.length)]);
  }

  Future<void> _onLevelChanged(ThreatLevel level) async {
    // 배경음 변경 (3개 변형 중 랜덤)
    final bgmList = _bgmVariants[level];
    if (bgmList != null && bgmList.isNotEmpty) {
      final bgm = bgmList[_rng.nextInt(bgmList.length)];
      final vol = _bgmVolume[level] ?? 0.5;
      await _playBgm(bgm, volume: vol);
    } else {
      await _stopBgm();
    }

    // SFX
    switch (level) {
      case ThreatLevel.warningFar:
        SfxService().alertLow();
      case ThreatLevel.warningClose:
        SfxService().alertLow();
      case ThreatLevel.dangerFar:
        SfxService().alertHigh();
      case ThreatLevel.dangerClose:
        SfxService().alertHigh();
      case ThreatLevel.critical:
        if (_horrorLevel >= 4) {
          await _playSfx(_horrorLevel >= 5 ? 'jumpscare2.mp3' : 'jumpscare.mp3');
        }
      case ThreatLevel.aheadClose:
        SfxService().chainBreak();
      case ThreatLevel.aheadMid:
        SfxService().whoosh();
      case ThreatLevel.aheadFar:
        SfxService().fanfare();
      case ThreatLevel.safe:
        break;
    }

    // TTS (랜덤 변형)
    if (_ttsEnabled) {
      final variants = _ttsVariants[level];
      if (variants != null && variants.isNotEmpty) {
        await _playTts(variants[_rng.nextInt(variants.length)]);
      }
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

  Future<void> _playBgm(String filename, {double volume = 0.6}) async {
    if (_isDisposed) return;
    // BGM preferences 반영 — 사용자가 off 했으면 재생 자체 생략.
    final prefs = BgmPreferences.I;
    if (!prefs.enabled.value || prefs.externalMusicMode.value) {
      try { await _bgmPlayer.stop(); } catch (_) {}
      return;
    }
    try {
      await _bgmPlayer.setAsset('assets/audio/$filename');
      _bgmPlayer.setLoopMode(LoopMode.one);
      _bgmPlayer.setVolume(prefs.effectiveVolume(volume));
      _bgmPlayer.play().catchError((_) {});
    } catch (e) {
      debugPrint('BGM 재생 에러: $e');
    }
  }

  Future<void> _playSfx(String filename) async {
    if (_isDisposed) return;
    try {
      await _sfxPlayer.setAsset('assets/audio/$filename');
      _sfxPlayer.setVolume(1.0);
      _sfxPlayer.play().catchError((_) {});
    } catch (e) {
      debugPrint('SFX 재생 에러: $e');
    }
  }

  Future<void> _playTts(String baseName) async {
    if (_isDisposed || _isTtsPlaying) return;
    _isTtsPlaying = true;
    try {
      // 영어 분기
      String langBase = baseName;
      if (!S.isKo) {
        // 숫자로 끝나면 tts_ahead_far_1 → tts_ahead_far_en_1
        // 아니면 tts_start → tts_start_en
        final lastUnderscore = baseName.lastIndexOf('_');
        final lastPart = baseName.substring(lastUnderscore + 1);
        final isNumbered = int.tryParse(lastPart) != null;
        if (isNumbered) {
          final prefix = baseName.substring(0, lastUnderscore);
          langBase = '${prefix}_en_$lastPart';
        } else {
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
      _ttsPlayer.play().catchError((_) {});
      await _ttsPlayer.playerStateStream
          .firstWhere((s) => s.processingState == ProcessingState.completed)
          .timeout(const Duration(seconds: 10), onTimeout: () => _ttsPlayer.playerState);
      if (_isDisposed) return;
    } catch (e) {
      debugPrint('TTS 재생 에러: $e');
    } finally {
      _isTtsPlaying = false;
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
      case ThreatLevel.warningFar:
        if (_horrorLevel >= 3) Vibration.vibrate(duration: 100);
      case ThreatLevel.warningClose:
        Vibration.vibrate(duration: 200, amplitude: 150);
      case ThreatLevel.dangerFar:
        Vibration.vibrate(duration: 300, amplitude: 200);
      case ThreatLevel.dangerClose:
        Vibration.vibrate(duration: 400, amplitude: 255);
      case ThreatLevel.critical:
        Vibration.vibrate(
          pattern: [0, 500, 100, 500, 100, 500],
          intensities: [0, 255, 0, 255, 0, 255],
        );
      case ThreatLevel.aheadClose:
      case ThreatLevel.aheadMid:
      case ThreatLevel.aheadFar:
        break;
    }
  }

  double get vignetteIntensity {
    switch (_currentLevel) {
      case ThreatLevel.safe:
        return 0.0;
      case ThreatLevel.warningFar:
        return _horrorLevel >= 2 ? 0.3 : 0.0;
      case ThreatLevel.warningClose:
        return _horrorLevel >= 2 ? 0.5 : 0.2;
      case ThreatLevel.dangerFar:
        return _horrorLevel >= 3 ? 0.7 : 0.4;
      case ThreatLevel.dangerClose:
        return _horrorLevel >= 3 ? 0.9 : 0.6;
      case ThreatLevel.critical:
        return 1.0;
      case ThreatLevel.aheadClose:
      case ThreatLevel.aheadMid:
      case ThreatLevel.aheadFar:
        return 0.0;
    }
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _bgmPlayer.dispose();
    _sfxPlayer.dispose();
    _ttsPlayer.dispose();
  }
}
