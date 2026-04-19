import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';
import 'package:shadowrun/features/result/presentation/widgets/result_detail_section.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// 한국 민속 호러(T3) 테마의 러닝 결과 화면.
///
/// 흑·쌀·피의 이중 계조, 나눔명조/고운바탕 고딕 혼용.
/// - 상단 "終" 한자 헤더 + × 닫기 + 공유
/// - 대형 판정 문구 "살 아 남 았 다" / "잡 혔 다"
/// - 영화적 서브 카피, 이중 괘선 장식
/// - 통계 3칸: 거리·시간·여유(도플갱어와의 최종 gap)
/// - 도플갱어 거리 라인차트 (CustomPainter)
/// - "지 난 기 록" 상세 리스트 (평균/최고 페이스, 심박, 칼로리)
/// - 배경 "終" 한자 워터마크
/// - 하단 버튼 2개: 다시 뛰어라 / 집으로
class MysticResultLayout extends StatelessWidget {
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

  final VoidCallback? onClose;
  final VoidCallback? onShare;
  final VoidCallback? onRestart;

  /// DB에서 splits/페이스 분포를 읽을 runId. null이면 상세 섹션 생략.
  final int? runId;

  const MysticResultLayout({
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
    this.onClose,
    this.onShare,
    this.onRestart,
    this.runId,
  });

  static const _ink = Color(0xFF050302);
  static const _rice = Color(0xFFF0EBE3);
  static const _bloodDry = Color(0xFF7A0A0E);
  static const _bloodFresh = Color(0xFFC42029);
  static const _outline = Color(0xFF7A6858);
  static const _fade = Color(0xFF5A4840);
  static const _borderInk = Color(0xFF2A1518);

  String _hanjaDigits(int n) {
    const d = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    if (n < 0) return '$n';
    if (n < 10) return d[n];
    if (n < 20) return '十${n > 10 ? d[n - 10] : ''}';
    if (n < 30) return '廿${n > 20 ? d[n - 20] : ''}';
    if (n < 40) return '卅${n > 30 ? d[n - 30] : ''}';
    if (n < 100) return '${d[n ~/ 10]}十${n % 10 > 0 ? d[n % 10] : ''}';
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  String get _verdictText {
    if (isWin == null) return '기  록  됐  다';
    return isWin! ? '살  아  남  았  다' : '잡  혔  다';
  }

  Color get _verdictColor {
    if (isWin == null) return _rice;
    return isWin! ? _rice : _bloodFresh;
  }

  String get _subCopy {
    if (isWin == null) {
      return '오늘의 걸음이\n밤의 장부에 남았다.';
    }
    if (isWin!) {
      return '오늘 밤은 그 그림자가\n당신을 놓쳤다.\n내일 밤은 아무도 모른다.';
    }
    return '오늘 밤, 그 놈에게\n숨결을 빼앗겼다.\n내일은, 다시 뛰어라.';
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

  Color get _gapColor {
    if (shadowGapM == null) return _rice;
    return shadowGapM! >= 0 ? _rice : _bloodFresh;
  }

  String _hanjaDate() {
    final now = DateTime.now();
    return '${_hanjaDigits(now.month)} 月  ${_hanjaDigits(now.day)} 日';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          // 배경 한자 워터마크
          const Positioned(
            right: -60,
            top: 80,
            child: IgnorePointer(
              child: Text(
                '終',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 340,
                  color: Color(0x22B00A12),
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 18),
                        _buildVerdict(),
                        const SizedBox(height: 22),
                        _buildDoubleRule(),
                        const SizedBox(height: 18),
                        _buildStatsRow(),
                        _buildDoubleRule(),
                        // 자유러닝(도플갱어 없음)은 그림자 차트 숨김.
                        if (isWin != null) ...[
                          const SizedBox(height: 22),
                          _buildChartSection(),
                        ],
                        const SizedBox(height: 26),
                        Center(
                          child: Text(
                            '─   지 난 기 록   ─',
                            style: GoogleFonts.nanumMyeongjo(
                              fontSize: 11,
                              color: _outline,
                              letterSpacing: 3,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildDetailList(),
                        if (runId != null)
                          ResultDetailSection(
                            runId: runId!,
                            palette: const AnalyticsPalette(
                              card: Color(0xFF0D0607),
                              border: _borderInk,
                              text: _rice,
                              muted: _outline,
                              fade: _fade,
                              accent: _bloodFresh,
                              danger: _bloodFresh,
                              numFamily: 'Nanum Myeongjo',
                              bodyFamily: 'Gowun Batang',
                            ),
                          ),
                        const SizedBox(height: 28),
                        _buildActions(context),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Row(
        children: [
          InkWell(
            onTap: () {
              SfxService().tapCard();
              onClose?.call();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '×',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 22,
                  color: _rice,
                  height: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                '終',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 20,
                  color: _bloodDry,
                  letterSpacing: 6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              SfxService().tapCard();
              onShare?.call();
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(
                '공 유',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 12,
                  color: _outline,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerdict() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '판  결',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 11,
            color: _fade,
            letterSpacing: 5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          _verdictText,
          textAlign: TextAlign.center,
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 40,
            color: _verdictColor,
            height: 1.1,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 16),
        // 붓터치 느낌의 붉은 가로선
        Container(
          height: 2,
          width: 120,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0x00C42029),
                _bloodFresh,
                Color(0x00C42029),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          _subCopy,
          textAlign: TextAlign.center,
          style: GoogleFonts.gowunBatang(
            fontSize: 13,
            color: _rice.withValues(alpha: 0.85),
            height: 1.8,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          '─   ${_hanjaDate()}  ·  밤 의 기 록   ─',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 10,
            color: _fade,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildDoubleRule() {
    return Column(
      children: [
        Container(height: 1, color: _borderInk),
        const SizedBox(height: 3),
        Container(height: 1, color: _borderInk),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _statCell(
              label: '거 리',
              value: _formattedDistance,
              unit: _distanceUnit,
              color: _rice,
            ),
          ),
          Container(width: 1, height: 44, color: _borderInk),
          Expanded(
            child: _statCell(
              label: '시 간',
              value: _formattedDuration,
              unit: '',
              color: _rice,
            ),
          ),
          Container(width: 1, height: 44, color: _borderInk),
          Expanded(
            child: _statCell(
              label: '여 유',
              value: _formattedGap,
              unit: shadowGapM == null ? '' : 'm',
              color: _gapColor,
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
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 10,
            color: _fade,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 22,
                  color: color,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 10,
                    color: _outline,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
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
          children: [
            Text(
              '그 림 자 와 의   거 리',
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 11,
                color: _outline,
                letterSpacing: 3,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              '── 米 / 분',
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 10,
                color: _fade,
                letterSpacing: 1,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AspectRatio(
          aspectRatio: 300 / 120,
          child: CustomPaint(
            painter: _ShadowDistancePainter(
              series: shadowDistanceSeries,
              lineColor: _bloodFresh,
              dangerColor: _bloodDry,
              gridColor: const Color(0xFF241618),
              endPointColor: _rice,
              isCaught: isWin == false,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0:00',
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 9,
                color: _fade,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              _halfTime(),
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 9,
                color: _fade,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              _formattedDuration,
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 9,
                color: _fade,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _halfTime() {
    final half = durationS ~/ 2;
    final m = (half % 3600) ~/ 60;
    final s = half % 60;
    final h = half ~/ 3600;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailList() {
    final rows = <_DetailRow>[
      _DetailRow('평 균 페 이 스', avgPaceText),
      _DetailRow('최 고 페 이 스', maxPaceText),
      _DetailRow(
        '심 박 · 평 균',
        avgHeartRate == null ? '— bpm' : '$avgHeartRate bpm',
      ),
      _DetailRow('칼 로 리', '$calories kcal'),
    ];

    return Column(
      children: [
        for (int i = 0; i < rows.length; i++)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: i == rows.length - 1 ? Colors.transparent : _borderInk,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    rows[i].label,
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 12,
                      color: _outline,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Text(
                  rows[i].value,
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 13,
                    color: _rice.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              SfxService().tapCard();
              onClose?.call();
            },
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF0D0607),
                border: Border.fromBorderSide(
                  BorderSide(color: _borderInk, width: 1),
                ),
              ),
              child: Text(
                '집  으  로',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 13,
                  color: _rice,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            onTap: () {
              SfxService().tapChallenge();
              onRestart?.call();
            },
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF3B0006), Color(0xFF0D0607)],
                ),
                border: Border.all(color: _bloodDry, width: 1),
              ),
              child: Text(
                '다  시   뛰  어  라',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 13,
                  color: _bloodFresh,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
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
  const _DetailRow(this.label, this.value);
}

/// 도플갱어와의 거리(m) 시계열을 그린다.
/// 실제 시리즈가 비어있거나 너무 짧으면 극적인 더미 곡선을 그림.
class _ShadowDistancePainter extends CustomPainter {
  final List<double> series;
  final Color lineColor;
  final Color dangerColor;
  final Color gridColor;
  final Color endPointColor;
  final bool isCaught;

  _ShadowDistancePainter({
    required this.series,
    required this.lineColor,
    required this.dangerColor,
    required this.gridColor,
    required this.endPointColor,
    required this.isCaught,
  });

  List<double> _normalized() {
    if (series.length >= 2) return series;
    // 더미: 긴장감 곡선 (중반에 위험, 말미에 탈출/추월)
    if (isCaught) {
      return const [180, 160, 150, 130, 110, 85, 60, 40, 20, 8, 0];
    }
    return const [160, 140, 130, 110, 90, 55, 80, 120, 170, 230, 312];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 데이터 정규화
    final data = _normalized();
    final maxV = data.reduce((a, b) => a > b ? a : b).clamp(1.0, double.infinity);
    const dangerThreshold = 50.0; // 50m 이하 위험

    double xAt(int i) => data.length <= 1 ? 0 : (i / (data.length - 1)) * w;
    double yAt(double v) {
      // 거리가 클수록 위(작은 y). 0m → h, maxV → 0
      final norm = (v / maxV).clamp(0.0, 1.0);
      return h - norm * h * 0.95 - h * 0.02; // 살짝 위아래 패딩
    }

    // 위험 구간 (하단 dangerThreshold 이하)
    final dangerYTop = yAt(dangerThreshold);
    final dangerRect = Rect.fromLTRB(0, dangerYTop, w, h);
    final dangerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          dangerColor.withValues(alpha: 0.28),
          dangerColor.withValues(alpha: 0.0),
        ],
      ).createShader(dangerRect);
    canvas.drawRect(dangerRect, dangerPaint);

    // 위험선 (점선)
    final dangerLinePaint = Paint()
      ..color = dangerColor.withValues(alpha: 0.6)
      ..strokeWidth = 0.6;
    _drawDashedLine(canvas, Offset(0, dangerYTop), Offset(w, dangerYTop),
        dangerLinePaint, dashWidth: 2, gapWidth: 3);

    // 그리드 (1/3, 2/3)
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    _drawDashedLine(canvas, Offset(0, h / 3), Offset(w, h / 3), gridPaint,
        dashWidth: 1, gapWidth: 3);
    _drawDashedLine(canvas, Offset(0, h * 2 / 3), Offset(w, h * 2 / 3),
        gridPaint,
        dashWidth: 1, gapWidth: 3);

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

    // 채우기(라인 아래)
    final fillPath = Path.from(linePath)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.32),
          lineColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fillPath, fillPaint);

    // 라인
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, linePaint);

    // 최저점 (가장 위험)
    int minIdx = 0;
    for (int i = 1; i < data.length; i++) {
      if (data[i] < data[minIdx]) minIdx = i;
    }
    final minX = xAt(minIdx);
    final minY = yAt(data[minIdx]);
    canvas.drawCircle(Offset(minX, minY), 3, Paint()..color = lineColor);

    // 끝점
    final endX = xAt(data.length - 1);
    final endY = yAt(data.last);
    canvas.drawCircle(
      Offset(endX, endY),
      3,
      Paint()..color = isCaught ? lineColor : endPointColor,
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
    final distance = (totalDx * totalDx + totalDy * totalDy);
    if (distance == 0) return;
    final len = distance <= 0 ? 0.0 : (distance).toDouble();
    final lineLength = len == 0 ? 0 : (totalDx.abs() + totalDy.abs());
    if (lineLength == 0) return;

    final dx = totalDx == 0 ? 0.0 : totalDx / (totalDx.abs() + totalDy.abs());
    final dy = totalDy == 0 ? 0.0 : totalDy / (totalDx.abs() + totalDy.abs());

    double traveled = 0;
    final total = totalDx.abs() + totalDy.abs();
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
  bool shouldRepaint(covariant _ShadowDistancePainter old) =>
      old.series != series || old.isCaught != isCaught;
}
