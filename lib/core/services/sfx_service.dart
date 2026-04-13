import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class SfxService {
  static final SfxService _instance = SfxService._();
  factory SfxService() => _instance;
  SfxService._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;

  Future<void> play(String filename) async {
    if (!enabled) return;
    try {
      await _player.setAsset('assets/audio/sfx/$filename');
      _player.setVolume(0.7);
      _player.play(); // fire-and-forget, don't await
    } catch (e) {
      debugPrint('SFX error: $e');
    }
  }

  // === App Entry ===
  Future<void> splash() => play('sfx_splash.mp3');
  Future<void> heartbeatSingle() => play('sfx_heartbeat_single.mp3');

  // === Home Screen ===
  Future<void> tapNewRun() => play('sfx_tap_newrun.mp3');
  Future<void> tapChallenge() => play('sfx_tap_challenge.mp3');
  Future<void> tapCard() => play('sfx_tap_card.mp3');

  // === Prepare Screen ===
  Future<void> gpsReady() => play('sfx_gps_ready.mp3');
  Future<void> toggle() => play('sfx_toggle.mp3');
  Future<void> countdown() => play('sfx_countdown.mp3');
  Future<void> go() => play('sfx_go.mp3');

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
  Future<void> victory() => play('sfx_victory.mp3');
  Future<void> defeat() => play('sfx_defeat.mp3');

  // === Result Screen ===
  Future<void> reportOpen() => play('sfx_report_open.mp3');
  Future<void> counter() => play('sfx_counter.mp3');
  Future<void> share() => play('sfx_share.mp3');

  // === Settings ===
  Future<void> switchOn() => play('sfx_switch_on.mp3');
  Future<void> switchOff() => play('sfx_switch_off.mp3');
  Future<void> levelup() => play('sfx_levelup.mp3');

  void dispose() {
    _player.dispose();
  }
}
