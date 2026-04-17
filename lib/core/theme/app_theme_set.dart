import 'package:flutter/material.dart';
import 'package:shadowrun/core/theme/theme_id.dart';

class ThemePalette {
  final Color background;
  final Color surface;
  final Color card;
  final Color cardHigh;
  final Color accent;
  final Color accentSoft;
  final Color accentBg;
  final Color onSurface;
  final Color onSurfaceDim;
  final Color onSurfaceFade;
  final Color outline;
  final Color border;
  final Color danger;

  const ThemePalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.cardHigh,
    required this.accent,
    required this.accentSoft,
    required this.accentBg,
    required this.onSurface,
    required this.onSurfaceDim,
    required this.onSurfaceFade,
    required this.outline,
    required this.border,
    required this.danger,
  });
}

class ThemeFonts {
  final String heroFamily;
  final String bodyFamily;
  final String numFamily;
  final bool heroItalic;

  const ThemeFonts({
    required this.heroFamily,
    required this.bodyFamily,
    required this.numFamily,
    this.heroItalic = false,
  });
}

class AppThemeSet {
  final ThemeId id;
  final ThemePalette palette;
  final ThemeFonts fonts;
  final String tagline;
  final bool showHanjaWatermark;
  final List<String> hanjaSet;
  // 테마별 BGM 풀 — 홈/러닝(비추격). 빈 리스트면 재생 안 함/기본 폴백.
  // chase_* 는 여기 포함하지 않음 (HorrorService가 공통 관리).
  final List<String> bgmHomePool;
  final List<String> bgmRunningPool;

  const AppThemeSet({
    required this.id,
    required this.palette,
    required this.fonts,
    required this.tagline,
    this.showHanjaWatermark = false,
    this.hanjaSet = const [],
    this.bgmHomePool = const [],
    this.bgmRunningPool = const [],
  });
}
