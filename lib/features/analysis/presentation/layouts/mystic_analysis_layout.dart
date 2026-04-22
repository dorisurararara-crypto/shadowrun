import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/features/analysis/presentation/widgets/analysis_dashboard.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

/// T3 Korean Mystic 분석 탭.
/// - 상단 "← 홈" + "曜" 한자 헤더
/// - 배경 한자 워터마크 "分"
/// - 공통 AnalysisDashboard에 Mystic 팔레트 주입
class MysticAnalysisLayout extends StatelessWidget {
  final VoidCallback onClose;
  final bool locked;
  final Widget? proOverlay;
  const MysticAnalysisLayout({
    super.key,
    required this.onClose,
    this.locked = false,
    this.proOverlay,
  });

  static const _ink = Color(0xFF050302);
  static const _rice = Color(0xFFF0EBE3);
  static const _bloodDry = Color(0xFF7A0A0E);
  static const _bloodFresh = Color(0xFFC42029);
  static const _outline = Color(0xFF7A6858);
  static const _fade = Color(0xFF5A4840);
  static const _borderInk = Color(0xFF2A1518);

  @override
  Widget build(BuildContext context) {
    const palette = AnalyticsPalette(
      card: Color(0xFF0D0607),
      border: _borderInk,
      text: _rice,
      muted: _outline,
      fade: _fade,
      accent: _bloodFresh,
      danger: _bloodFresh,
      numFamily: 'Nanum Myeongjo',
      bodyFamily: 'Gowun Batang',
    );

    return Scaffold(
      backgroundColor: _ink,
      bottomNavigationBar: const BannerAdTile(),
      body: Stack(
        children: [
          const Positioned(
            right: -60,
            top: 60,
            child: IgnorePointer(
              child: Text(
                '分',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 320,
                  color: Color(0x26B00A12),
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const Positioned(
            left: -40,
            bottom: 180,
            child: IgnorePointer(
              child: Text(
                '析',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 260,
                  color: Color(0x1C7A0A0E),
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 18),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 22, 6),
      child: Row(
        children: [
          InkWell(
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                S.isKo ? '← 홈' : '← home',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 13,
                  color: _rice.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '曜',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 18,
              color: _bloodDry,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '分 析',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 11,
            color: _outline,
            letterSpacing: 6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          S.isKo ? '달린 흔적' : 'your traces',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 30,
            color: _rice,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 60, height: 1, color: _bloodDry),
      ],
    );
  }
}
