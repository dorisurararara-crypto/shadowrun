import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';

class SfxService {
  static final SfxService _instance = SfxService._();
  factory SfxService() => _instance;
  SfxService._();

  // AudioPlayer 풀 (동시 재생 지원, 겹침 방지)
  final List<AudioPlayer> _pool = List.generate(3, (_) => AudioPlayer());
  int _poolIndex = 0;
  bool enabled = true;
  bool _disposed = false;

  Future<void> play(String filename) async {
    if (!enabled) return;
    if (_disposed) return;
    try {
      final player = _pool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _pool.length;
      await player.setAsset('assets/audio/sfx/$filename');
      player.setVolume(0.7);
      player.play().catchError((_) {});
    } catch (e) {
      debugPrint('SFX error: $e');
    }
  }

  // === App Entry ===
  static final _splashRng = Random();
  Future<void> splash() => play(
      _splashRng.nextBool() ? 'sfx_splash_v1.mp3' : 'sfx_splash_v2.mp3');
  Future<void> heartbeatSingle() => play('sfx_heartbeat_single.mp3');

  // === Home Screen ===
  Future<void> tapNewRun() => play('sfx_tap_newrun.mp3');
  Future<void> tapChallenge() => play('sfx_tap_challenge.mp3');
  Future<void> tapCard() => play('sfx_tap_card.mp3');

  // === Prepare Screen ===
  Future<void> gpsReady() => play('sfx_gps_ready.mp3');
  Future<void> toggle() => play('sfx_toggle.mp3');
  Future<void> countdown() {
    final file = ThemeManager.I.currentId == ThemeId.pureCinematic
        ? 'sfx_countdown_pure.mp3'
        : 'sfx_countdown.mp3';
    return play(file);
  }
  Future<void> go() {
    final file = ThemeManager.I.currentId == ThemeId.koreanMystic
        ? 'sfx_go_mystic.mp3'
        : 'sfx_go.mp3';
    return play(file);
  }

  // === Doppelganger Running ===
  Future<void> alertLow() => play('sfx_alert_low.mp3');
  Future<void> alertHigh() => play('sfx_alert_high.mp3');
  Future<void> chainBreak() => play('sfx_chain_break.mp3');
  Future<void> whoosh() => play('sfx_whoosh.mp3');
  Future<void> fanfare() => play('sfx_fanfare.mp3');
  Future<void> glassBreak() => play('sfx_glass_break.mp3');
  Future<void> kmDing() => play('sfx_km_ding.mp3');

  // === Marathon Running ===
  Future<void> whistle() => play('sfx_whistle.mp3');
  Future<void> powerup() => play('sfx_powerup.mp3');
  Future<void> tension() => play('sfx_tension.mp3');

  // === Common Running ===
  Future<void> pause() => play('sfx_pause.mp3');
  Future<void> resume() => play('sfx_resume.mp3');
  Future<void> vehicleWarn() => play('sfx_vehicle_warn.mp3');

  // === Run End ===
  Future<void> doorClose() => play('sfx_door_close.mp3');
  Future<void> victory() {
    final themeFile = _themeFile('victory');
    return play(themeFile ?? 'sfx_victory.mp3');
  }
  Future<void> defeat() {
    final themeFile = _themeFile('defeat');
    return play(themeFile ?? 'sfx_defeat.mp3');
  }

  /// 테마별 러닝 시작 signature. noir/editorial/cyber 는 전용 SFX,
  /// Pure/Mystic 은 기존 whistle 로 fallback (whistle 이 범용).
  Future<void> themeStart() async {
    final themeFile = _themeFile('start');
    if (themeFile != null) {
      return play(themeFile);
    }
    return whistle();
  }

  /// 새 3테마 전용 signature SFX 파일 매핑. 그 외는 null (기본 SFX 사용).
  String? _themeFile(String kind) {
    switch (ThemeManager.I.currentId) {
      case ThemeId.filmNoir:
        return 'sfx_noir_$kind.mp3';
      case ThemeId.editorial:
        return 'sfx_editorial_$kind.mp3';
      case ThemeId.neoNoirCyber:
        return 'sfx_cyber_$kind.mp3';
      case ThemeId.pureCinematic:
      case ThemeId.koreanMystic:
        return null;
    }
  }

  // === Result Screen ===
  Future<void> reportOpen() => play('sfx_report_open.mp3');
  Future<void> counter() => play('sfx_counter.mp3');
  Future<void> share() => play('sfx_share.mp3');

  // === Settings ===
  Future<void> switchOn() => play('sfx_switch_on.mp3');
  Future<void> switchOff() => play('sfx_switch_off.mp3');
  Future<void> levelup() => play('sfx_levelup.mp3');

  void dispose() {
    _disposed = true;
    for (final p in _pool) {
      p.dispose();
    }
  }
}
