import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/bgm_toggle_button.dart';
import 'package:shadowrun/shared/widgets/challenge_run_picker.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

/// T4 — Editorial Thriller 홈 레이아웃. 목업 full-t4-editorial.html > Cover Story.
class EditorialHomeLayout extends StatelessWidget {
  final Future<Map<String, dynamic>> statsFuture;
  final Future<List<RunModel>> runsFuture;
  final VoidCallback onRefresh;
  final Future<int> challengeCountFuture;
  final Future<void> Function(BuildContext) onAdPlusOneTapped;

  const EditorialHomeLayout({
    super.key,
    required this.statsFuture,
    required this.runsFuture,
    required this.onRefresh,
    required this.challengeCountFuture,
    required this.onAdPlusOneTapped,
  });

  // ─── Editorial 팔레트 ──────────────────────────────────
  static const _ink = Color(0xFF0A0A0A);
  static const _white = Color(0xFFFFFFFF);
  static const _red = Color(0xFFDC2626);
  static const _redSoft = Color(0xFFF87171);
  static const _muted = Color(0xFF888888);
  static const _mutedDim = Color(0xFF555555);
  static const _hair = Color(0x1FFFFFFF); // white 12%
  static const _hairLow = Color(0x14FFFFFF); // white 8%

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          // Subtle vertical grain
          const Positioned.fill(child: _Grain()),
          Positioned.fill(
            child: RefreshIndicator(
              color: _red,
              backgroundColor: _ink,
              onRefresh: () async => onRefresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 18,
                  left: 24,
                  right: 24,
                  bottom: 28,
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
                          issueNumber: totalRuns,
                          weeklyKm: weeklyKm,
                          bestEscapeM: bestEscape,
                          lastRun: lastRun,
                          runs: runs.take(4).toList(),
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

  // ─── Bottom nav (magazine style) ───────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(top: BorderSide(color: _white, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem('COVER', 'home', active: true, onTap: () {}),
              _navItem('BACK', 'archive', onTap: () {
                SfxService().tapCard();
                context.push('/history');
              }),
              _navItem('REPORT', 'stats', onTap: () {
                SfxService().tapCard();
                context.push('/analysis');
              }),
              _navItem('MAST', 'settings', onTap: () {
                SfxService().tapCard();
                context.push('/settings');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    String top,
    String bottom, {
    bool active = false,
    required VoidCallback onTap,
  }) {
    final color = active ? _red : _muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              top,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              bottom,
              style: GoogleFonts.playfairDisplay(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: color,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required int issueNumber,
    required double weeklyKm,
    required int bestEscapeM,
    required RunModel? lastRun,
    required List<RunModel> runs,
  }) {
    final nextIssue = issueNumber + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Page head (mast-top) ──
        Row(
          children: [
            Text(
              'COVER · P.01',
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
            const Spacer(),
            Text(
              'SHADOWRUN/HOME',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF7A7A7F),
                letterSpacing: 3.5,
              ),
            ),
            BgmToggleButton(color: _redSoft, size: 16),
          ],
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: _hair),
        const SizedBox(height: 16),

        // ── No. 028 ──
        Text(
          'No. ${_pad3(issueNumber)}',
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
            color: const Color(0xFF888888),
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(height: 2, color: _white),
        const SizedBox(height: 8),

        // ── HUGE logo "Shadow\nRun." ──
        RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 60,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: _white,
              height: 0.88,
              letterSpacing: -3,
            ),
            children: const [
              TextSpan(text: 'Shadow\nRun'),
              TextSpan(text: '.', style: TextStyle(color: _red)),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // ── Tagline (border-bottom white 2px) ──
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _white, width: 2)),
            ),
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              S.isKo
                  ? '— 추적은 멈추지 않는다 —'
                  : '— THE CHASE NEVER SLEEPS —',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF9A9A9F),
                letterSpacing: 3,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),

        // ── Section tag: Cover Story ──
        _sectionTag(S.isKo ? '커버 스토리' : 'COVER STORY'),
        const SizedBox(height: 10),

        // ── Cover lede with drop-cap ──
        _coverLede(lastRun),
        const SizedBox(height: 12),

        // ── Cover meta ──
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _hair)),
          ),
          padding: const EdgeInsets.only(bottom: 14),
          child: _coverMeta(lastRun, issueNumber),
        ),
        const SizedBox(height: 18),

        // ── Stat row (3 cells, right-border divider) ──
        _statRow(
          weeklyKm: weeklyKm,
          chapters: issueNumber,
          bestEscapeM: bestEscapeM,
        ),
        const SizedBox(height: 22),

        // ── Today's Issue (red box w/ inset border) ──
        _todaysIssueBox(context, nextIssue: nextIssue),
        const SizedBox(height: 12),
        _adPlusOneButton(context),
        _newRecordButton(context),

        const SizedBox(height: 30),

        // ── Back Issues ──
        if (runs.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: '◆ ',
                      style: TextStyle(
                        color: _red,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextSpan(
                      text: S.isKo ? '이전 발간호' : 'BACK ISSUES',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _red,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  SfxService().tapCard();
                  context.push('/history');
                },
                child: Text(
                  S.isKo ? '전체 호 ›' : 'all issues ›',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFAAAAAA),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 2, color: _white),
          for (int i = 0; i < runs.length; i++)
            _issueRow(context, runs[i], issueNumber - i),
        ],
      ],
    );
  }

  // ─── Section tag ──────────────────────────────────────
  Widget _sectionTag(String text) {
    return Row(
      children: [
        const Text('◆',
            style: TextStyle(color: _red, fontSize: 9)),
        const SizedBox(width: 6),
        Text(
          text,
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
    );
  }

  // ─── Cover lede ───────────────────────────────────────
  Widget _coverLede(RunModel? last) {
    final parts = _narrativeParts(last);
    final body = TextStyle(
      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w400,
      color: _white,
      height: 1.3,
      letterSpacing: -0.3,
    );
    final dropCap = TextStyle(
      fontFamily: GoogleFonts.playfairDisplay().fontFamily,
      fontSize: 56,
      fontWeight: FontWeight.w900,
      fontStyle: FontStyle.italic,
      color: _red,
      height: 0.9,
    );
    // First glyph becomes drop cap.
    final first = parts.pre.isNotEmpty ? parts.pre.substring(0, 1) : '·';
    final rest = parts.pre.length > 1 ? parts.pre.substring(1) : '';
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.top,
            child: Padding(
              padding: const EdgeInsets.only(right: 6, top: 2),
              child: Text(first, style: dropCap),
            ),
          ),
          TextSpan(text: rest, style: body),
          TextSpan(
            text: parts.highlight,
            style: body.copyWith(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: _red,
            ),
          ),
          TextSpan(text: parts.post, style: body),
        ],
      ),
    );
  }

  _NarrativeParts _narrativeParts(RunModel? last) {
    final ko = S.isKo;
    if (last == null) {
      return _NarrativeParts(
        pre: ko ? '그는 당신을 ' : 'He has been ',
        highlight: ko ? '기다리고 있다' : 'waiting',
        post: ko ? '.' : '.',
      );
    }
    if (last.isChallenge) {
      final gap = (last.finalShadowGapM ?? 0).abs().toInt();
      if (last.challengeResult == 'lose') {
        return _NarrativeParts(
          pre: ko ? '그는 어젯밤, 당신을 ' : 'Last night, he ',
          highlight: ko ? '따라잡았다' : 'caught you',
          post: ko ? '.' : '.',
        );
      }
      if (last.challengeResult == 'win') {
        return _NarrativeParts(
          pre: ko ? '그는 어젯밤, 당신의 ' : 'Last night, he came within ',
          highlight: ko ? '$gap미터' : '$gap meters',
          post: ko ? ' 뒤까지 따라붙었다.' : ' of you.',
        );
      }
    }
    return _NarrativeParts(
      pre: ko ? '어제, 당신은 ' : 'Yesterday, you ran ',
      highlight: last.formattedDistance,
      post: ko ? '를 달렸다.' : '.',
    );
  }

  // ─── Cover meta ───────────────────────────────────────
  Widget _coverMeta(RunModel? last, int issueNumber) {
    final loc = last?.location?.trim();
    final name = last?.name?.trim();
    final locText = (name != null && name.isNotEmpty)
        ? name
        : (loc != null && loc.isNotEmpty)
            ? loc
            : (S.isKo ? '어느 길' : 'Unmarked');
    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          fontSize: 9.5,
          fontWeight: FontWeight.w300,
          color: const Color(0xFF777777),
          letterSpacing: 2.8,
        ),
        children: [
          TextSpan(text: _shorten(locText, 12).toUpperCase()),
          const WidgetSpan(child: SizedBox(width: 10)),
          WidgetSpan(
            child: Text(
              '·',
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: _redSoft,
              ),
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 10)),
          TextSpan(text: _timeNow()),
          const WidgetSpan(child: SizedBox(width: 10)),
          WidgetSpan(
            child: Text(
              '·',
              style: GoogleFonts.playfairDisplay(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: _redSoft,
              ),
            ),
          ),
          const WidgetSpan(child: SizedBox(width: 10)),
          TextSpan(text: 'CH. ${_pad3(issueNumber)}'),
        ],
      ),
    );
  }

  // ─── Stat row ─────────────────────────────────────────
  Widget _statRow({
    required double weeklyKm,
    required int chapters,
    required int bestEscapeM,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _statCell(
            label: S.isKo ? '이번 주' : 'WEEK',
            value: RunModel.useMiles
                ? (weeklyKm / 1.609344).toStringAsFixed(1)
                : weeklyKm.toStringAsFixed(1),
            unit: RunModel.useMiles ? 'mi' : 'km',
          ),
        ),
        Container(width: 1, height: 44, color: _hair),
        Expanded(
          child: _statCell(
            label: S.isKo ? '챕터' : 'CHAPTERS',
            value: '$chapters',
            unit: '',
          ),
        ),
        Container(width: 1, height: 44, color: _hair),
        Expanded(
          child: _statCell(
            label: S.isKo ? '최장' : 'BEST',
            value: '$bestEscapeM',
            unit: 'm',
          ),
        ),
      ],
    );
  }

  Widget _statCell({
    required String label,
    required String value,
    required String unit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF7A7A7F),
              letterSpacing: 2.8,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    color: _white,
                    height: 1,
                    letterSpacing: -0.8,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: const Color(0xFF777777),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Today's issue (red box) ──────────────────────────
  Widget _todaysIssueBox(BuildContext context, {required int nextIssue}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        SfxService().tapChallenge();
        final runId = await pickChallengeRun(context);
        if (runId != null && context.mounted) {
          context.push('/prepare', extra: runId);
        }
      },
      child: Container(
        color: _red,
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _white.withValues(alpha: 0.25), width: 1),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.isKo
                    ? '오늘의 호 · No. ${_pad3(nextIssue)}'
                    : "TODAY'S ISSUE · No. ${_pad3(nextIssue)}",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.78),
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                S.isKo
                    ? 'Chapter ${_pad3(nextIssue)}\n이 지금 시작된다.'
                    : 'Chapter ${_pad3(nextIssue)}\nbegins now.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: _white,
                  height: 1.05,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: _white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Text(
                      S.isKo ? '읽기 시작' : 'BEGIN READING',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _white,
                        letterSpacing: 3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '›',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        color: _white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── New record button (outlined) ─────────────────────
  Widget _newRecordButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().tapNewRun();
        context.push('/prepare');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: _white.withValues(alpha: 0.3), width: 1),
          color: _ink,
        ),
        child: Row(
          children: [
            Text(
              S.isKo ? '단독 기록 · SOLO' : 'SOLO · NEW RECORD',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _white,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            Text(
              S.isKo ? '시작 ›' : 'begin ›',
              style: GoogleFonts.playfairDisplay(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: _redSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _adPlusOneButton(BuildContext context) {
    return FutureBuilder<int>(
      future: challengeCountFuture,
      builder: (context, snap) {
        const maxFree = 3;
        final used = snap.data ?? 0;
        if (used < maxFree) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onAdPlusOneTapped(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: _ink,
                border: Border.all(
                  color: _red.withValues(alpha: 0.55),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_outline, size: 14, color: _red),
                  const SizedBox(width: 8),
                  Text(
                    S.isKo ? '광고 +1' : 'AD +1',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _red,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Issue row (back issues) ──────────────────────────
  Widget _issueRow(BuildContext context, RunModel r, int issueNo) {
    final isWin = r.challengeResult == 'win';
    final isLoss = r.challengeResult == 'lose';
    final gap = (r.finalShadowGapM ?? 0).toInt();
    final metaRes = isWin
        ? (S.isKo ? '탈출' : 'ESCAPED')
        : isLoss
            ? (S.isKo ? '잡힘' : 'CAUGHT')
            : (S.isKo ? '완주' : 'LOGGED');
    final dateStr = _dateShort(r.date);
    final valueText = r.isChallenge
        ? (gap >= 0 ? '+${_pad3(gap)}' : '−${_pad3(gap.abs())}')
        : r.formattedDistance;
    final subtitleName = r.name?.trim().isNotEmpty == true
        ? r.name!.trim()
        : (r.location?.trim().isNotEmpty == true
            ? r.location!.trim()
            : (S.isKo ? '어느 밤' : 'Unmarked'));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().tapCard();
        context.push('/result', extra: {'runId': r.id});
      },
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hairLow)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: Text(
                _pad3(issueNo),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  color: _mutedDim,
                  height: 1,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        color: _white,
                        height: 1.15,
                      ),
                      children: [
                        TextSpan(text: _shorten(subtitleName, 18)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${r.formattedDistance.toUpperCase()} · $dateStr · $metaRes',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                      color: _muted,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              valueText,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: isLoss ? _mutedDim : _red,
                letterSpacing: -0.2,
                decoration:
                    isLoss ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: _mutedDim,
              ),
            ),
          ],
        ),
      ),
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

  static String _timeNow() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _dateShort(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  static String _shorten(String s, int max) =>
      s.length > max ? '${s.substring(0, max)}…' : s;
}

class _NarrativeParts {
  final String pre;
  final String highlight;
  final String post;
  _NarrativeParts({
    required this.pre,
    required this.highlight,
    required this.post,
  });
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
