import 'package:flutter/material.dart';
import 'package:shadowrun/core/theme/app_theme_set.dart';
import 'package:shadowrun/core/theme/theme_id.dart';

const pureCinematicTheme = AppThemeSet(
  id: ThemeId.pureCinematic,
  palette: ThemePalette(
    background: Color(0xFF000000),
    surface: Color(0xFF0A0A0A),
    card: Color(0xFF0E0E0E),
    cardHigh: Color(0xFF161616),
    accent: Color(0xFF8B0000),
    accentSoft: Color(0xFFC83030),
    accentBg: Color(0x1A8B0000),
    onSurface: Color(0xFFF5F5F5),
    onSurfaceDim: Color(0xFF888888),
    onSurfaceFade: Color(0xFF555555),
    outline: Color(0xFFAF8787),
    border: Color(0xFF1A1A1A),
    danger: Color(0xFFFF5262),
  ),
  fonts: ThemeFonts(
    heroFamily: 'Playfair Display',
    bodyFamily: 'Noto Serif KR',
    numFamily: 'Playfair Display',
    heroItalic: true,
  ),
  tagline: '그림자는 쉬지 않는다',
  // ElevenLabs Music API로 생성한 테마 전용 BGM (2026-04-18)
  // 프롬프트: cinematic noir minimal piano + dark strings ambient
  bgmHomePool: [
    'themes/t1_home_v1.mp3',
    'themes/t1_home_v2.mp3',
  ],
  bgmRunningPool: [
    'themes/t1_run_v1.mp3',
    'themes/t1_run_v2.mp3',
  ],
);

const koreanMysticTheme = AppThemeSet(
  id: ThemeId.koreanMystic,
  palette: ThemePalette(
    background: Color(0xFF050302),
    surface: Color(0xFF0A0604),
    card: Color(0xFF0D0607),
    cardHigh: Color(0xFF14090A),
    accent: Color(0xFFC42029),
    accentSoft: Color(0xFFE8555C),
    accentBg: Color(0x1F7A0A0E),
    onSurface: Color(0xFFF0EBE3),
    onSurfaceDim: Color(0xFF9A8A7A),
    onSurfaceFade: Color(0xFF5A4840),
    outline: Color(0xFF7A6858),
    border: Color(0xFF2A1518),
    danger: Color(0xFFC42029),
  ),
  fonts: ThemeFonts(
    heroFamily: 'Nanum Myeongjo',
    bodyFamily: 'Gowun Batang',
    numFamily: 'Nanum Myeongjo',
    heroItalic: false,
  ),
  tagline: '그 놈이 오늘 밤도 쫓아온다',
  showHanjaWatermark: true,
  hanjaSet: ['影', '追', '夜', '始', '終', '走', '設'],
  // ElevenLabs Music API 생성 — Korean traditional horror ambient
  // gayageum drone + cold wind + daegeum flute + pounding heartbeat
  bgmHomePool: [
    'themes/t3_home_v1.mp3',
    'themes/t3_home_v2.mp3',
  ],
  bgmRunningPool: [
    'themes/t3_run_v1.mp3',
    'themes/t3_run_v2.mp3',
  ],
);

const filmNoirTheme = AppThemeSet(
  id: ThemeId.filmNoir,
  palette: ThemePalette(
    background: Color(0xFF0D0907),
    surface: Color(0xFF110C08),
    card: Color(0xFF150E0A),
    cardHigh: Color(0xFF1F1510),
    accent: Color(0xFFB89660),
    accentSoft: Color(0xFFE0BF82),
    accentBg: Color(0x14B89660),
    onSurface: Color(0xFFE8DCC4),
    onSurfaceDim: Color(0xFF8A7D5F),
    onSurfaceFade: Color(0xFF5A4D35),
    outline: Color(0xFF3A2718),
    border: Color(0xFF2A1D10),
    danger: Color(0xFF8B2635),
  ),
  fonts: ThemeFonts(
    heroFamily: 'Cormorant Garamond',
    bodyFamily: 'Cormorant Garamond',
    numFamily: 'Cormorant Garamond',
    heroItalic: true,
  ),
  tagline: 'A Nightly Chase',
);

const editorialTheme = AppThemeSet(
  id: ThemeId.editorial,
  palette: ThemePalette(
    background: Color(0xFF0A0A0A),
    surface: Color(0xFF111111),
    card: Color(0xFF0E0E0E),
    cardHigh: Color(0xFF1A1A1A),
    accent: Color(0xFFDC2626),
    accentSoft: Color(0xFFF87171),
    accentBg: Color(0x14DC2626),
    onSurface: Color(0xFFFFFFFF),
    onSurfaceDim: Color(0xFF888888),
    onSurfaceFade: Color(0xFF555555),
    outline: Color(0xFF444444),
    border: Color(0xFF222222),
    danger: Color(0xFFDC2626),
  ),
  fonts: ThemeFonts(
    heroFamily: 'Playfair Display',
    bodyFamily: 'Inter',
    numFamily: 'Playfair Display',
    heroItalic: true,
  ),
  tagline: 'The Chase Never Sleeps',
);

const neoNoirCyberTheme = AppThemeSet(
  id: ThemeId.neoNoirCyber,
  palette: ThemePalette(
    background: Color(0xFF04040A),
    surface: Color(0xFF080812),
    card: Color(0xFF0A0A18),
    cardHigh: Color(0xFF12122A),
    accent: Color(0xFFFF1744),
    accentSoft: Color(0xFFFF5A75),
    accentBg: Color(0x14FF1744),
    onSurface: Color(0xFFE8E8F0),
    onSurfaceDim: Color(0xFF666677),
    onSurfaceFade: Color(0xFF3A3A4A),
    outline: Color(0xFF4DD0E1),
    border: Color(0x264DD0E1),
    danger: Color(0xFFFF1744),
  ),
  fonts: ThemeFonts(
    heroFamily: 'Playfair Display',
    bodyFamily: 'Inter',
    numFamily: 'JetBrains Mono',
    heroItalic: true,
  ),
  tagline: 'ENTITY TRACKING ACTIVE',
);
