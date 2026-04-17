import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/challenge_run_picker.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

/// T1 — Pure Cinematic 홈 레이아웃
/// 순검정 배경 + 세리프 + 영화 자막체. 목업 full-t1-pure.html > Cell 1(Home) 충실 재현.
class PureHomeLayout extends StatelessWidget {
  final Future<Map<String, dynamic>> statsFuture;
  final Future<List<RunModel>> runsFuture;
  final VoidCallback onRefresh;

  const PureHomeLayout({
    super.key,
    required this.statsFuture,
    required this.runsFuture,
    required this.onRefresh,
  });

  // ─── Pure Cinematic 팔레트 ──────────────────────────────────
  static const _ink = Color(0xFF000000);           // 순검정
  static const _offWhite = Color(0xFFF5F5F5);      // 오프화이트 본문
  static const _bloodDeep = Color(0xFF8B0000);     // 블러드 레드 (강조)
  static const _bloodSub = Color(0xFFC83030);      // 블러드 서브
  static const _divider = Color(0xFF2A0000);       // 이중 괘선
  static const _faint = Color(0xFF555555);         // 외곽선 서브
  static const _muted = Color(0xFF7A7A7A);         // 서브 텍스트

  @override
  Widget build(BuildContext context) {
    // MysticHomeLayout과 동일한 hit-test 버그 방지 패턴:
    // Scaffold body = Stack, SingleChildScrollView를 Positioned.fill로 감싼다.
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              color: _bloodSub,
              backgroundColor: _ink,
              onRefresh: () async => onRefresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 28,
                  left: 24,
                  right: 24,
                  bottom: 32,
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: statsFuture,
                  builder: (context, statsSnap) {
                    final stats = statsSnap.data ?? const {};
                    final totalRuns = (stats['totalRuns'] ?? 0) as int;
                    final totalDistanceM =
                        ((stats['totalDistanceM'] ?? 0.0) as num).toDouble();
                    final weeklyKm = totalDistanceM / 1000;
                    return FutureBuilder<List<RunModel>>(
                      future: runsFuture,
                      builder: (context, runsSnap) {
                        final runs = runsSnap.data ?? const <RunModel>[];
                        final lastRun = runs.isNotEmpty ? runs.first : null;
                        final bestEscape = runs.isEmpty
                            ? 0
                            : runs
                                .map((r) => r.distanceM.toInt())
                                .reduce((a, b) => a > b ? a : b);
                        final prevMeters = lastRun?.distanceM.toInt() ?? 0;
                        return _buildContent(
                          context,
                          totalRuns: totalRuns,
                          weeklyKm: weeklyKm,
                          bestEscapeM: bestEscape,
                          prevMeters: prevMeters,
                          runs: runs.take(3).toList(),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required int totalRuns,
    required double weeklyKm,
    required int bestEscapeM,
    required int prevMeters,
    required List<RunModel> runs,
  }) {
    // "Episode 005" 가 무슨 뜻인지 사용자가 혼란 → padding 제거 + "N번째 달리기"로 명확화.
    final runCount = totalRuns + 1;
    final episodeLabel = S.isKo
        ? '$runCount번째 달리기'
        : 'Your run #$runCount';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Eyebrow: a shadow never rests ──
        Center(
          child: Text(
            '— a shadow never rests —',
            style: GoogleFonts.playfairDisplay(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _bloodSub,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── Logo: Shadow Run (Playfair 900 Italic) ──
        Center(
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Shadow ',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 52,
                    fontStyle: FontStyle.italic,
                    color: _offWhite,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                ),
                TextSpan(
                  text: 'Run',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 52,
                    fontStyle: FontStyle.italic,
                    color: _bloodDeep,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // ── Episode 028 · Date ──
        Center(
          child: Text(
            '$episodeLabel   ·   ${_todayEn()}',
            style: GoogleFonts.notoSerifKr(
              fontSize: 11,
              color: _muted,
              letterSpacing: 3,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        const SizedBox(height: 30),

        // ── Cinematic subtitle quote ──
        _quoteBlock(prevMeters),

        const SizedBox(height: 10),

        // ── previously on shadow run ──
        Center(
          child: Text(
            '— previously on shadow run —',
            style: GoogleFonts.playfairDisplay(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _muted,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Stats: 이중 괘선 사이 3칸 ──
        _statsRow(weeklyKm: weeklyKm, chapters: totalRuns, bestEscapeM: bestEscapeM),

        const SizedBox(height: 32),

        // ── Doppelgänger card (begin tonight's run) ──
        _doppelgangerCard(context),
        const SizedBox(height: 14),
        _newRecordCard(context),

        const SizedBox(height: 32),

        // ── Recent chapters ──
        if (runs.isNotEmpty) ...[
          Row(
            children: [
              Expanded(child: Container(height: 1, color: _divider)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'recent chapters',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: _muted,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              Expanded(child: Container(height: 1, color: _divider)),
            ],
          ),
          const SizedBox(height: 16),
          for (final r in runs) _recentRow(r),
        ],
      ],
    );
  }

  // ─── Quote block ───────────────────────────────────────────
  Widget _quoteBlock(int prevMeters) {
    if (prevMeters <= 0) {
      return SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            children: [
              Text(
                S.isKo
                    ? '그는 아직 당신을\n찾지 못했다.'
                    : 'He has not\nfound you yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 18,
                  color: _offWhite,
                  height: 1.7,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              S.isKo ? '어젯밤, 그는 당신보다' : 'Last night, he came',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifKr(
                fontSize: 17,
                color: _offWhite,
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.notoSerifKr(
                  fontSize: 17,
                  color: _offWhite,
                  height: 1.7,
                ),
                children: [
                  TextSpan(
                    text: S.isKo ? '$prevMeters미터' : '${prevMeters}m',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontStyle: FontStyle.italic,
                      color: _bloodSub,
                      fontWeight: FontWeight.w800,
                      height: 1.5,
                    ),
                  ),
                  TextSpan(text: S.isKo ? ' 더 가까이' : ' closer'),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              S.isKo ? '다가왔다.' : 'than you.',
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifKr(
                fontSize: 17,
                color: _offWhite,
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Stats row: 상하 이중 괘선 ──────────────────────────────
  Widget _statsRow({
    required double weeklyKm,
    required int chapters,
    required int bestEscapeM,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _divider, width: 1),
          bottom: BorderSide(color: _divider, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: _statCell(
              value: weeklyKm.toStringAsFixed(1),
              unit: 'km',
              label: 'this week',
            ),
          ),
          Container(width: 1, height: 50, color: _divider),
          Expanded(
            child: _statCell(
              value: '$chapters',
              unit: '',
              label: 'chapters',
            ),
          ),
          Container(width: 1, height: 50, color: _divider),
          Expanded(
            child: _statCell(
              value: '$bestEscapeM',
              unit: 'm',
              label: 'best escape',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell({
    required String value,
    required String unit,
    required String label,
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
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  color: _offWhite,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: _muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.playfairDisplay(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: _muted,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ─── Doppelgänger card (challenge 진입) ─────────────────────
  Widget _doppelgangerCard(BuildContext context) {
    return _actionCard(
      context: context,
      height: 118,
      titleKo: S.isKo ? '오늘의 도주' : "Tonight's Chase",
      subtitleEn: "begin tonight's run",
      borderColor: _bloodDeep,
      accentColor: _bloodSub,
      onTap: () async {
        SfxService().tapChallenge();
        final runId = await pickChallengeRun(context);
        if (runId != null && context.mounted) {
          context.push('/prepare', extra: runId);
        }
      },
    );
  }

  // ─── New record card ───────────────────────────────────────
  Widget _newRecordCard(BuildContext context) {
    return _actionCard(
      context: context,
      height: 118,
      titleKo: S.isKo ? '홀로, 새 기록을' : 'Alone, a new record.',
      subtitleEn: "tonight's legend",
      borderColor: _faint,
      accentColor: _muted,
      onTap: () {
        debugPrint('[PureHome] 새 기록 카드 TAP');
        SfxService().tapNewRun();
        context.push('/prepare');
      },
    );
  }

  /// 공통 액션 카드 — Stack 없이 Column+Row 조합 (hit test 단순화)
  Widget _actionCard({
    required BuildContext context,
    required double height,
    required String titleKo,
    required String subtitleEn,
    required Color borderColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _ink,
            border: Border.all(color: borderColor, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Eyebrow
              Text(
                subtitleEn,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: accentColor,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w400,
                ),
              ),
              // Title
              Text(
                titleKo,
                style: GoogleFonts.notoSerifKr(
                  fontSize: 24,
                  color: _offWhite,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              // CTA arrow line
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '—   cue the chase',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: accentColor,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    '›',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontStyle: FontStyle.italic,
                      color: accentColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Recent row ────────────────────────────────────────────
  Widget _recentRow(RunModel r) {
    final isWin = r.challengeResult == 'win';
    final isLoss = r.challengeResult == 'lose';
    // 챌린지가 아닌 경우에도 무난한 라벨
    final resultLabel =
        isWin ? 'escaped' : isLoss ? 'caught' : 'chapter closed';
    final resultColor =
        isWin ? _offWhite : isLoss ? _bloodSub : _muted;

    final date = _dateShort(r.date);
    final location = (r.location ?? '').trim().isEmpty ? 'unmarked path' : r.location!;
    final shortLoc = location.length > 12 ? '${location.substring(0, 12)}…' : location;
    final distKm = (r.distanceM / 1000).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$date  ·  $shortLoc',
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 13,
                    color: _offWhite,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${distKm}km  ·  ${r.formattedDuration}',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: _muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Text(
            resultLabel,
            style: GoogleFonts.playfairDisplay(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: resultColor,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom nav: HOME / LOGS / CHART / SETTINGS (Playfair Italic) ──
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(top: BorderSide(color: _divider, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, 'home', active: true, onTap: () {}),
            _navItem(context, 'logs', onTap: () {
              SfxService().tapCard();
              context.push('/history');
            }),
            _navItem(context, 'chart', onTap: () {
              SfxService().tapCard();
              context.push('/analysis');
            }),
            _navItem(context, 'settings', onTap: () {
              SfxService().tapCard();
              context.push('/settings');
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String label, {
    bool active = false,
    required VoidCallback onTap,
  }) {
    final color = active ? _bloodSub : _muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: color,
                  letterSpacing: 2,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              const SizedBox(height: 3),
              Container(
                width: active ? 18 : 0,
                height: 1,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── helpers ───────────────────────────────────────────────
  static String _todayEn() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${weekdays[now.weekday - 1]}';
  }

  static String _dateShort(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}';
  }
}
