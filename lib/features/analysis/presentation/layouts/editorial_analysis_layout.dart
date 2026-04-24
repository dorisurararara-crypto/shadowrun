import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/features/analysis/presentation/widgets/analysis_dashboard.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

/// T4 — Editorial Thriller 분석 탭.
/// - 매거진 mast head + P.XX 페이지 번호
/// - Playfair italic 매가 헤드, Inter caps 라벨
/// - 레드 섹션 태그 "◆ FEATURE REPORT"
/// - 공통 AnalysisDashboard 에 Editorial 팔레트 주입
class EditorialAnalysisLayout extends StatelessWidget {
  final VoidCallback onClose;
  final bool locked;
  final Widget? proOverlay;
  const EditorialAnalysisLayout({
    super.key,
    required this.onClose,
    this.locked = false,
    this.proOverlay,
  });

  // ─── Editorial 팔레트 ──────────────────────────────────
  static const _ink = Color(0xFF0A0A0A);
  static const _white = Color(0xFFFFFFFF);
  static const _red = Color(0xFFDC2626);
  static const _redSoft = Color(0xFFF87171);
  static const _muted = Color(0xFF888888);
  static const _hair = Color(0x1FFFFFFF); // white 12%

  @override
  Widget build(BuildContext context) {
    const palette = AnalyticsPalette(
      card: Color(0xFF0F0F0F),
      border: _hair,
      text: _white,
      muted: _muted,
      fade: Color(0xFF555555),
      accent: _red,
      danger: _red,
      numFamily: 'Playfair Display',
      bodyFamily: 'Inter',
    );

    return Scaffold(
      backgroundColor: _ink,
      bottomNavigationBar: const BannerAdTile(),
      body: Stack(
        children: [
          const Positioned.fill(child: _Grain()),
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
                        const SizedBox(height: 20),
                        const AnalysisDashboard(palette: palette),
                        const SizedBox(height: 24),
                        _buildFooterRule(),
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

  // ─── Top bar (mast) ────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    S.isKo ? '← 커버로' : '← COVER',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _muted,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'REPORT · P.04',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF7A7A7F),
                  letterSpacing: 3.5,
                ),
              ),
              const Spacer(),
              Text(
                _monthName().toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: _redSoft,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: _hair),
        ],
      ),
    );
  }

  // ─── Header (FEATURE REPORT) ───────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 10),
        // ◆ FEATURE REPORT
        Row(
          children: [
            const Text('◆', style: TextStyle(color: _red, fontSize: 9)),
            const SizedBox(width: 6),
            Text(
              S.isKo ? '특집 리포트 · FEATURE REPORT' : 'FEATURE · REPORT',
              style: GoogleFonts.inter(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: _red,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: _hair)),
          ],
        ),
        const SizedBox(height: 12),
        // No.
        Text(
          'No. ${_pad3(DateTime.now().month)}',
          style: GoogleFonts.playfairDisplay(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: _red,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '${_monthName().toUpperCase()} ISSUE · ${_todayDot()}',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w200,
            color: _muted,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(height: 2, color: _white),
        const SizedBox(height: 10),
        // Huge italic headline
        RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: _white,
              height: 0.92,
              letterSpacing: -2,
            ),
            children: const [
              TextSpan(text: 'The\nReport'),
              TextSpan(text: '.', style: TextStyle(color: _red)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _white, width: 2)),
          ),
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            S.isKo
                ? '— 숫자 뒤의 이야기 —'
                : '— THE STORY BEHIND THE NUMBERS —',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF9A9A9F),
              letterSpacing: 3,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Footer rule ───────────────────────────────────────
  Widget _buildFooterRule() {
    return Column(
      children: [
        Container(height: 2, color: _white),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SHADOWRUN/REPORT',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF7A7A7F),
                letterSpacing: 3.5,
              ),
            ),
            Text(
              S.isKo ? '— 끝 —' : '— FIN —',
              style: GoogleFonts.playfairDisplay(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: _redSoft,
              ),
            ),
            Text(
              'P.04',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF7A7A7F),
                letterSpacing: 3.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── helpers ──────────────────────────────────────────
  static String _pad3(int n) => n.toString().padLeft(3, '0');

  static String _monthName() {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[DateTime.now().month - 1];
  }

  static String _todayDot() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }
}

class _Grain extends StatelessWidget {
  const _Grain();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _GrainPainter(), size: Size.infinite),
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x03FFFFFF)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
