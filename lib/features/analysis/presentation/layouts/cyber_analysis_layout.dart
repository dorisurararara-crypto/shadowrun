import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/features/analysis/presentation/widgets/analysis_dashboard.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

/// T5 — Neo-Noir Cyber 분석 탭.
/// - "// BACK" 뒤로가기 + PULSE 태그
/// - JetBrains Mono code-like 라벨 + Playfair italic 헤드 (크로매틱 aberration)
/// - 스캔라인 배경 + 시안 액센트 + 레드 글로우
/// - 공통 AnalysisDashboard 에 Cyber 팔레트 주입
class CyberAnalysisLayout extends StatelessWidget {
  final VoidCallback onClose;
  final bool locked;
  final Widget? proOverlay;
  const CyberAnalysisLayout({
    super.key,
    required this.onClose,
    this.locked = false,
    this.proOverlay,
  });

  // ─── Cyber 팔레트 ──────────────────────────────────────
  static const _bg = Color(0xFF04040A);
  static const _red = Color(0xFFFF1744);
  static const _cyan = Color(0xFF4DD0E1);
  static const _text = Color(0xFFE8E8F0);
  static const _textDim = Color(0xFF9898A8);
  static const _textFade = Color(0xFF5A5A68);
  static const _textMute = Color(0xFF3A3A48);
  static const _borderCyan = Color(0x264DD0E1); // 15%

  @override
  Widget build(BuildContext context) {
    const palette = AnalyticsPalette(
      card: Color(0xFF0A0A12),
      border: _borderCyan,
      text: _text,
      muted: _textDim,
      fade: _textFade,
      accent: _cyan,
      danger: _red,
      numFamily: 'Space Grotesk',
      bodyFamily: 'JetBrains Mono',
    );

    return Scaffold(
      backgroundColor: _bg,
      bottomNavigationBar: const BannerAdTile(),
      body: Stack(
        children: [
          // 배경 글로우
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -1.1),
                  radius: 1.1,
                  colors: [
                    _red.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.0, 1.0),
                  radius: 1.0,
                  colors: [
                    _cyan.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _ScanLines()),
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
                        const SizedBox(height: 20),
                        const AnalysisDashboard(palette: palette),
                        const SizedBox(height: 24),
                        _buildFooter(),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 22, 4),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                S.isKo ? '// BACK' : '// BACK',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: _cyan,
                  letterSpacing: 2.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const Spacer(),
          _pulseTag('DIAGNOSTICS · ACTIVE'),
        ],
      ),
    );
  }

  Widget _pulseTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: _red, width: 1),
        color: const Color(0x0AFF1744),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _red.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: _red,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header (SYSTEM DIAGNOSTICS) ───────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          S.isKo ? '// 시스템 진단 · SYSTEM DIAGNOSTICS' : '// SYSTEM DIAGNOSTICS',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: _cyan,
            letterSpacing: 3,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        // Chromatic aberration mega head
        _chromaticHead(),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: _cyan,
              letterSpacing: 2.5,
            ),
            children: [
              const TextSpan(text: 'QUERY'),
              const TextSpan(
                text: '  /  ',
                style: TextStyle(color: _textMute),
              ),
              TextSpan(text: _todayDot()),
              const TextSpan(
                text: '  /  ',
                style: TextStyle(color: _textMute),
              ),
              TextSpan(
                text: 'STREAM',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: _red,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          S.isKo
              ? '37.5658°N · 127.0450°E · TELEMETRY OPEN'
              : '37.5658°N · 127.0450°E · TELEMETRY OPEN',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: _textFade,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(height: 1, color: _borderCyan),
      ],
    );
  }

  // ─── Chromatic-aberration head ────────────────────────
  Widget _chromaticHead() {
    const size = 42.0;
    final style = GoogleFonts.playfairDisplay(
      fontSize: size,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w900,
      height: 0.95,
      letterSpacing: -1.6,
    );
    Widget layer(Color color, Offset offset, {double alpha = 1}) {
      return Transform.translate(
        offset: offset,
        child: Opacity(
          opacity: alpha,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Diagnostics', style: style.copyWith(color: color)),
                TextSpan(text: '.', style: style.copyWith(color: color)),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: size * 1.2,
      child: Stack(
        children: [
          layer(_cyan, const Offset(2, 0), alpha: 0.5),
          layer(_red, const Offset(-2, 0), alpha: 0.5),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Diagnostics',
                  style: style.copyWith(color: _text),
                ),
                TextSpan(text: '.', style: style.copyWith(color: _red)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Footer ────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      children: [
        Container(height: 1, color: _borderCyan),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '// EOF',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: _textFade,
                letterSpacing: 2.5,
              ),
            ),
            Text(
              'STREAM CLOSED @ ${_timeNow()}',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: _cyan,
                letterSpacing: 2.2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── helpers ──────────────────────────────────────────
  static String _todayDot() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
  }

  static String _timeNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _ScanLines extends StatelessWidget {
  const _ScanLines();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _ScanLinePainter(), size: Size.infinite),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A4DD0E1) // cyan 4%
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
