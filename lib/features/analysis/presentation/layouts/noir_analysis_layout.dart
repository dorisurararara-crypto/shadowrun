import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/features/analysis/presentation/widgets/analysis_dashboard.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

/// T2 — Film Noir 분석 탭.
/// - "← FILE" 뒤로가기 + CASE 스탬프
/// - Cormorant italic "Case Analytics" 헤드 + Oswald caps 라벨
/// - 크림 페이퍼 톤 + 브래스 골드 + 와인 블러드
/// - 공통 AnalysisDashboard 에 Noir 팔레트 주입
class NoirAnalysisLayout extends StatelessWidget {
  final VoidCallback onClose;
  final bool locked;
  final Widget? proOverlay;
  const NoirAnalysisLayout({
    super.key,
    required this.onClose,
    this.locked = false,
    this.proOverlay,
  });

  // ─── Film Noir 팔레트 ─────────────────────────────────────
  static const _ink = Color(0xFF0D0907);
  static const _ink2 = Color(0xFF160E08);
  static const _paper = Color(0xFFE8DCC4);
  static const _paperDim = Color(0xFFA89A80);
  static const _paperFade = Color(0xFF6A5D48);
  static const _brass = Color(0xFFB89660);
  static const _brassDim = Color(0xFF8A6F48);
  static const _wine = Color(0xFF8B2635);
  static const _line = Color(0xFF2A1D10);

  @override
  Widget build(BuildContext context) {
    const palette = AnalyticsPalette(
      card: _ink2,
      border: _brassDim,
      text: _paper,
      muted: _paperDim,
      fade: _paperFade,
      accent: _brass,
      danger: _wine,
      numFamily: 'Cormorant Garamond',
      bodyFamily: 'Cormorant Garamond',
    );

    return Scaffold(
      backgroundColor: _ink,
      bottomNavigationBar: const BannerAdTile(),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 22),
                        const AnalysisDashboard(palette: palette),
                        const SizedBox(height: 24),
                        _buildFooterStamp(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (locked && proOverlay != null) proOverlay!,
        ],
      ),
    );
  }

  // ─── Top bar ───────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 22, 6),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    '← ',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: _paper.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    S.isKo ? '파일' : 'FILE',
                    style: GoogleFonts.oswald(
                      fontSize: 10,
                      color: _paperFade,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Transform.rotate(
            angle: 0.04,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: _wine, width: 1),
              ),
              child: Text(
                S.isKo ? '분석 · 기밀' : 'DOSSIER',
                style: GoogleFonts.oswald(
                  fontSize: 9,
                  color: _wine,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header (CASE ANALYTICS) ───────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // eyebrow caps
        Text(
          S.isKo ? '사건 분석 · CASE ANALYTICS' : 'CASE · ANALYTICS',
          style: GoogleFonts.oswald(
            fontSize: 10,
            color: _brass,
            letterSpacing: 4.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        // Cormorant italic mega head
        Text(
          S.isKo ? 'The Ledger.' : 'The Ledger.',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 48,
            fontStyle: FontStyle.italic,
            color: _paper,
            fontWeight: FontWeight.w700,
            height: 0.95,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 8),
        // subline
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _line, width: 1)),
          ),
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                S.isKo
                    ? '어느 밤, 어느 거리, 어느 숫자.'
                    : 'every night, every mile, every number.',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: _paperDim,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                _todayEn(),
                style: GoogleFonts.oswald(
                  fontSize: 9,
                  color: _paperFade,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Footer stamp ──────────────────────────────────────
  Widget _buildFooterStamp() {
    return Column(
      children: [
        Container(height: 0.6, color: _line),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 24, height: 1, color: _brassDim),
            const SizedBox(width: 10),
            Text(
              S.isKo ? '사건 종결' : 'CASE CLOSED',
              style: GoogleFonts.oswald(
                fontSize: 9,
                color: _paperFade,
                letterSpacing: 4,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 10),
            Container(width: 24, height: 1, color: _brassDim),
          ],
        ),
      ],
    );
  }

  // ─── helpers ──────────────────────────────────────────
  static String _todayEn() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]} · ${months[now.month - 1]} ${now.day}';
  }
}
