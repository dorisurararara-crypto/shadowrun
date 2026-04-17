import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/features/analysis/presentation/widgets/analysis_dashboard.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';

/// T1 Pure Cinematic 분석 탭.
/// - 상단 "← home" + eyebrow
/// - Playfair Italic 대제목
/// - 공통 AnalysisDashboard에 Pure 팔레트 주입
class PureAnalysisLayout extends StatelessWidget {
  final VoidCallback onClose;
  final bool locked;
  final Widget? proOverlay;
  const PureAnalysisLayout({
    super.key,
    required this.onClose,
    this.locked = false,
    this.proOverlay,
  });

  static const _bgPage = Color(0xFF050507);
  static const _ink = Color(0xFFF5F5F5);
  static const _inkDim = Color(0xFF9A9A9A);
  static const _inkFade = Color(0xFF5A5A5E);
  static const _redSub = Color(0xFFC83030);

  @override
  Widget build(BuildContext context) {
    const palette = AnalyticsPalette(
      card: Color(0xFF0E0E0E),
      border: Color(0xFF1A1A1A),
      text: _ink,
      muted: _inkDim,
      fade: _inkFade,
      accent: _redSub,
      danger: _redSub,
      numFamily: 'Playfair Display',
      bodyFamily: 'Noto Serif KR',
    );

    return Scaffold(
      backgroundColor: _bgPage,
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
                        const SizedBox(height: 20),
                        const AnalysisDashboard(palette: palette),
                        const SizedBox(height: 24),
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

  Widget _buildTopBar() {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 22, 0),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: SizedBox(
                height: 44,
                child: Row(
                  children: [
                    Text(
                      '← ',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: _ink.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      S.isKo ? '홈' : 'home',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: _inkFade,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Center(
          child: Text(
            S.isKo ? '— 통계 —' : '— analysis —',
            style: GoogleFonts.playfairDisplay(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _redSub,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'Performance',
            style: GoogleFonts.playfairDisplay(
              fontSize: 46,
              fontStyle: FontStyle.italic,
              color: _ink,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -1.2,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            S.isKo ? '당신의 그림자, 숫자로' : 'your shadow, in numbers',
            style: GoogleFonts.playfairDisplay(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _inkDim,
              letterSpacing: 3,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ],
    );
  }
}
