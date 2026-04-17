import 'package:flutter/material.dart';
import 'package:shadowrun/core/services/bgm_preferences.dart';

/// 홈 상단에 배치하는 BGM on/off 미니 토글.
/// 테마별로 색상만 다르게 주입해 재사용.
class BgmToggleButton extends StatelessWidget {
  final Color color;
  final double size;
  const BgmToggleButton({super.key, required this.color, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final prefs = BgmPreferences.I;
    return AnimatedBuilder(
      animation: Listenable.merge([prefs.enabled, prefs.externalMusicMode]),
      builder: (context, _) {
        final muted = !prefs.enabled.value || prefs.externalMusicMode.value;
        return IconButton(
          splashRadius: 22,
          tooltip: muted ? 'BGM 켜기' : 'BGM 끄기',
          icon: Icon(
            muted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
            color: color,
            size: size,
          ),
          onPressed: () async {
            if (prefs.externalMusicMode.value) {
              // 외부 음악 모드면 우선 해제하고 BGM 활성화
              await prefs.setExternalMusicMode(false);
            }
            await prefs.setEnabled(!prefs.enabled.value);
          },
        );
      },
    );
  }
}
