import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T1 Pure Cinematic 테마용 History(Chronicles) 화면.
///
/// 구성 (designs/full-t1-pure.html · 5. History):
///   - 상단 "← home"
///   - "Chronicles" Playfair Italic 대제목 + "April 2026" 서브
///   - 월간 요약 상하 괘선: "28 runs · 64.8km · 22·6" (세로 실선 구분)
///   - 에피소드 리스트: "E28" 번호 · "4월 16일 wed" · 장소/거리/시간 · "escaped"/"caught"
class PureHistoryLayout extends StatelessWidget {
  final List<RunModel> runs;
  final void Function(RunModel run) onRunTap;
  final VoidCallback onClose;

  const PureHistoryLayout({
    super.key,
    required this.runs,
    required this.onRunTap,
    required this.onClose,
  });

  // Pure Cinematic 팔레트 (full-t1-pure.html :root 변수)
  static const _bgPage = Color(0xFF050507);
  static const _ink = Color(0xFFF5F5F5);
  static const _inkDim = Color(0xFF9A9A9A);
  static const _inkFade = Color(0xFF5A5A5E);
  static const _redSub = Color(0xFFC83030);
  static const _redEmber = Color(0xFF5A0000);
  static final _hair = const Color(0xFFF5F5F5).withValues(alpha: 0.08);

  // 세로 실선 구분선 (월간 요약 카드)
  static const _vDivider = Color(0xFF2A0000);

  // ---------- 월간 집계 ----------
  List<RunModel> _runsThisMonth(DateTime now) {
    return runs.where((r) {
      final dt = DateTime.tryParse(r.date);
      if (dt == null) return false;
      return dt.year == now.year && dt.month == now.month;
    }).toList();
  }

  // "April", "May" ...
  static const _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdaysEn = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthRuns = _runsThisMonth(now);
    final totalRuns = monthRuns.length;
    final totalKm = monthRuns.fold<double>(0, (a, r) => a + r.distanceM) / 1000;
    final wins = monthRuns.where((r) => r.challengeResult == 'win').length;
    final losses = monthRuns.where((r) => r.challengeResult == 'lose').length;

    return Scaffold(
      backgroundColor: _bgPage,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(now),
                    const SizedBox(height: 20),
                    _buildMonthlySummary(
                      totalRuns: totalRuns,
                      totalKm: totalKm,
                      wins: wins,
                      losses: losses,
                    ),
                    const SizedBox(height: 22),
                    _buildSectionLabel(),
                    const SizedBox(height: 2),
                    if (runs.isEmpty)
                      _buildEmpty()
                    else
                      ...runs.map(_buildEpisodeRow),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 상단 바 "← home" ----------
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
                      'home',
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

  // ---------- 헤더 "Chronicles / April 2026" ----------
  Widget _buildHeader(DateTime now) {
    final month = _monthsEn[now.month - 1];
    final year = now.year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Chronicles',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 38,
            fontStyle: FontStyle.italic,
            color: _ink,
            height: 1,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$month $year'.toUpperCase(),
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: _redSub,
            fontWeight: FontWeight.w400,
            letterSpacing: 4.5,
          ),
        ),
        const SizedBox(height: 18),
        Container(width: 28, height: 1, color: _redEmber),
        const SizedBox(height: 2),
      ],
    );
  }

  // ---------- 월간 요약 상하 괘선 ----------
  Widget _buildMonthlySummary({
    required int totalRuns,
    required double totalKm,
    required int wins,
    required int losses,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _hair, width: 1),
          bottom: BorderSide(color: _hair, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _SummaryCell(
                valueWidget: Text(
                  '$totalRuns',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: _ink,
                    height: 1,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
                label: 'RUNS',
              ),
            ),
            Container(width: 1, color: _vDivider),
            Expanded(
              child: _SummaryCell(
                valueWidget: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: totalKm.toStringAsFixed(1),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          color: _ink,
                          height: 1,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.2,
                        ),
                      ),
                      TextSpan(
                        text: 'km',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 10,
                          color: _inkFade,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                label: 'DISTANCE',
              ),
            ),
            Container(width: 1, color: _vDivider),
            Expanded(
              child: _SummaryCell(
                valueWidget: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$wins',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: _ink,
                          height: 1,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: ' · ',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          color: _redEmber,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: '$losses',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          color: _redSub,
                          height: 1,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                label: 'WON · LOST',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- 섹션 라벨 "chapters this month" ----------
  Widget _buildSectionLabel() {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _hair, width: 1),
        ),
      ),
      child: Text(
        'CHAPTERS THIS MONTH',
        style: GoogleFonts.playfairDisplay(
          fontSize: 10,
          fontStyle: FontStyle.italic,
          color: _inkFade,
          fontWeight: FontWeight.w400,
          letterSpacing: 3.5,
        ),
      ),
    );
  }

  // ---------- 빈 상태 ----------
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Text(
            'no chapters yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: _inkDim,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '첫 번째 밤을 새겨라.',
            style: GoogleFonts.notoSerif(
              fontSize: 11,
              color: _inkFade,
              fontWeight: FontWeight.w300,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 에피소드 row ----------
  Widget _buildEpisodeRow(RunModel run) {
    final dt = DateTime.tryParse(run.date);
    final episodeNo = run.id ?? 0;

    final dateKo = dt != null ? '${dt.month}월 ${dt.day}일' : run.date;
    final weekEn = dt != null ? _weekdaysEn[dt.weekday - 1] : '';

    final distKm = (run.distanceM / 1000).toStringAsFixed(2);
    final duration = run.formattedDuration;

    final isWin = run.challengeResult == 'win';
    final isLoss = run.challengeResult == 'lose';
    final resultLabel = isWin ? 'escaped' : isLoss ? 'caught' : 'chased';
    final resultColor = isLoss ? _redSub : _inkFade;

    final location = (run.location ?? '').trim().isEmpty
        ? '이름 없는 길'
        : run.location!.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onRunTap(run),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _hair, width: 1),
          ),
        ),
        child: SizedBox(
          height: 48,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 좌측 번호 "E28"
              SizedBox(
                width: 46,
                child: Text(
                  'E$episodeNo',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: _inkDim,
                    height: 1,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 중앙: 날짜 + 장소/거리/시간
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: dateKo,
                            style: GoogleFonts.notoSerif(
                              fontSize: 13,
                              color: _ink,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.1,
                            ),
                          ),
                          if (weekEn.isNotEmpty)
                            TextSpan(
                              text: '  $weekEn',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                color: _inkFade,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$location · $distKm km · $duration',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSerif(
                        fontSize: 10.5,
                        color: _inkFade,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // 우측: 결과
              Text(
                resultLabel,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: resultColor,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== 내부 위젯 =====================

class _SummaryCell extends StatelessWidget {
  final Widget valueWidget;
  final String label;

  const _SummaryCell({
    required this.valueWidget,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        valueWidget,
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.playfairDisplay(
            fontSize: 9,
            fontStyle: FontStyle.italic,
            color: PureHistoryLayout._inkFade,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }
}
