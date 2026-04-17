import 'package:flutter/foundation.dart';
import 'package:shadowrun/core/theme/app_theme_set.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/themes/theme_definitions.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/services/purchase_service.dart';

class ThemeManager {
  ThemeManager._() {
    // codex P2: PRO 해제/체험 만료 시 현재 테마가 더 이상 쓸 수 없게 될 수 있음.
    // proNotifier 변경을 듣고 재검증해 기본 테마로 폴백.
    PurchaseService().proNotifier.addListener(_revalidateOnProChange);
  }
  static final ThemeManager I = ThemeManager._();

  final ValueNotifier<ThemeId> themeIdNotifier = ValueNotifier(ThemeId.pureCinematic);

  void _revalidateOnProChange() {
    if (!PurchaseService().canUseTheme(themeIdNotifier.value)) {
      // 사용 권한 잃었으므로 기본 테마로 복귀하고 DB도 반영.
      themeIdNotifier.value = ThemeId.pureCinematic;
      DatabaseHelper.setSetting('theme_id', ThemeId.pureCinematic.key).catchError((e) {
        debugPrint('테마 폴백 저장 실패: $e');
      });
    }
  }

  static const Map<ThemeId, AppThemeSet> _themes = {
    ThemeId.pureCinematic: pureCinematicTheme,
    ThemeId.filmNoir: filmNoirTheme,
    ThemeId.koreanMystic: koreanMysticTheme,
    ThemeId.editorial: editorialTheme,
    ThemeId.neoNoirCyber: neoNoirCyberTheme,
  };

  static AppThemeSet getTheme(ThemeId id) => _themes[id] ?? pureCinematicTheme;
  static List<AppThemeSet> all() => ThemeId.values.map((id) => _themes[id]!).toList();

  ThemeId get currentId => themeIdNotifier.value;
  AppThemeSet get current => getTheme(currentId);

  Future<void> loadSaved() async {
    try {
      final saved = await DatabaseHelper.getSetting('theme_id');
      final candidate = ThemeId.fromKey(saved);
      // codex P2: 저장된 테마가 더 이상 사용 가능하지 않으면(예: 체험 만료 후
      // 유료 테마 보유 X) 기본 테마로 폴백하고 DB에 반영.
      if (PurchaseService().canUseTheme(candidate)) {
        themeIdNotifier.value = candidate;
      } else {
        themeIdNotifier.value = ThemeId.pureCinematic;
        await DatabaseHelper.setSetting('theme_id', ThemeId.pureCinematic.key);
      }
    } catch (e) {
      debugPrint('테마 로드 실패: $e');
    }
  }

  Future<void> setTheme(ThemeId id) async {
    // codex P2: 사용 권한 없으면 거부 (UI에서 피커가 이미 lock 표시하지만 방어적 체크).
    if (!PurchaseService().canUseTheme(id)) {
      debugPrint('테마 설정 거부: ${id.key} — 구매/PRO 필요');
      return;
    }
    themeIdNotifier.value = id;
    try {
      await DatabaseHelper.setSetting('theme_id', id.key);
    } catch (e) {
      debugPrint('테마 저장 실패: $e');
    }
  }
}
