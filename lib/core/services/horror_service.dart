import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:vibration/vibration.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/core/services/bgm_preferences.dart';
import 'package:shadowrun/core/services/theme_tts_service.dart';
import 'package:shadowrun/core/services/tts_coordinator.dart';
import 'package:shadowrun/core/services/tts_line_bank.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';

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
  // 종료 흐름 진입 후엔 contextual/periodic TTS 차단. end TTS(승리/패배)만 force로 재생.
  // "잡혔어" 직전에 "아직 안잡혔어" 류 경고 대사가 큐에 남아 순차 재생되는 버그 방지.
  bool _silenced = false;
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

  /// 종료 흐름 진입 시 호출. 재생 중인 contextual TTS 즉시 취소 + 이후 경고 TTS 차단.
  /// playSurvivedTts/playDefeatedTts 는 force=true 로 이 플래그를 우회해 결과 대사는 정상 재생.
  Future<void> silenceRuntime() async {
    _silenced = true;
    try { await _ttsPlayer.stop(); } catch (_) {}
    _isTtsPlaying = false;
  }

  Future<void> initialize({
    int horrorLevel = 3,
    bool ttsEnabled = true,
    bool vibrationEnabled = true,
    String voice = 'harry',
    // 도플갱어 모드가 아닐 땐 false — HorrorService 의 vignette/currentLevel 은
    // 공유하지만 추격 BGM(t3_run_v*, bgm_chase_*) 은 마라톤/자유 BGM 과 겹치면 안 됨.
    bool startBgm = true,
  }) async {
    _horrorLevel = horrorLevel;
    _ttsEnabled = ttsEnabled;
    _vibrationEnabled = vibrationEnabled;
    _voiceId = voice;
    _hasVibrator = (await Vibration.hasVibrator()) == true;

    if (startBgm) {
      // 초기 BGM 시작 — _onLevelChanged 는 "변경" 트리거라 초기 safe 상태에선 호출되지 않음.
      // 도플갱어 모드에서 시작 직후 무음 구간이 생기는 걸 방지.
      final bgm = _pickBgmFile(_currentLevel);
      if (bgm != null) {
        final vol = _bgmVolume[_currentLevel] ?? 0.5;
        await _playBgm(bgm, volume: vol);
      }
    }
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

  // 신 TTS Bank 시스템 — 레벨 → 카테고리 매핑
  static const _levelToCategory = {
    ThreatLevel.aheadFar: 'ahead_far',
    ThreatLevel.aheadMid: 'ahead_mid',
    ThreatLevel.aheadClose: 'ahead_close',
    ThreatLevel.safe: 'safe',
    ThreatLevel.warningFar: 'warning_far',
    ThreatLevel.warningClose: 'warning_close',
    ThreatLevel.dangerFar: 'danger_far',
    ThreatLevel.dangerClose: 'danger_close',
    ThreatLevel.critical: 'critical',
  };

  // Pure Cinematic 테마 전용 카테고리 풀 (도플갱어 모드)
  static const _pureCats = [
    'scene_cut', 'title_drop', 'voiceover_distance', 'voiceover_pace',
    'critical_narration', 'chapter_mark', 'inner_monologue', 'ending_credits',
    'tagline_random', 'whisper',
  ];

  // Korean Mystic 테마 전용 카테고리 풀 (할머니 무당 도플갱어)
  static const _mysticCats = [
    'whisper', 'omen', 'chant', 'ancestor_warning', 'ghost_mock',
    'threshold', 'incantation', 'final_climax', 'spirit_breath', 'curse',
  ];

  // 테마 전용 TTS 혼합 확률 (20%)
  static const double _themeMixRatio = 0.20;

  // 구간별 배경음 (3개 변형 중 랜덤) — default/Pure/기타 테마용
  static const _bgmVariants = {
    ThreatLevel.aheadFar: ['bgm_peaceful.mp3', 'bgm_peaceful_v2.mp3', 'bgm_peaceful_v3.mp3'],
    ThreatLevel.aheadMid: ['bgm_calm_wind.mp3', 'bgm_calm_wind_v2.mp3', 'bgm_calm_wind_v3.mp3'],
    ThreatLevel.aheadClose: ['bgm_tension_low.mp3', 'bgm_tension_low_v2.mp3', 'bgm_tension_low_v3.mp3'],
    // v1 은 원본이 -50 LUFS 로 거의 무음 + 정규화 시 클리핑. 풀에서 제외 (v2/v3 만).
    ThreatLevel.safe: ['bgm_dark_ambient_v2.mp3', 'bgm_dark_ambient_v3.mp3'],
    ThreatLevel.warningFar: ['bgm_chase_far.mp3', 'bgm_chase_far_v2.mp3', 'bgm_chase_far_v3.mp3'],
    ThreatLevel.warningClose: ['bgm_chase_mid.mp3', 'bgm_chase_mid_v2.mp3', 'bgm_chase_mid_v3.mp3'],
    ThreatLevel.dangerFar: ['bgm_chase_close.mp3', 'bgm_chase_close_v2.mp3', 'bgm_chase_close_v3.mp3'],
    ThreatLevel.dangerClose: ['bgm_chase_critical.mp3', 'bgm_chase_critical_v2.mp3', 'bgm_chase_critical_v3.mp3'],
    ThreatLevel.critical: ['bgm_chase_critical.mp3', 'bgm_chase_critical_v2.mp3', 'bgm_chase_critical_v3.mp3'],
  };

  // Mystic 테마 전용 — t3_run_v*.mp3 (한국 전통 공포 톤, ElevenLabs Music API 생성).
  // ThreatLevel 별 개별 변형 없이 2개 트랙에서 랜덤 재생. 볼륨은 _bgmVolume 으로 레벨별 차등.
  static const _mysticDoppelgangerPool = [
    'themes/t3_run_v1.mp3',
    'themes/t3_run_v2.mp3',
  ];

  // Film Noir (T2) 전용 추격 BGM — 1940s 재즈 pursuit score.
  static const _noirDoppelgangerPool = [
    'themes/t2_chase_v1.mp3',
    'themes/t2_chase_v2.mp3',
  ];

  // Editorial Thriller (T4) 전용 추격 BGM — 모던 스릴러 score.
  static const _editorialDoppelgangerPool = [
    'themes/t4_chase_v1.mp3',
    'themes/t4_chase_v2.mp3',
  ];

  // Neo-Noir Cyber (T5) 전용 추격 BGM — darksynth pursuit.
  static const _cyberDoppelgangerPool = [
    'themes/t5_chase_v1.mp3',
    'themes/t5_chase_v2.mp3',
  ];

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
    ThreatLevel.critical: 0.9,
  };

  /// 현재 테마·레벨에 맞는 BGM 파일 1개 선택.
  /// T3 Mystic / T2 Noir / T4 Editorial / T5 Cyber 는 전용 chase 풀(ThreatLevel 무관).
  /// 그 외는 default chase 풀 (bgm_chase_*.mp3, level 별 변형).
  String? _pickBgmFile(ThreatLevel level) {
    switch (ThemeManager.I.currentId) {
      case ThemeId.koreanMystic:
        return _mysticDoppelgangerPool[_rng.nextInt(_mysticDoppelgangerPool.length)];
      case ThemeId.filmNoir:
        return _noirDoppelgangerPool[_rng.nextInt(_noirDoppelgangerPool.length)];
      case ThemeId.editorial:
        return _editorialDoppelgangerPool[_rng.nextInt(_editorialDoppelgangerPool.length)];
      case ThemeId.neoNoirCyber:
        return _cyberDoppelgangerPool[_rng.nextInt(_cyberDoppelgangerPool.length)];
      case ThemeId.pureCinematic:
        break;
    }
    final list = _bgmVariants[level];
    if (list == null || list.isEmpty) return null;
    return list[_rng.nextInt(list.length)];
  }

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
    if (_silenced) return;
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
      final played = await TtsLineBank.I.play(
        mode: 'doppelganger_public',
        category: 'losing_lead',
      );
      if (!played) {
        final variant = _losingLeadVariants[_rng.nextInt(_losingLeadVariants.length)];
        await _playTts(variant);
      }
    }
    _wasAhead = isNowAhead;

    if (newLevel != _currentLevel) {
      final prevLevel = _currentLevel;
      _currentLevel = newLevel;
      _lastPeriodicTts = DateTime.now();
      debugPrint('[Horror] threat ${prevLevel.name} → ${newLevel.name} (dist=${distanceM.toStringAsFixed(1)}m)');
      // v30: 테마 내레이터 이벤트 라인 + signature SFX. 노이즈 방지 위해 쿨다운 있는 ThemeTts 내부에서 억제.
      _dispatchThemeThreatHook(prevLevel, newLevel);
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
    if (_silenced || !_ttsEnabled || level == ThreatLevel.critical) return;
    final interval = _periodicInterval[level] ?? 40;
    final now = DateTime.now();
    if (_lastPeriodicTts != null && now.difference(_lastPeriodicTts!).inSeconds < interval) return;
    _lastPeriodicTts = now;
    await _playContextualTts(level);
  }

  /// 신 TtsLineBank 시스템 우선 재생 + 실패 시 구 시스템 fallback.
  /// 20% 확률로 현재 테마 전용 카테고리로 대체 재생.
  Future<void> _playContextualTts(ThreatLevel level) async {
    if (_silenced) return;
    final category = _levelToCategory[level];
    if (category == null) return;

    String mode = 'doppelganger_public';
    String cat = category;

    if (_rng.nextDouble() < _themeMixRatio) {
      final themeId = ThemeManager.I.currentId;
      if (themeId == ThemeId.koreanMystic) {
        mode = 'mystic_doppelganger';
        cat = _mysticCats[_rng.nextInt(_mysticCats.length)];
      } else if (themeId == ThemeId.pureCinematic) {
        mode = 'pure_doppelganger';
        cat = _pureCats[_rng.nextInt(_pureCats.length)];
      }
    }

    final played = await TtsLineBank.I.play(mode: mode, category: cat);
    if (played) return;

    // fallback — 구 시스템 (생성 완료 전까지 자동 유지)
    final variants = _ttsVariants[level];
    if (variants != null && variants.isNotEmpty) {
      await _playTts(variants[_rng.nextInt(variants.length)]);
    }
  }

  /// v30: 테마 고정 내레이터 + signature SFX 를 threat 전환 시점에 1회 트리거.
  /// Severity 순서: safe < warningFar < warningClose < dangerFar < dangerClose < critical.
  /// ahead* 는 플레이어가 앞선 상태 (선두). 플레이어가 뒤처지는 쪽으로 이동 = near/critical.
  void _dispatchThemeThreatHook(ThreatLevel prev, ThreatLevel next) {
    int sev(ThreatLevel l) {
      switch (l) {
        case ThreatLevel.aheadFar:
        case ThreatLevel.aheadMid:
        case ThreatLevel.aheadClose:
        case ThreatLevel.safe:
          return 0;
        case ThreatLevel.warningFar:
        case ThreatLevel.warningClose:
          return 1;
        case ThreatLevel.dangerFar:
        case ThreatLevel.dangerClose:
          return 2;
        case ThreatLevel.critical:
          return 3;
      }
    }
    final pv = sev(prev);
    final nv = sev(next);
    if (nv > pv) {
      // 위협 상승 — 근접/치명
      if (next == ThreatLevel.critical) {
        ThemeTtsService.I.playEvent('critical');
      } else if (nv >= 1) {
        SfxService().themeNearShadow();
        ThemeTtsService.I.playEvent('near_shadow');
      }
    } else if (nv < pv && pv >= 2) {
      // 위험에서 회복 — 격차 재확보
      ThemeTtsService.I.playEvent('regained');
    }
  }

  Future<void> _onLevelChanged(ThreatLevel level) async {
    if (_silenced) return;
    // 배경음 변경 — 테마별 분기 포함 (_pickBgmFile)
    final bgm = _pickBgmFile(level);
    if (bgm != null) {
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

    // TTS (신 Bank → 구 시스템 fallback)
    if (_ttsEnabled) {
      await _playContextualTts(level);
    }
  }

  Future<void> playStartTts() async {
    if (_ttsEnabled) {
      await _playTts('tts_start');
    }
  }

  Future<void> playSurvivedTts() async {
    if (_ttsEnabled) {
      await _playTts('tts_survived', force: true);
    }
  }

  Future<void> playDefeatedTts() async {
    if (_ttsEnabled) {
      await _playTts('tts_defeated', force: true);
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

  /// 테마별 고정 voice. 사용자가 설정에서 고른 voice 는 Pure/Mystic 에서만 사용되고,
  /// 새 3테마는 테마 캐릭터에 맞는 보이스로 강제. "목소리 설정 무관 특색 있는 TTS" 목적.
  String get _effectiveVoice {
    switch (ThemeManager.I.currentId) {
      case ThemeId.filmNoir:
        return 'drill'; // 깊은 하드보일드 남성 내레이터
      case ThemeId.editorial:
        return 'harry'; // 영국 저널리스트 톤
      case ThemeId.neoNoirCyber:
        return 'callum'; // 사이버 쿨 스코티시
      case ThemeId.pureCinematic:
      case ThemeId.koreanMystic:
        return _voiceId;
    }
  }

  Future<void> _playTts(String baseName, {bool force = false}) async {
    if (_isDisposed || _isTtsPlaying) return;
    if (_silenced && !force) return;
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

      // 음성 분기: harry는 기본 파일명, callum/drill은 접미사.
      // _effectiveVoice 가 테마별 고정 voice 를 반영 (사용자 설정 무시, 특색 강화).
      final voice = _effectiveVoice;
      String filename;
      if (voice == 'harry') {
        filename = '$langBase.mp3';
      } else {
        filename = '${langBase}_$voice.mp3';
      }

      TtsCoordinator.I.begin(() => _ttsPlayer.stop());
      await _ttsPlayer.stop();
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
