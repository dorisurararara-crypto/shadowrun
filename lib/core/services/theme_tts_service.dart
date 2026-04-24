import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/services/tts_coordinator.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';

/// 테마 고정 내레이터 TTS 재생 서비스.
///
/// v30: filmNoir/editorial/neoNoirCyber 3테마 각각 10종 상황 대사를
/// 테마 voice (Cedric/Clarice/River) 로 미리 생성해 assets/audio/tts/ 에 번들.
/// 테마 외(default/pure/mystic) 에서는 모든 호출이 no-op.
///
/// 이벤트명 리스트:
/// - `start_run` (러닝 시작)
/// - `start_doppel` (도플갱어 모드 시작)
/// - `checkpoint_1km` (1km 첫 통과)
/// - `near_shadow` (도플갱어 근접 경고 mid/close)
/// - `critical` (치명적 근접)
/// - `regained` (격차 다시 벌어짐)
/// - `victory` (도망 성공 결과)
/// - `defeat` (포획 결과)
/// - `encourage_early` (초반 격려)
/// - `encourage_late` (후반 격려)
class ThemeTtsService {
  static final ThemeTtsService I = ThemeTtsService._();
  ThemeTtsService._();

  final AudioPlayer _player = AudioPlayer();
  bool enabled = true;
  bool _disposed = false;

  /// 중복 재생 억제 (같은 이벤트가 짧은 시간에 두 번 트리거되는 경우 방지)
  final Map<String, DateTime> _lastPlayed = {};
  static const _cooldown = Duration(seconds: 3);

  String? _themePrefix() {
    switch (ThemeManager.I.currentId) {
      case ThemeId.filmNoir:
        return 't2';
      case ThemeId.editorial:
        return 't4';
      case ThemeId.neoNoirCyber:
        return 't5';
      case ThemeId.pureCinematic:
      case ThemeId.koreanMystic:
        return null;
    }
  }

  /// 테마 전용 이벤트 TTS 1회 재생. 현재 테마가 지원하지 않으면 no-op.
  Future<void> playEvent(String eventName) async {
    if (!enabled || _disposed) {
      debugPrint('[ThemeTts] skip event=$eventName enabled=$enabled disposed=$_disposed');
      return;
    }
    final prefix = _themePrefix();
    if (prefix == null) {
      debugPrint('[ThemeTts] skip event=$eventName — theme without TTS pool');
      return;
    }
    final now = DateTime.now();
    final last = _lastPlayed[eventName];
    if (last != null && now.difference(last) < _cooldown) {
      debugPrint('[ThemeTts] cooldown skip event=$eventName');
      return;
    }
    _lastPlayed[eventName] = now;
    final path = 'assets/audio/tts/${prefix}_tts_$eventName.mp3';
    debugPrint('[ThemeTts] play event=$eventName path=$path');
    try {
      TtsCoordinator.I.begin(() => _player.stop());
      await _player.setAsset(path);
      _player.setVolume(1.0);
      _player.play().catchError((_) {});
    } catch (e) {
      debugPrint('[ThemeTts] ERROR event=$eventName path=$path err=$e');
    }
  }

  /// 새 러닝 세션 진입 시 쿨다운 초기화.
  void resetSession() => _lastPlayed.clear();

  void dispose() {
    _disposed = true;
    _player.dispose();
  }
}
