import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

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
  final void Function(RunModel run)? onRunChallenge;
  final void Function(RunModel run)? onRunEdit;
  final void Function(RunModel run)? onRunDelete;

  const PureHistoryLayout({
    super.key,
    required this.runs,
    required this.onRunTap,
    required this.onClose,
    this.onRunChallenge,
    this.onRunEdit,
    this.onRunDelete,
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
      bottomNavigationBar: const BannerAdTile(),
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

  // ---------- 헤더 "Chronicles / April 2026" ----------
  Widget _buildHeader(DateTime now) {
    final month = _monthsEn[now.month - 1];
    final year = now.year;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          S.isKo ? '연대기' : 'Chronicles',
          textAlign: TextAlign.center,
          style: S.isKo
              ? GoogleFonts.notoSerifKr(
                  fontSize: 34,
                  color: _ink,
                  height: 1,
                  fontWeight: FontWeight.w500,
                )
              : GoogleFonts.playfairDisplay(
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
                label: S.isKo ? '러닝' : 'RUNS',
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
                        text: RunModel.useMiles
                            ? (totalKm / 1.609344).toStringAsFixed(1)
                            : totalKm.toStringAsFixed(1),
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
                        text: RunModel.useMiles ? 'mi' : 'km',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 10,
                          color: _inkFade,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                label: S.isKo ? '거리' : 'DISTANCE',
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
                          height: 1,
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
                label: S.isKo ? '탈출 · 잡힘' : 'WON · LOST',
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
        S.isKo ? '이번 달 기록' : 'CHAPTERS THIS MONTH',
        style: S.isKo
            ? GoogleFonts.notoSerifKr(
                fontSize: 10,
                color: _inkFade,
                fontWeight: FontWeight.w400,
                letterSpacing: 3.5,
              )
            : GoogleFonts.playfairDisplay(
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
            S.isKo ? '아직 기록 없음' : 'no chapters yet',
            style: S.isKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 18,
                    color: _inkDim,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                  )
                : GoogleFonts.playfairDisplay(
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
    return Builder(
      builder: (ctx) => _buildEpisodeRowContent(ctx, run),
    );
  }

  Widget _buildEpisodeRowContent(BuildContext context, RunModel run) {
    final dt = DateTime.tryParse(run.date);
    final episodeNo = run.id ?? 0;

    final dateKo = dt != null ? '${dt.month}월 ${dt.day}일' : run.date;
    final weekEn = dt != null ? _weekdaysEn[dt.weekday - 1] : '';

    final distance = run.formattedDistance;
    final duration = run.formattedDuration;

    final isWin = run.challengeResult == 'win';
    final isLoss = run.challengeResult == 'lose';
    final isKo = S.isKo;
    final resultLabel = isWin
        ? (isKo ? '탈출' : 'escaped')
        : isLoss
            ? (isKo ? '잡힘' : 'caught')
            : (isKo ? '완주' : 'chased');
    final resultColor = isLoss ? _redSub : _inkFade;

    // 사용자 지정 이름(run.name) 우선, 없으면 자동 장소(run.location), 둘 다 없으면 플레이스홀더
    final userName = run.name?.trim() ?? '';
    final autoLoc = run.location?.trim() ?? '';
    final location = userName.isNotEmpty
        ? userName
        : (autoLoc.isNotEmpty ? autoLoc : '이름 없는 길');

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
                      '$location · $distance · $duration',
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
                style: isKo
                    ? GoogleFonts.notoSerifKr(
                        fontSize: 11,
                        color: resultColor,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.5,
                      )
                    : GoogleFonts.playfairDisplay(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: resultColor,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 2.5,
                      ),
              ),
              // 우측 끝: ⋯ 액션 버튼
              if (onRunEdit != null || onRunDelete != null || onRunChallenge != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showActionSheet(context, run),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(left: 6),
                    child: Text(
                      '⋯',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: _inkFade,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- 액션 바텀시트 (수정/삭제/도전) ----------
  void _showActionSheet(BuildContext context, RunModel run) {
    final isKo = S.isKo;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 1,
                  margin: const EdgeInsets.only(top: 4, bottom: 16),
                  color: _hair,
                ),
                Text(
                  isKo ? '액션' : 'ACTIONS',
                  style: isKo
                      ? GoogleFonts.notoSerifKr(
                          fontSize: 10,
                          color: _inkFade,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 3.5,
                        )
                      : GoogleFonts.playfairDisplay(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: _inkFade,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 3.5,
                        ),
                ),
                const SizedBox(height: 14),
                if (onRunChallenge != null)
                  _PureSheetItem(
                    label: isKo ? '도플갱어로 도전' : 'Challenge as doppelganger',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onRunChallenge!(run);
                    },
                  ),
                if (onRunEdit != null)
                  _PureSheetItem(
                    label: isKo ? '이름 변경' : 'Rename',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onRunEdit!(run);
                    },
                  ),
                if (onRunDelete != null)
                  _PureSheetItem(
                    label: isKo ? '삭제' : 'Delete',
                    danger: true,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onRunDelete!(run);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===================== 내부 위젯 =====================

/// Pure 바텀시트 액션 아이템. danger: true면 _red 외곽선.
class _PureSheetItem extends StatelessWidget {
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _PureSheetItem({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(
            color: danger
                ? PureHistoryLayout._redSub
                : PureHistoryLayout._hair,
            width: danger ? 1 : 0.8,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: danger
                ? PureHistoryLayout._redSub
                : PureHistoryLayout._ink,
            fontWeight: FontWeight.w400,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

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
      mainAxisSize: MainAxisSize.min,
      children: [
        valueWidget,
        const SizedBox(height: 3),
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
