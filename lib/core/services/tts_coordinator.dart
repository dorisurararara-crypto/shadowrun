import 'dart:async';

/// 전역 TTS 재생 중재자. 어떤 서비스든 TTS 를 재생하기 직전 [begin] 을 호출하면,
/// 이전에 진행 중이던 **다른** TTS 가 즉시 중단된다. BGM/SFX 는 이 조정과 무관해서
/// TTS 와 동시 재생이 허용된다.
///
/// 사용 예:
/// ```dart
/// TtsCoordinator.I.begin(() => _player.stop());
/// await _player.setAsset(path);
/// _player.play();
/// ```
///
/// `end` 는 일부러 두지 않는다 — 다음 [begin] 이 오면 자연스럽게 이전 재생을 멈추고,
/// 재생이 정상 완료되어 이미 멈춰 있는 경우 stop 콜백은 no-op 으로 동작한다.
class TtsCoordinator {
  TtsCoordinator._();
  static final TtsCoordinator I = TtsCoordinator._();

  FutureOr<void> Function()? _activeStop;

  /// TTS 재생 직전 호출. 등록된 이전 stop 콜백을 fire-and-forget 으로 호출해
  /// 기존 TTS 를 중단시킨 뒤, 새 재생자의 stop 콜백을 active 로 등록한다.
  void begin(FutureOr<void> Function() stop) {
    final previous = _activeStop;
    if (previous != null) {
      try {
        previous();
      } catch (_) {
        // 이미 해제된 player 의 stop 예외는 무시 — 다음 재생을 막지 않는다.
      }
    }
    _activeStop = stop;
  }
}
