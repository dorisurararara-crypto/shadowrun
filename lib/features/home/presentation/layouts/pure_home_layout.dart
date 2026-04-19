import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/bgm_toggle_button.dart';
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
                        return _buildContent(
                          context,
                          totalRuns: totalRuns,
                          weeklyKm: weeklyKm,
                          bestEscapeM: bestEscape,
                          lastRun: lastRun,
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
    required RunModel? lastRun,
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
        // ── Eyebrow: a shadow never rests + 우측 BGM 토글 ──
        Row(
          children: [
            const SizedBox(width: 44),
            Expanded(
              child: Center(
                child: Text(
                  S.isKo ? '— 그림자는 쉬지 않는다 —' : '— a shadow never rests —',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: _bloodSub,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            BgmToggleButton(color: _bloodSub),
          ],
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
        _quoteBlock(lastRun),

        const SizedBox(height: 10),

        // ── previously on shadow run ──
        Center(
          child: Text(
            S.isKo ? '— 지난 달리기 —' : '— previously on shadow run —',
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
                  S.isKo ? '최근 기록' : 'recent chapters',
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
  /// 어제 러닝 결과에 따른 시적 카피. 도플갱어 승/패, 자유, 마라톤 분기.
  Widget _quoteBlock(RunModel? lastRun) {
    final parts = _narrativeParts(lastRun);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              parts.line1,
              textAlign: TextAlign.center,
              style: GoogleFonts.notoSerifKr(
                fontSize: 17,
                color: _offWhite,
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              parts.highlight,
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontStyle: FontStyle.italic,
                color: parts.highlightColor,
                fontWeight: FontWeight.w800,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              parts.line3,
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

  _NarrativeParts _narrativeParts(RunModel? last) {
    final ko = S.isKo;
    if (last == null) {
      return _NarrativeParts(
        line1: ko ? '그림자는' : 'The shadow',
        highlight: ko ? '당신을 기다린다' : 'waits for you',
        highlightColor: _offWhite,
        line3: ko ? '' : '',
      );
    }
    // 같은 날(오늘) 달린 기록이면 "오늘 / Today", 그 외엔 "어젯밤 / Last night".
    final lastDate = DateTime.tryParse(last.date);
    final now = DateTime.now();
    final isToday = lastDate != null &&
        lastDate.year == now.year &&
        lastDate.month == now.month &&
        lastDate.day == now.day;
    final whenPrefix = isToday
        ? (ko ? '오늘' : 'Tonight')
        : (ko ? '어젯밤' : 'Last night');
    final youPrefix = isToday
        ? (ko ? '오늘 당신은' : 'Tonight, you ran')
        : (ko ? '어제 당신은' : 'Yesterday, you ran');
    final yesterdayRun = isToday
        ? (ko ? '오늘의' : 'Today\'s')
        : (ko ? '어제의' : 'Yesterday\'s');
    if (last.isChallenge) {
      final r = last.challengeResult;
      // 도플갱어 모드 표시용 거리는 **최종 간격(finalShadowGapM)** 을 우선 사용.
      // 구버전 레코드(null)나 fallback 시 distanceM 사용.
      final gap = (last.finalShadowGapM ?? 0).abs().toInt();
      if (r == 'lose') {
        return _NarrativeParts(
          line1: ko ? '$whenPrefix, 그는' : '$whenPrefix, he',
          highlight: ko ? '당신을 덮쳤다' : 'caught you',
          highlightColor: _bloodSub,
          line3: ko ? '.' : '.',
        );
      }
      if (r == 'win') {
        if (gap >= 500) {
          return _NarrativeParts(
            line1: ko ? '$whenPrefix, 그를' : '$whenPrefix,',
            highlight: ko ? '$gap미터' : '${gap}m',
            highlightColor: _bloodSub,
            line3: ko ? '차이로 떨궈놓고 왔다.' : 'far behind you.',
          );
        }
        if (gap >= 100) {
          return _NarrativeParts(
            line1: ko ? '$whenPrefix, 그를' : '$whenPrefix, by',
            highlight: ko ? '$gap미터' : '${gap}m',
            highlightColor: _bloodSub,
            line3: ko ? '앞서 벗어났다.' : 'you escaped him.',
          );
        }
        return _NarrativeParts(
          line1: ko ? '$whenPrefix,' : '$whenPrefix,',
          highlight: ko ? '아슬아슬하게' : 'just barely',
          highlightColor: _bloodSub,
          line3: ko ? '벗어났다.' : 'you got away.',
        );
      }
      // isChallenge 인데 result null (취소·오류) — 중립
      return _NarrativeParts(
        line1: yesterdayRun,
        highlight: ko ? '달리기' : 'run',
        highlightColor: _offWhite,
        line3: ko ? '가 기록되었다.' : 'is recorded.',
      );
    }
    // 자유 · 마라톤 (isChallenge=false)
    return _NarrativeParts(
      line1: youPrefix,
      highlight: last.formattedDistance,
      highlightColor: _offWhite,
      line3: ko ? '를 달렸다.' : '.',
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
              value: RunModel.useMiles
                  ? (weeklyKm / 1.609344).toStringAsFixed(1)
                  : weeklyKm.toStringAsFixed(1),
              unit: RunModel.useMiles ? 'mi' : 'km',
              label: S.isKo ? '이번 주' : 'this week',
            ),
          ),
          Container(width: 1, height: 50, color: _divider),
          Expanded(
            child: _statCell(
              value: '$chapters',
              unit: '',
              label: S.isKo ? '기록' : 'chapters',
            ),
          ),
          Container(width: 1, height: 50, color: _divider),
          Expanded(
            child: _statCell(
              value: '$bestEscapeM',
              unit: 'm',
              label: S.isKo ? '최장 탈출' : 'best escape',
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
      subtitleEn: S.isKo ? '오늘 밤의 추격' : "begin tonight's run",
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
      subtitleEn: S.isKo ? '오늘의 전설' : "tonight's legend",
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
                    S.isKo ? '—   추격 시작' : '—   cue the chase',
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
    final resultLabel = S.isKo
        ? (isWin ? '탈출' : isLoss ? '잡힘' : '완주')
        : (isWin ? 'escaped' : isLoss ? 'caught' : 'chapter closed');
    final resultColor =
        isWin ? _offWhite : isLoss ? _bloodSub : _muted;

    final date = _dateShort(r.date);
    final userName = r.name?.trim() ?? '';
    final autoLoc = r.location?.trim() ?? '';
    final location = userName.isNotEmpty
        ? userName
        : (autoLoc.isNotEmpty ? autoLoc : (S.isKo ? '이름 없는 길' : 'unmarked path'));
    final shortLoc = location.length > 12 ? '${location.substring(0, 12)}…' : location;

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
                  '${r.formattedDistance}  ·  ${r.formattedDuration}',
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

class _NarrativeParts {
  final String line1;
  final String highlight;
  final Color highlightColor;
  final String line3;
  _NarrativeParts({
    required this.line1,
    required this.highlight,
    required this.highlightColor,
    required this.line3,
  });
}
