import 'package:flutter/foundation.dart';
import 'package:shadowrun/core/theme/app_theme_set.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/themes/theme_definitions.dart';
import 'package:shadowrun/core/database/database_helper.dart';

class ThemeManager {
  ThemeManager._();
  static final ThemeManager I = ThemeManager._();

  final ValueNotifier<ThemeId> themeIdNotifier = ValueNotifier(ThemeId.pureCinematic);

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
      themeIdNotifier.value = ThemeId.fromKey(saved);
    } catch (e) {
      debugPrint('테마 로드 실패: $e');
    }
  }

  Future<void> setTheme(ThemeId id) async {
    themeIdNotifier.value = id;
    try {
      await DatabaseHelper.setSetting('theme_id', id.key);
    } catch (e) {
      debugPrint('테마 저장 실패: $e');
    }
  }
}
