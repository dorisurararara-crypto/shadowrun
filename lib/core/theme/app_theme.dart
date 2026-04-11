import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SRColors {
  // Backgrounds
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF131313);
  static const surfaceContainerLow = Color(0xFF161616);
  static const surfaceContainer = Color(0xFF201F1F);
  static const surfaceContainerHigh = Color(0xFF2A2A2A);
  static const surfaceContainerHighest = Color(0xFF353534);
  static const surfaceBright = Color(0xFF3A3939);

  // Primary (The Pulse)
  static const primary = Color(0xFFFFB3B4);
  static const primaryContainer = Color(0xFFFF5262);
  static const onPrimary = Color(0xFF680016);
  static const onPrimaryContainer = Color(0xFF5B0012);

  // Secondary (The Shadow)
  static const secondary = Color(0xFFFFB3B4);
  static const secondaryContainer = Color(0xFF920223);

  // Tertiary (The Ghost / Safe)
  static const tertiary = Color(0xFF6BD9C7);
  static const tertiaryContainer = Color(0xFF2AA192);

  // Text
  static const onSurface = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFFE9BCBB);
  static const onBackground = Color(0xFFE5E2E1);
  static const outline = Color(0xFFAF8787);
  static const outlineVariant = Color(0xFF5E3E3F);

  // Functional
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF93000A);

  // Semantic aliases
  static const runner = Color(0xFF00FF88);
  static const shadow = Color(0xFFFF5262);
  static const safe = Color(0xFF6BD9C7);
  static const warning = Color(0xFFFFA500);
  static const danger = Color(0xFFFF5262);
  static const critical = Color(0xFFFF0000);

  // PRO badge
  static const proBadge = Color(0xFFD4AF37);

  // Legacy aliases (used by screens)
  static const card = surfaceContainerLow;        // #161616
  static const cardLight = surfaceContainer;       // #201F1F
  static const textPrimary = onSurface;            // #E5E2E1
  static const textSecondary = onSurfaceVariant;   // #E9BCBB
  static Color get textMuted => onSurface.withValues(alpha: 0.4);
  static const divider = Color(0x0DFFFFFF);        // white/5
  static const neutral500 = Color(0xFF737373);
}

class SRTheme {
  static TextStyle _spaceGrotesk({
    double size = 14,
    FontWeight weight = FontWeight.w700,
    Color color = SRColors.onSurface,
    double letterSpacing = -0.5,
  }) => GoogleFonts.spaceGrotesk(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  static TextStyle _inter({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = SRColors.onSurface,
    double letterSpacing = 0,
  }) => GoogleFonts.inter(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
  );

  // Headline styles (Space Grotesk)
  static TextStyle get displayLarge => _spaceGrotesk(size: 48, weight: FontWeight.w900, letterSpacing: -2);
  static TextStyle get headlineLarge => _spaceGrotesk(size: 32, weight: FontWeight.w900, letterSpacing: -1);
  static TextStyle get headlineMedium => _spaceGrotesk(size: 24, weight: FontWeight.w800, letterSpacing: -0.5);
  static TextStyle get titleLarge => _spaceGrotesk(size: 20, weight: FontWeight.w700, letterSpacing: -0.5);
  static TextStyle get titleMedium => _spaceGrotesk(size: 18, weight: FontWeight.w700, letterSpacing: -0.3);

  // Body styles (Inter)
  static TextStyle get bodyLarge => _inter(size: 16);
  static TextStyle get bodyMedium => _inter(size: 14, color: SRColors.onSurfaceVariant);
  static TextStyle get bodySmall => _inter(size: 12, color: SRColors.outline);

  // Label styles (Inter, uppercase tracking)
  static TextStyle get labelLarge => _inter(size: 12, weight: FontWeight.w700, letterSpacing: 2);
  static TextStyle get labelMedium => _inter(size: 10, weight: FontWeight.w700, letterSpacing: 1.5);
  static TextStyle get labelSmall => _inter(size: 10, weight: FontWeight.w700, color: SRColors.primaryContainer, letterSpacing: 1);

  // Stat number style
  static TextStyle get statNumber => _spaceGrotesk(size: 24, weight: FontWeight.w700);

  static ThemeData get dark => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: SRColors.background,
    colorScheme: const ColorScheme.dark(
      primary: SRColors.primaryContainer,
      secondary: SRColors.secondary,
      surface: SRColors.surface,
      error: SRColors.error,
      onPrimary: Colors.white,
      onSurface: SRColors.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: SRColors.surface,
      foregroundColor: SRColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: _spaceGrotesk(
        size: 20,
        weight: FontWeight.w900,
        color: SRColors.primary,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: const CardThemeData(
      color: SRColors.surfaceContainerLow,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: SRColors.outlineVariant,
      thickness: 0.5,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: SRColors.primaryContainer,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _inter(size: 12, weight: FontWeight.w900, letterSpacing: 3),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SRColors.primary,
        shape: const StadiumBorder(),
        side: const BorderSide(color: SRColors.primaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: _inter(size: 12, weight: FontWeight.w900, letterSpacing: 3),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: SRColors.surface,
      selectedItemColor: SRColors.primary,
      unselectedItemColor: SRColors.surfaceContainerHighest,
    ),
  );
}
