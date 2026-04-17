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

  const AppThemeSet({
    required this.id,
    required this.palette,
    required this.fonts,
    required this.tagline,
    this.showHanjaWatermark = false,
    this.hanjaSet = const [],
  });
}
