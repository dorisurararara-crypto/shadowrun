import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';
import 'package:shadowrun/features/result/presentation/widgets/result_detail_section.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// 순정 시네마(T1) 테마의 러닝 결과 화면.
///
/// 순검정 / 오프화이트 / 블러드 레드(#8B0000) · Noto Serif KR + Playfair Italic.
/// - 상단 × 닫기 + 공유 icon
/// - "Episode NNN · End Credits" 태그 (Playfair Italic red)
/// - 대형 "ESCAPED" / "CAUGHT" / "RECORDED" (Playfair Italic 900, red glow)
/// - 한글 보조 "탈 출" / "잡 힘" / "기 록"
/// - 영화적 서브 카피
/// - 통계 3칸: Distance / Elapsed / Final gap
/// - 추격 거리 라인차트 (CustomPainter)
/// - "— the fine print —" 상세 리스트
/// - 하단 2버튼: Home / Again (이중 보더)
class PureResultLayout extends StatelessWidget {
  /// 도전 모드 승(탈출)/패(잡힘)/기록(자유). null이면 자유 러닝.
  final bool? isWin;
  final double distanceM;
  final int durationS;
  final String avgPaceText;

  /// 도플갱어와의 최종 거리(m). 양수=탈출, 음수=잡힘, null=자유.
  final double? shadowGapM;

  /// 도플갱어와의 거리 시계열(m). 비어있으면 더미 곡선을 그림.
  final List<double> shadowDistanceSeries;

  final String maxPaceText;
  final int? avgHeartRate;
  final int calories;

  /// Episode 넘버 표시용 (없으면 "—").
  final int? episodeNumber;

  final VoidCallback? onClose;
  final VoidCallback? onShare;
  final VoidCallback? onRestart;

  /// DB에서 splits/페이스 분포를 조회할 runId. null이면 상세 섹션 생략.
  final int? runId;

  /// 배너 광고 위젯 (free 유저에 한해 result_screen 이 주입). null = 비노출.
  final Widget? bannerAd;

  const PureResultLayout({
    super.key,
    required this.isWin,
    required this.distanceM,
    required this.durationS,
    required this.avgPaceText,
    required this.shadowGapM,
    this.shadowDistanceSeries = const [],
    required this.maxPaceText,
    required this.avgHeartRate,
    required this.calories,
    this.episodeNumber,
    this.onClose,
    this.onShare,
    this.onRestart,
    this.runId,
    this.bannerAd,
  });

  // Pure Cinematic 팔레트 (full-t1-pure.html 참고)
  static const _bg = Color(0xFF000000);
  static const _bgPage = Color(0xFF050507);
  static const _ink = Color(0xFFF5F5F5);
  static const _inkDim = Color(0xFF9A9A9A);
  static const _inkFade = Color(0xFF5A5A5E);
  static const _inkGhost = Color(0xFF3A3A3E);
  static const _red = Color(0xFF8B0000);
  static const _redSub = Color(0xFFC83030);
  static const _redEmber = Color(0xFF5A0000);
  static const _hair = Color(0x14F5F5F5); // rgba(245,245,245,0.08)

  String get _verdictText {
    if (isWin == null) return 'RECORDED';
    return isWin! ? 'ESCAPED' : 'CAUGHT';
  }

  String get _verdictKo {
    if (isWin == null) return '기 록';
    return isWin! ? '탈 출' : '잡 힘';
  }

  String get _narration {
    if (isWin == null) {
      return '오늘의 걸음이 기록되었다.\n당신의 페이스는 여전히 당신의 것이다.';
    }
    if (isWin!) {
      return '그는 당신을 잡지 못했다.\n오늘 밤, 어둠 속에서 당신이 이겼다.';
    }
    return '어둠이 더 빨랐다.\n오늘 밤, 그가 당신을 스쳤다.';
  }

  String get _narrationTail {
    if (isWin == null) return '당신의 페이스는 여전히 당신의 것이다.';
    if (isWin!) return '어둠 속에서 당신이 이겼다.';
    return '그가 당신을 스쳤다.';
  }

  String get _formattedDistance {
    if (RunModel.useMiles) {
      final miles = distanceM / 1609.344;
      if (miles >= 0.1) return miles.toStringAsFixed(2);
      return (distanceM * 1.09361).toInt().toString();
    }
    if (distanceM >= 1000) return (distanceM / 1000).toStringAsFixed(2);
    return distanceM.toInt().toString();
  }

  String get _distanceUnit {
    if (RunModel.useMiles) {
      final miles = distanceM / 1609.344;
      return miles >= 0.1 ? 'mi' : 'yd';
    }
    return distanceM >= 1000 ? 'km' : 'm';
  }

  String get _formattedDuration {
    final h = durationS ~/ 3600;
    final m = (durationS % 3600) ~/ 60;
    final s = durationS % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _formattedGap {
    if (shadowGapM == null) return '—';
    final g = shadowGapM!.round();
    if (g > 0) return '+$g';
    return '$g'; // 음수는 자체 '-' 포함
  }

  String get _episodeTag {
    final ep = episodeNumber;
    final epStr = ep == null ? '—' : ep.toString().padLeft(3, '0');
    if (S.isKo) {
      return '에피소드 $epStr · 엔드 크레딧';
    }
    return 'Episode $epStr · End Credits';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      body: Container(
        color: _bg,
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      _buildEpisodeTag(),
                      const SizedBox(height: 18),
                      _buildVerdict(),
                      const SizedBox(height: 26),
                      _buildStatsRow(),
                      // 자유러닝(도플갱어 없음)은 그림자 차트 숨김.
                      if (isWin != null) ...[
                        const SizedBox(height: 24),
                        _buildChartSection(),
                      ],
                      const SizedBox(height: 26),
                      _buildDetails(),
                      if (runId != null)
                        ResultDetailSection(
                          runId: runId!,
                          palette: const AnalyticsPalette(
                            card: Color(0xFF0E0E0E),
                            border: Color(0xFF1A1A1A),
                            text: _ink,
                            muted: _inkDim,
                            fade: _inkFade,
                            accent: _redSub,
                            danger: _redSub,
                            numFamily: 'Playfair Display',
                            bodyFamily: 'Noto Serif KR',
                          ),
                        ),
                      const SizedBox(height: 28),
                      if (bannerAd != null) ...[
                        bannerAd!,
                        const SizedBox(height: 16),
                      ],
                      _buildActions(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              SfxService().tapCard();
              onClose?.call();
            },
            child: SizedBox(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '×',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontStyle: FontStyle.italic,
                      color: _inkDim,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.isKo ? '닫기' : 'CLOSE',
                    style: S.isKo
                        ? GoogleFonts.notoSerifKr(
                            fontSize: 10,
                            color: _inkFade,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w400,
                          )
                        : GoogleFonts.notoSerif(
                            fontSize: 10,
                            color: _inkFade,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w300,
                          ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              SfxService().tapCard();
              onShare?.call();
            },
            child: SizedBox(
              height: 40,
              width: 36,
              child: Center(
                child: Text(
                  '↗',
                  style: GoogleFonts.notoSerif(
                    fontSize: 16,
                    color: _inkDim,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEpisodeTag() {
    return Center(
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.playfairDisplay(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: _redSub,
            letterSpacing: 4.5,
            fontWeight: FontWeight.w400,
          ),
          children: [
            const TextSpan(
              text: '—   ',
              style: TextStyle(color: _redEmber),
            ),
            TextSpan(text: _episodeTag.toUpperCase()),
            const TextSpan(
              text: '   —',
              style: TextStyle(color: _redEmber),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdict() {
    return Column(
      children: [
        // ESCAPED / CAUGHT / RECORDED — Playfair Italic 900 대형 + red glow
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _verdictText,
            maxLines: 1,
            softWrap: false,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 56,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w900,
              color: _ink,
              letterSpacing: 2,
              height: 1,
              shadows: const [
                Shadow(color: Color(0x59C83030), blurRadius: 40),
                Shadow(color: Color(0x338B0000), blurRadius: 80),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        // 한글 보조 (작게, 이탤릭 세리프)
        Text(
          _verdictKo,
          style: GoogleFonts.notoSerifKr(
            fontSize: 13,
            color: _redSub,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 18),
        // 영화적 서브카피
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _narration,
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerifKr(
              fontSize: 13,
              color: _inkDim,
              fontWeight: FontWeight.w300,
              height: 1.75,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _hair, width: 1),
          bottom: BorderSide(color: _hair, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statCell(
              label: S.isKo ? '거리' : 'DISTANCE',
              value: _formattedDistance,
              unit: _distanceUnit,
            ),
          ),
          Container(width: 1, height: 36, color: _hair),
          Expanded(
            child: _statCell(
              label: S.isKo ? '시간' : 'ELAPSED',
              value: _formattedDuration,
              unit: '',
            ),
          ),
          Container(width: 1, height: 36, color: _hair),
          Expanded(
            child: _statCell(
              label: S.isKo ? '최종 간격' : 'FINAL GAP',
              value: _formattedGap,
              unit: shadowGapM == null ? '' : 'm',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell({
    required String label,
    required String value,
    required String unit,
  }) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  color: _ink,
                  height: 1,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: GoogleFonts.notoSerif(
                    fontSize: 11,
                    color: _inkFade,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.playfairDisplay(
            fontSize: 9,
            fontStyle: FontStyle.italic,
            color: _inkFade,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              S.isKo ? '그림자와의 거리' : 'DISTANCE FROM THE SHADOW',
              style: S.isKo
                  ? GoogleFonts.notoSerifKr(
                      fontSize: 11,
                      color: _redSub,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
                    )
                  : GoogleFonts.playfairDisplay(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: _redSub,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w400,
                    ),
            ),
            const Spacer(),
            Text(
              '00:00 → $_formattedDuration',
              style: GoogleFonts.playfairDisplay(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: _inkFade,
                letterSpacing: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _hair, width: 1),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x0A8B0000), Color(0x00000000)],
              stops: [0.0, 0.6],
            ),
          ),
          child: AspectRatio(
            aspectRatio: 300 / 120,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ShadowChartPainter(
                      series: shadowDistanceSeries,
                      isCaught: isWin == false,
                    ),
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 8,
                  child: Text(
                    S.isKo ? '+최대' : '+max',
                    style: S.isKo
                        ? GoogleFonts.notoSerifKr(
                            fontSize: 9,
                            color: _inkFade,
                            fontWeight: FontWeight.w400,
                          )
                        : GoogleFonts.playfairDisplay(
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                            color: _inkFade,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 8,
                  child: Text(
                    S.isKo ? '안전' : 'safe',
                    style: S.isKo
                        ? GoogleFonts.notoSerifKr(
                            fontSize: 9,
                            color: _redSub,
                            fontWeight: FontWeight.w500,
                          )
                        : GoogleFonts.playfairDisplay(
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                            color: _redSub,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  left: 8,
                  child: Text(
                    '0m',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 9,
                      fontStyle: FontStyle.italic,
                      color: _inkFade,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 5,
                  right: 8,
                  child: Text(
                    S.isKo
                        ? (isWin == false ? '잡힘' : '위험')
                        : (isWin == false ? 'caught' : 'danger'),
                    style: S.isKo
                        ? GoogleFonts.notoSerifKr(
                            fontSize: 9,
                            color: _inkFade,
                            fontWeight: FontWeight.w400,
                          )
                        : GoogleFonts.playfairDisplay(
                            fontSize: 9,
                            fontStyle: FontStyle.italic,
                            color: _inkFade,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _narrationTail,
            style: GoogleFonts.playfairDisplay(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _inkFade,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    final rows = <_DetailRow>[
      _DetailRow('평균 페이스', avgPaceText, ' /km'),
      _DetailRow('최고 페이스', maxPaceText, ' /km'),
      _DetailRow(
        '심박 · 평균',
        avgHeartRate == null ? '—' : '$avgHeartRate',
        avgHeartRate == null ? '' : ' bpm',
      ),
      _DetailRow('소모 칼로리', '$calories', ' kcal'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _hair, width: 1)),
          ),
          child: Text(
            S.isKo ? '세부 기록' : 'THE FINE PRINT',
            style: S.isKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 11,
                    color: _redSub,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: _redSub,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                  ),
          ),
        ),
        for (int i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: i == rows.length - 1 ? Colors.transparent : _hair,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 12.5,
                      color: _inkDim,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: rows[i].value,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: _ink,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      if (rows[i].unit.isNotEmpty)
                        TextSpan(
                          text: rows[i].unit,
                          style: GoogleFonts.notoSerif(
                            fontSize: 10,
                            color: _inkFade,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              SfxService().tapCard();
              onClose?.call();
            },
            child: SizedBox(
              height: 54,
              child: _DoubleBorder(
                borderColor: _inkGhost,
                innerColor: Colors.transparent,
                child: Center(
                  child: Text(
                    S.isKo ? '홈' : 'HOME',
                    style: S.isKo
                        ? GoogleFonts.notoSerifKr(
                            fontSize: 13,
                            color: _ink,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w500,
                          )
                        : GoogleFonts.playfairDisplay(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: _ink,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              SfxService().tapChallenge();
              onRestart?.call();
            },
            child: SizedBox(
              height: 54,
              child: _DoubleBorder(
                borderColor: _red,
                innerColor: const Color(0xFF0A0000),
                child: Center(
                  child: Text(
                    S.isKo ? '다시' : 'AGAIN',
                    style: S.isKo
                        ? GoogleFonts.notoSerifKr(
                            fontSize: 13,
                            color: _redSub,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w700,
                          )
                        : GoogleFonts.playfairDisplay(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: _redSub,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w700,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow {
  final String label;
  final String value;
  final String unit;
  const _DetailRow(this.label, this.value, this.unit);
}

/// 이중 보더 (외곽선 1 + 간격 2 + 내곽선 1) — 영화 크레딧 느낌의 버튼 프레임.
class _DoubleBorder extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final Color innerColor;

  const _DoubleBorder({
    required this.child,
    required this.borderColor,
    required this.innerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          color: innerColor,
          border: Border.all(color: borderColor, width: 1),
        ),
        child: child,
      ),
    );
  }
}

/// Pure Cinematic 차트 페인터.
/// 시간축 x, 거리 y. 하단 <50m 구간은 붉은 위험 그라디언트.
/// 라인 색은 시작 붉음 → 중앙 오프화이트 그라디언트 (정면 위협 → 탈출감).
class _ShadowChartPainter extends CustomPainter {
  final List<double> series;
  final bool isCaught;

  _ShadowChartPainter({required this.series, required this.isCaught});

  static const _red = Color(0xFF8B0000);
  static const _redSub = Color(0xFFC83030);
  static const _ink = Color(0xFFF5F5F5);
  static const _grid = Color(0xFF1A1A1E);
  static const _gridMid = Color(0xFF2A2A2E);

  List<double> _dataFor() {
    if (series.length >= 2) return series;
    if (isCaught) {
      // 점점 따라잡힘: +양수 → 0 수렴 → 음수(추월)
      return const [180, 160, 140, 120, 95, 70, 48, 28, 10, -8, -22];
    }
    // 중반 위험 → 후반 탈출 가속
    return const [160, 140, 120, 90, 55, 30, 60, 110, 180, 260, 312];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final data = _dataFor();
    // 0을 중앙, 양수는 위, 음수는 아래로 매핑 (safe ↔ caught)
    double maxAbs = 1;
    for (final v in data) {
      if (v.abs() > maxAbs) maxAbs = v.abs();
    }
    maxAbs *= 1.1; // 상하 여백

    double xAt(int i) =>
        data.length <= 1 ? 0 : (i / (data.length - 1)) * w;
    double yAt(double v) {
      // v == +maxAbs → y=0, v == -maxAbs → y=h, v==0 → y=h/2
      final norm = (v / maxAbs).clamp(-1.0, 1.0);
      return h / 2 - norm * (h / 2) * 0.9;
    }

    // 기준선 (0m)
    final zeroY = yAt(0);
    final gridMidPaint = Paint()
      ..color = _gridMid
      ..strokeWidth = 0.5;
    _drawDashedLine(canvas, Offset(0, zeroY), Offset(w, zeroY), gridMidPaint,
        dashWidth: 2, gapWidth: 3);

    // 1/3, 2/3 그리드
    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 0.5;
    _drawDashedLine(
      canvas,
      Offset(0, h / 3),
      Offset(w, h / 3),
      gridPaint,
      dashWidth: 2,
      gapWidth: 4,
    );
    _drawDashedLine(
      canvas,
      Offset(0, h * 2 / 3),
      Offset(w, h * 2 / 3),
      gridPaint,
      dashWidth: 2,
      gapWidth: 4,
    );

    // 위험 구간 (하단: y > zeroY): 붉은 그라디언트
    final dangerRect = Rect.fromLTRB(0, zeroY, w, h);
    if (dangerRect.height > 0) {
      final dangerPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x338B0000), Color(0x008B0000)],
        ).createShader(dangerRect);
      canvas.drawRect(dangerRect, dangerPaint);
    }

    // 라인 path
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = xAt(i);
      final y = yAt(data[i]);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    // 하단 채우기(라인 아래 → 바닥)
    final fillPath = Path.from(linePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          _red.withValues(alpha: 0.35),
          _red.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // 라인 — 시작 red → 끝 offwhite 그라디언트
    final linePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [_redSub, _ink, _ink],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 최저점(가장 위험) 마커
    int minIdx = 0;
    for (int i = 1; i < data.length; i++) {
      if (data[i] < data[minIdx]) minIdx = i;
    }
    final minX = xAt(minIdx);
    final minY = yAt(data[minIdx]);
    canvas.drawCircle(Offset(minX, minY), 2.5, Paint()..color = _redSub);

    // 끝점 링 강조
    final endX = xAt(data.length - 1);
    final endY = yAt(data.last);
    final endColor = isCaught ? _redSub : _ink;
    canvas.drawCircle(Offset(endX, endY), 3, Paint()..color = endColor);
    canvas.drawCircle(
      Offset(endX, endY),
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = endColor.withValues(alpha: 0.3),
    );

  }

  void _drawDashedLine(
    Canvas canvas,
    Offset from,
    Offset to,
    Paint paint, {
    double dashWidth = 2,
    double gapWidth = 3,
  }) {
    final totalDx = to.dx - from.dx;
    final totalDy = to.dy - from.dy;
    final total = totalDx.abs() + totalDy.abs();
    if (total == 0) return;
    final dx = totalDx / total;
    final dy = totalDy / total;
    double traveled = 0;
    while (traveled < total) {
      final startX = from.dx + dx * traveled;
      final startY = from.dy + dy * traveled;
      final endT = (traveled + dashWidth).clamp(0.0, total);
      final endX = from.dx + dx * endT;
      final endY = from.dy + dy * endT;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
      traveled += dashWidth + gapWidth;
    }
  }

  @override
  bool shouldRepaint(covariant _ShadowChartPainter old) =>
      old.series != series || old.isCaught != isCaught;
}
