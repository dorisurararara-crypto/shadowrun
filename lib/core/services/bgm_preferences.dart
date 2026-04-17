import 'package:flutter/foundation.dart';
import 'package:shadowrun/core/database/database_helper.dart';

/// BGM 사용자 설정을 중앙에서 관리.
/// Horror/Marathon 등 BGM을 재생하는 모든 서비스는 이 값을 참조해
/// 실제 재생 볼륨 = [volume] × 서비스별 기본 배수 로 계산.
///
/// 이 싱글톤은 설정 UI에서 바뀌면 listeners를 알려주고,
/// 서비스는 [AudioPlayer.setVolume]을 실시간 반영한다.
class BgmPreferences {
  BgmPreferences._();
  static final BgmPreferences I = BgmPreferences._();

  /// BGM 재생 여부 (false면 아예 재생 안 함 — 외부 음악 우선 시나리오에 유용)
  final ValueNotifier<bool> enabled = ValueNotifier(true);

  /// 사용자 볼륨 (0.0 ~ 1.0). 서비스 기본 볼륨에 곱해짐.
  final ValueNotifier<double> volume = ValueNotifier(0.6);

  /// 외부 음악(Spotify/YouTube Music) 허용 모드.
  /// true면 내장 BGM 자동 off + AudioSession을 mix로 설정.
  final ValueNotifier<bool> externalMusicMode = ValueNotifier(false);

  Future<void> loadSaved() async {
    try {
      final en = await DatabaseHelper.getSetting('bgm_enabled');
      enabled.value = en != 'false';

      final vol = await DatabaseHelper.getSetting('bgm_volume');
      final parsed = double.tryParse(vol ?? '');
      if (parsed != null && parsed >= 0 && parsed <= 1) {
        volume.value = parsed;
      }

      final ext = await DatabaseHelper.getSetting('bgm_external_music');
      externalMusicMode.value = ext == 'true';
    } catch (e) {
      debugPrint('BgmPreferences 로드 실패: $e');
    }
  }

  Future<void> setEnabled(bool v) async {
    enabled.value = v;
    try {
      await DatabaseHelper.setSetting('bgm_enabled', v ? 'true' : 'false');
    } catch (e) {
      debugPrint('bgm_enabled 저장 실패: $e');
    }
  }

  Future<void> setVolume(double v) async {
    final clamped = v.clamp(0.0, 1.0);
    volume.value = clamped;
    try {
      await DatabaseHelper.setSetting('bgm_volume', clamped.toStringAsFixed(2));
    } catch (e) {
      debugPrint('bgm_volume 저장 실패: $e');
    }
  }

  Future<void> setExternalMusicMode(bool v) async {
    externalMusicMode.value = v;
    try {
      await DatabaseHelper.setSetting('bgm_external_music', v ? 'true' : 'false');
    } catch (e) {
      debugPrint('bgm_external_music 저장 실패: $e');
    }
    // 외부 음악 모드를 켜면 내장 BGM은 자동 off.
    if (v) await setEnabled(false);
  }

  /// 서비스에서 사용할 최종 볼륨. enabled==false이거나 externalMusicMode==true면 0.
  /// [baseVolume]은 서비스가 기본으로 원하는 볼륨 (예: Horror peaceful 0.3).
  double effectiveVolume(double baseVolume) {
    if (!enabled.value) return 0.0;
    if (externalMusicMode.value) return 0.0;
    return (baseVolume * volume.value).clamp(0.0, 1.0);
  }
}
