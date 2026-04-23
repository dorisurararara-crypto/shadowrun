import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/bgm_toggle_button.dart';
import 'package:shadowrun/shared/widgets/challenge_run_picker.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

/// T2 — Film Noir 홈 레이아웃. 목업 full-t2-noir.html > Cell 1(HOME · CASE No. 028).
class NoirHomeLayout extends StatelessWidget {
  final Future<Map<String, dynamic>> statsFuture;
  final Future<List<RunModel>> runsFuture;
  final VoidCallback onRefresh;
  final Future<int> challengeCountFuture;
  final Future<void> Function(BuildContext) onAdPlusOneTapped;

  const NoirHomeLayout({
    super.key,
    required this.statsFuture,
    required this.runsFuture,
    required this.onRefresh,
    required this.challengeCountFuture,
    required this.onAdPlusOneTapped,
  });

  // ─── Film Noir 팔레트 ─────────────────────────────────────
  static const _ink = Color(0xFF0D0907);           // 짙은 브라운블랙
  static const _ink2 = Color(0xFF160E08);          // 카드 상단
  static const _ink3 = Color(0xFF0A0604);          // 카드 하단
  static const _paper = Color(0xFFE8DCC4);         // 크림 페이퍼
  static const _paperDim = Color(0xFFA89A80);      // 서브 텍스트
  static const _paperFade = Color(0xFF6A5D48);     // 흐린 텍스트
  static const _brass = Color(0xFFB89660);         // 브래스 골드
  static const _brassDim = Color(0xFF8A6F48);      // 브래스 서브
  static const _wine = Color(0xFF8B2635);          // 와인 블러드
  static const _line = Color(0xFF2A1D10);          // 괘선

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: RefreshIndicator(
              color: _brass,
              backgroundColor: _ink,
              onRefresh: () async => onRefresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20,
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
                          caseNumber: totalRuns,
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
    required int caseNumber,
    required double weeklyKm,
    required int bestEscapeM,
    required RunModel? lastRun,
    required List<RunModel> runs,
  }) {
    final nextCase = caseNumber + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Case stamp row ──
        Row(
          children: [
            Transform.rotate(
              angle: -0.05,
              child: _stamp('CASE NO. ${_pad3(caseNumber)}'),
            ),
            const Spacer(),
            Text(
              _todayEn(),
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: _paperFade,
                letterSpacing: 3,
                fontWeight: FontWeight.w400,
              ),
            ),
            BgmToggleButton(color: _brass, size: 18),
          ],
        ),
        const SizedBox(height: 18),

        // ── Logo: Shadow Run (Cormorant Italic 48) ──
        Text(
          'Shadow Run',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 48,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: _paper,
            height: 0.9,
            letterSpacing: -1.4,
          ),
        ),
        const SizedBox(height: 6),

        // ── Tagline ──
        Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _line, width: 1)),
            ),
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              S.isKo ? 'A NIGHTLY  CHASE' : 'A  NIGHTLY  CHASE',
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: _brass,
                letterSpacing: 4.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),

        // ── Last Reported (wine left border) ──
        _lastReported(lastRun),
        const SizedBox(height: 22),

        // ── Stats 3 ──
        _statsRow(
          weeklyKm: weeklyKm,
          cases: caseNumber,
          bestEscapeM: bestEscapeM,
        ),
        const SizedBox(height: 24),

        // ── Open Case (brass card) ──
        _openCaseCard(context, nextCase: nextCase),
        const SizedBox(height: 14),
        _adPlusOneButton(context),
        _newRecordCard(context),

        const SizedBox(height: 30),

        // ── Previous Files ──
        if (runs.isNotEmpty) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                S.isKo ? '이전 사건' : 'Previous Files',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  color: _paper,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  SfxService().tapCard();
                  context.push('/history');
                },
                child: Text(
                  'VIEW ALL ›',
                  style: GoogleFonts.oswald(
                    fontSize: 9,
                    color: _brass,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < runs.length; i++)
            _prevRow(context, runs[i], caseNumber - i),
        ],
      ],
    );
  }

  // ─── Stamp ─────────────────────────────────────────────
  Widget _stamp(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(border: Border.all(color: _brass, width: 1)),
      child: Text(
        text,
        style: GoogleFonts.oswald(
          fontSize: 10,
          color: _brass,
          letterSpacing: 3.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ─── Last Reported quote ───────────────────────────────
  Widget _lastReported(RunModel? last) {
    final parts = _narrativeParts(last);
    return Container(
      padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _wine, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.isKo ? '지난 보고' : 'LAST REPORTED',
            style: GoogleFonts.oswald(
              fontSize: 9,
              color: _wine,
              letterSpacing: 4,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.cormorantGaramond(
                fontSize: 17,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: _paper,
                height: 1.45,
              ),
              children: [
                TextSpan(text: parts.pre),
                TextSpan(
                  text: parts.highlight,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: _wine,
                  ),
                ),
                TextSpan(text: parts.post),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.isKo ? '— 지난 쉐도우런에서 —' : '— PREVIOUSLY ON SHADOW RUN —',
            style: GoogleFonts.oswald(
              fontSize: 9,
              color: _paperFade,
              letterSpacing: 3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  _NarrativeParts _narrativeParts(RunModel? last) {
    final ko = S.isKo;
    if (last == null) {
      return _NarrativeParts(
        pre: ko ? '용의자, ' : 'Subject, ',
        highlight: ko ? '행방 불명' : 'still at large',
        post: ko ? '. 단서 없음.' : '. No leads.',
      );
    }
    if (last.isChallenge) {
      final gap = (last.finalShadowGapM ?? 0).abs().toInt();
      if (last.challengeResult == 'lose') {
        return _NarrativeParts(
          pre: ko ? '용의자, 당신을 ' : 'Subject caught ',
          highlight: ko ? '덮쳤다' : 'you',
          post: ko ? '. 사건 미해결.' : '. Case cold.',
        );
      }
      if (last.challengeResult == 'win') {
        return _NarrativeParts(
          pre: ko ? '용의자, 피해자로부터\n' : 'Subject, ',
          highlight: ko ? '$gap미터' : '$gap meters',
          post: ko ? '. 추적 지속 중.' : ' behind. Tail ongoing.',
        );
      }
    }
    return _NarrativeParts(
      pre: ko ? '기록: ' : 'Logged: ',
      highlight: last.formattedDistance,
      post: ko ? '. 사건 종결.' : '. Case closed.',
    );
  }

  // ─── Stats row ─────────────────────────────────────────
  Widget _statsRow({
    required double weeklyKm,
    required int cases,
    required int bestEscapeM,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _line, width: 1),
          bottom: BorderSide(color: _line, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _statCell(
              label: S.isKo ? '이번 주' : 'THIS WEEK',
              value: RunModel.useMiles
                  ? (weeklyKm / 1.609344).toStringAsFixed(1)
                  : weeklyKm.toStringAsFixed(1),
              unit: RunModel.useMiles ? 'MI' : 'KM',
            ),
          ),
          Container(width: 1, height: 44, color: _line),
          Expanded(
            child: _statCell(
              label: S.isKo ? '사건' : 'CASES',
              value: '$cases',
              unit: '',
            ),
          ),
          Container(width: 1, height: 44, color: _line),
          Expanded(
            child: _statCell(
              label: S.isKo ? '최장 간격' : 'MAX GAP',
              value: '$bestEscapeM',
              unit: 'M',
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
        Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 9,
            color: _paperFade,
            letterSpacing: 3,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: _paper,
                  height: 1,
                  letterSpacing: -0.2,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: GoogleFonts.oswald(
                    fontSize: 9,
                    color: _paperFade,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Open case card (Tonight) ─────────────────────────
  Widget _openCaseCard(BuildContext context, {required int nextCase}) {
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
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        decoration: BoxDecoration(
          border: Border.all(color: _brass, width: 1),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_ink2, _ink3],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.isKo
                  ? '오늘밤 · 사건 ${_pad3(nextCase)}'
                  : 'TONIGHT · CASE ${_pad3(nextCase)}',
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: _brass,
                letterSpacing: 4.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: _paper,
                  height: 1.1,
                  letterSpacing: -0.4,
                ),
                children: [
                  TextSpan(text: S.isKo ? '오늘의 ' : "Open tonight's "),
                  TextSpan(
                    text: S.isKo ? '사건' : 'file',
                    style: const TextStyle(color: _brass),
                  ),
                  TextSpan(text: S.isKo ? '을\n열 시간이다.' : '.'),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: _brassDim, width: 0.6)),
              ),
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Text(
                    S.isKo ? '파일 열기' : 'OPEN THE FILE',
                    style: GoogleFonts.oswald(
                      fontSize: 11,
                      color: _paper,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '›',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 26,
                      color: _brass,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── New record (무채색 새 기록) ────────────────────────
  Widget _newRecordCard(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().tapNewRun();
        context.push('/prepare');
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          border: Border.all(color: _paperFade, width: 1),
          color: _ink,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.isKo ? '단독 기록' : 'SOLO RECORD',
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: _paperDim,
                letterSpacing: 4,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.isKo ? '홀로, 새 기록을.' : 'Alone, a new record.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: _paper,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  S.isKo ? '조용히 시작' : 'BEGIN IN SILENCE',
                  style: GoogleFonts.oswald(
                    fontSize: 10,
                    color: _paperDim,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(),
                Text(
                  '›',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    color: _paperDim,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Ad +1 ────────────────────────────────────────────
  Widget _adPlusOneButton(BuildContext context) {
    return FutureBuilder<int>(
      future: challengeCountFuture,
      builder: (context, snap) {
        const maxFree = 3;
        final used = snap.data ?? 0;
        if (used < maxFree) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onAdPlusOneTapped(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _ink,
                border: Border.all(color: _wine.withValues(alpha: 0.55), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_outline, size: 14, color: _wine),
                  const SizedBox(width: 8),
                  Text(
                    S.isKo ? '광고 +1' : 'AD +1',
                    style: GoogleFonts.oswald(
                      fontSize: 10,
                      color: _wine,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w500,
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

  // ─── Previous file row ────────────────────────────────
  Widget _prevRow(BuildContext context, RunModel r, int caseNo) {
    final isWin = r.challengeResult == 'win';
    final isLoss = r.challengeResult == 'lose';
    final gap = (r.finalShadowGapM ?? 0).toInt();
    final valueText = r.isChallenge
        ? (gap >= 0 ? '+${gap}m' : '${gap}m')
        : r.formattedDistance;
    final lblText = isWin
        ? (S.isKo ? '해결' : 'SOLVED')
        : isLoss
            ? (S.isKo ? '미해결' : 'COLD')
            : (S.isKo ? '기록' : 'LOGGED');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().tapCard();
        context.push('/result', extra: {'runId': r.id});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line, width: 0.5)),
        ),
        child: Row(
          children: [
            // Badge
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isLoss ? _wine : _brass,
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _pad3(caseNo),
                    style: GoogleFonts.oswald(
                      fontSize: 11,
                      color: isLoss ? _wine : _brass,
                      fontWeight: FontWeight.w600,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'CASE',
                    style: GoogleFonts.oswald(
                      fontSize: 7,
                      color: isLoss ? _wine : _brass,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dateLabel(r),
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: _paper,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${r.formattedDistance}  ·  ${r.formattedDuration}',
                    style: GoogleFonts.oswald(
                      fontSize: 9,
                      color: _paperFade,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  valueText,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isLoss ? _wine : _paper,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lblText,
                  style: GoogleFonts.oswald(
                    fontSize: 8,
                    color: _paperFade,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom nav ───────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(top: BorderSide(color: _line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem('HOME', 'home', active: true, onTap: () {}),
              _navItem('FILES', 'archive', onTap: () {
                SfxService().tapCard();
                context.push('/history');
              }),
              _navItem('STATS', 'report', onTap: () {
                SfxService().tapCard();
                context.push('/analysis');
              }),
              _navItem('AGENT', 'profile', onTap: () {
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
    final color = active ? _brass : _paperFade;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              top,
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: color,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              bottom,
              style: GoogleFonts.cormorantGaramond(
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

  // ─── helpers ──────────────────────────────────────────
  static String _pad3(int n) => n.toString().padLeft(3, '0');

  static String _todayEn() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]} · ${months[now.month - 1]} ${now.day}';
  }

  static String _dateLabel(RunModel r) {
    final userName = r.name?.trim() ?? '';
    if (userName.isNotEmpty) return userName;
    final dt = DateTime.tryParse(r.date);
    if (dt == null) return r.date;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final d = '${months[dt.month - 1]} ${dt.day.toString().padLeft(2, '0')}';
    final loc = r.location?.trim() ?? '';
    return loc.isNotEmpty ? '$d · $loc' : d;
  }
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
