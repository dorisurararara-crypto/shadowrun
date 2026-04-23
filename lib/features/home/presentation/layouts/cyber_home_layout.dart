import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/bgm_toggle_button.dart';
import 'package:shadowrun/shared/widgets/challenge_run_picker.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

/// T5 — Neo-Noir Cyber 홈 레이아웃. 목업 full-t5-cyber.html > SCREEN 1 HOME.
class CyberHomeLayout extends StatelessWidget {
  final Future<Map<String, dynamic>> statsFuture;
  final Future<List<RunModel>> runsFuture;
  final VoidCallback onRefresh;
  final Future<int> challengeCountFuture;
  final Future<void> Function(BuildContext) onAdPlusOneTapped;

  const CyberHomeLayout({
    super.key,
    required this.statsFuture,
    required this.runsFuture,
    required this.onRefresh,
    required this.challengeCountFuture,
    required this.onAdPlusOneTapped,
  });

  // ─── Cyber 팔레트 ──────────────────────────────────────
  static const _bg = Color(0xFF04040A);
  static const _red = Color(0xFFFF1744);
  static const _redDeep = Color(0xFF8A0A1F);
  static const _redSoft = Color(0xFFFF5470);
  static const _cyan = Color(0xFF4DD0E1);
  static const _text = Color(0xFFE8E8F0);
  static const _textDim = Color(0xFF9898A8);
  static const _textFade = Color(0xFF5A5A68);
  static const _textMute = Color(0xFF3A3A48);
  static const _borderCyan = Color(0x264DD0E1); // 15%
  static const _panel = Color(0x0A4DD0E1); // 4%

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // 배경 글로우 2개 + 가로 스캔라인
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -1.1),
                  radius: 1.1,
                  colors: [
                    _red.withValues(alpha: 0.16),
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
          Positioned.fill(
            child: RefreshIndicator(
              color: _red,
              backgroundColor: _bg,
              onRefresh: () async => onRefresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 22,
                  right: 22,
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
                          epNumber: totalRuns,
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
      bottomNavigationBar: _buildTabs(context),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required int epNumber,
    required double weeklyKm,
    required int bestEscapeM,
    required RunModel? lastRun,
    required List<RunModel> runs,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Top row: TRACKING tag + icons + BGM toggle ──
        Row(
          children: [
            _pulseTag('TRACKING · ${_pad3(epNumber)}'),
            const Spacer(),
            BgmToggleButton(color: _cyan, size: 18),
          ],
        ),
        const SizedBox(height: 18),

        // ── Logo: Shadow\nRun. (chromatic aberration) ──
        _chromaticLogo(),
        const SizedBox(height: 6),

        // ── Sub: ep.N / date / seoul ──
        RichText(
          text: TextSpan(
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: _cyan,
              letterSpacing: 2.5,
            ),
            children: [
              TextSpan(text: 'EP.${_pad3(epNumber)}'),
              const TextSpan(
                text: '  /  ',
                style: TextStyle(color: _textMute),
              ),
              TextSpan(text: _todayDot()),
              const TextSpan(
                text: '  /  ',
                style: TextStyle(color: _textMute),
              ),
              const TextSpan(text: 'SEOUL'),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: _textFade,
              letterSpacing: 1.5,
            ),
            children: [
              const TextSpan(text: '37.5658°N · 127.0450°E · '),
              TextSpan(
                text: 'ENTITY ACTIVE',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: _red,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ── Quote (red left border + glow dot) ──
        _systemLog(lastRun),
        const SizedBox(height: 22),

        // ── 3 bordered stat panels with cyan corner ──
        _statsRow(
          weeklyKm: weeklyKm,
          runsCount: epNumber,
          bestEscapeM: bestEscapeM,
        ),
        const SizedBox(height: 22),

        // ── Tonight's Protocol (red gradient) ──
        _protocolButton(context),
        const SizedBox(height: 12),
        _adPlusOneButton(context),
        _newRecordButton(context),

        const SizedBox(height: 26),

        // ── Recent logs ──
        if (runs.isNotEmpty) ...[
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _borderCyan)),
            ),
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text(
                  S.isKo ? '// 최근 로그' : '// RECENT LOGS',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: _cyan,
                    letterSpacing: 2.8,
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
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8,
                      color: _textFade,
                      letterSpacing: 2.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (int i = 0; i < runs.length; i++)
            _logRow(context, runs[i], epNumber - i),
        ],
      ],
    );
  }

  // ─── Pulse tag ────────────────────────────────────────
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

  // ─── Chromatic-aberration logo (stacked tinted text) ──
  Widget _chromaticLogo() {
    const size = 62.0;
    final style = GoogleFonts.playfairDisplay(
      fontSize: size,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w900,
      height: 0.92,
      letterSpacing: -2.8,
    );
    Widget layer(Color color, Offset offset, {double alpha = 1}) {
      return Transform.translate(
        offset: offset,
        child: Opacity(
          opacity: alpha,
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Shadow\nRun', style: style.copyWith(color: color)),
                TextSpan(
                  text: '.',
                  style: style.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: size * 2,
      child: Stack(
        children: [
          layer(_cyan, const Offset(2, 0), alpha: 0.55),
          layer(_red, const Offset(-2, 0), alpha: 0.55),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Shadow\nRun',
                  style: style.copyWith(color: _text),
                ),
                TextSpan(
                  text: '.',
                  style: style.copyWith(color: _red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── System log (quote) ───────────────────────────────
  Widget _systemLog(RunModel? last) {
    final parts = _narrativeParts(last);
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: Container(width: 2, color: _red),
        ),
        Positioned(
          left: -1,
          top: 0,
          child: Container(
            width: 4,
            height: 10,
            decoration: BoxDecoration(
              color: _red,
              boxShadow: [
                BoxShadow(color: _red.withValues(alpha: 0.9), blurRadius: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    color: _text,
                    height: 1.5,
                    letterSpacing: -0.2,
                  ),
                  children: [
                    TextSpan(text: parts.pre),
                    TextSpan(
                      text: parts.highlight,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 17,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        color: _red,
                        height: 1.5,
                        shadows: [
                          Shadow(
                            color: _red.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                    ),
                    TextSpan(text: parts.post),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: _cyan,
                    letterSpacing: 2.8,
                  ),
                  children: [
                    const TextSpan(text: '— SYSTEM LOG '),
                    TextSpan(
                      text: '·',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: _textFade,
                      ),
                    ),
                    TextSpan(text: ' ${_timeNow()} UTC+9'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  _NarrativeParts _narrativeParts(RunModel? last) {
    final ko = S.isKo;
    if (last == null) {
      return _NarrativeParts(
        pre: ko ? '엔티티가 ' : 'Entity ',
        highlight: ko ? '추적 대기 중' : 'awaiting',
        post: ko ? '.' : ' target.',
      );
    }
    if (last.isChallenge) {
      final gap = (last.finalShadowGapM ?? 0).abs().toInt();
      if (last.challengeResult == 'lose') {
        return _NarrativeParts(
          pre: ko ? '그는 어젯밤 당신을 ' : 'Entity overtook target at ',
          highlight: ko ? '따라잡았다' : '0m',
          post: ko ? '. 오늘은 더 빨리 올 것이다.' : '. Today: faster.',
        );
      }
      if (last.challengeResult == 'win') {
        return _NarrativeParts(
          pre: ko ? '그는 어젯밤 당신을 ' : 'Entity tracked target to ',
          highlight: ko ? '${gap}m' : '${gap}m',
          post: ko ? '까지 추적했다. 오늘은 더 가까울 것이다.' : '. Today: closer.',
        );
      }
    }
    return _NarrativeParts(
      pre: ko ? '마지막 로그: ' : 'Last log: ',
      highlight: last.formattedDistance,
      post: ko ? '. 엔티티 대기.' : '. Entity idle.',
    );
  }

  // ─── Stats (3 cyan corner panels) ─────────────────────
  Widget _statsRow({
    required double weeklyKm,
    required int runsCount,
    required int bestEscapeM,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statPanel(
            k: 'WEEK',
            v: RunModel.useMiles
                ? (weeklyKm / 1.609344).toStringAsFixed(1)
                : weeklyKm.toStringAsFixed(1),
            unit: RunModel.useMiles ? 'mi' : 'km',
          ),
        ),
        const SizedBox(width: 6),
        Expanded(child: _statPanel(k: 'RUNS', v: '$runsCount', unit: '')),
        const SizedBox(width: 6),
        Expanded(
          child: _statPanel(k: 'BEST', v: '$bestEscapeM', unit: 'm'),
        ),
      ],
    );
  }

  Widget _statPanel({required String k, required String v, required String unit}) {
    return Container(
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _borderCyan, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
      child: Stack(
        children: [
          // Cyan corner dot + gradient under-line
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: _cyan,
                boxShadow: [
                  BoxShadow(color: _cyan.withValues(alpha: 0.8), blurRadius: 6),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, _cyan, Colors.transparent],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                k,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: _cyan,
                  letterSpacing: 2.4,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: v,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        color: _text,
                        height: 1,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: unit,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: _textFade,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Protocol (red gradient button) ───────────────────
  Widget _protocolButton(BuildContext context) {
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
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_red, _redDeep],
          ),
          border: Border.all(color: _red, width: 1),
          boxShadow: [
            BoxShadow(
              color: _red.withValues(alpha: 0.3),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.isKo ? '// 오늘의 프로토콜' : "// TONIGHT'S PROTOCOL",
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.85),
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              S.isKo ? '지금,\n도주를 시작하라.' : 'Execute.\nBegin the run.',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white,
                height: 1.05,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Text(
                    '[ EXECUTE ]',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: Colors.white,
                      letterSpacing: 2.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '›',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
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

  // ─── New record (outlined cyan) ───────────────────────
  Widget _newRecordButton(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().tapNewRun();
        context.push('/prepare');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border.all(color: _borderCyan, width: 1),
          color: _panel,
        ),
        child: Row(
          children: [
            Text(
              S.isKo ? '// 단독 런' : '// SOLO RUN',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: _cyan,
                letterSpacing: 2.8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              S.isKo ? '시작 ›' : 'boot ›',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                color: _text,
                letterSpacing: 2.2,
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
                color: _bg,
                border: Border.all(color: _redSoft.withValues(alpha: 0.55)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.play_circle_outline,
                    size: 14,
                    color: _redSoft,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.isKo ? '// 광고 +1' : '// AD +1',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: _redSoft,
                      letterSpacing: 2.6,
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

  // ─── Log row ──────────────────────────────────────────
  Widget _logRow(BuildContext context, RunModel r, int epNo) {
    final isWin = r.challengeResult == 'win';
    final isLoss = r.challengeResult == 'lose';
    final gap = (r.finalShadowGapM ?? 0).toInt();
    final status = isWin
        ? 'ESCAPED'
        : isLoss
            ? 'CAPTURED'
            : 'LOGGED';
    final statusColor = isLoss ? _red : (isWin ? _cyan : _textDim);
    final valueText = r.isChallenge
        ? (gap >= 0 ? '+${_pad3(gap)}' : '−${_pad3(gap.abs())}')
        : r.formattedDistance;
    final loc = r.name?.trim().isNotEmpty == true
        ? r.name!.trim()
        : (r.location?.trim().isNotEmpty == true
            ? r.location!.trim()
            : (S.isKo ? '미지' : 'Unmarked'));

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().tapCard();
        context.push('/result', extra: {'runId': r.id});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0x194DD0E1)), // cyan 10%
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              padding: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                border: Border(right: BorderSide(color: _borderCyan)),
              ),
              child: Text(
                _pad3(epNo),
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: _cyan,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _shorten(loc, 8),
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: _text,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: statusColor.withValues(alpha: 0.45)),
                        ),
                        child: Text(
                          status,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 7.5,
                            color: statusColor,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_dateShort(r.date)} · ${r.formattedDistance} / ${r.formattedDuration}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 8.5,
                      color: _textFade,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            RichText(
              textAlign: TextAlign.right,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: valueText,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 13,
                      color: isLoss ? _red : (isWin ? _cyan : _text),
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text: '\nMETERS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 7,
                      color: _textFade,
                      letterSpacing: 2,
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

  // ─── Tabs ─────────────────────────────────────────────
  Widget _buildTabs(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xD904040A),
        border: Border(top: BorderSide(color: _borderCyan)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tab('●', 'HOME', active: true, onTap: () {}),
              _tab('◷', 'LOGS', onTap: () {
                SfxService().tapCard();
                context.push('/history');
              }),
              _tab('◎', 'STATS', onTap: () {
                SfxService().tapCard();
                context.push('/analysis');
              }),
              _tab('⚙', 'SYS', onTap: () {
                SfxService().tapCard();
                context.push('/settings');
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(String icon, String label,
      {bool active = false, required VoidCallback onTap}) {
    final color = active ? _red : _textFade;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                icon,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  height: 1,
                  shadows: active
                      ? [
                          Shadow(
                            color: _red.withValues(alpha: 0.8),
                            blurRadius: 10,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: color,
                  letterSpacing: 2.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── helpers ──────────────────────────────────────────
  static String _pad3(int n) => n.toString().padLeft(3, '0');

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
