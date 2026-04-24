import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

/// T5 Neo-Noir Cyber 테마용 History(DATA LOG) 화면.
///
/// 구성 (designs/full-t5-cyber.html · SCREEN 5 HISTORY):
///   - 상단 "LOGS · ARCHIVE" 태그 + ⌕ / ▽ 아이콘
///   - 대제목 "LOGS · APR 2026" (chromatic aberration)
///   - 서브 "28 ENTRIES · FROM 04.01 TO 04.17"
///   - 3 cyan corner panel (RUNS / DIST / W/L)
///   - RECENT ENTRIES 헤더 + "↓ LATEST" sort 라벨
///   - hs-row: id 028 · 제목 + ESCAPED/CAPTURED 뱃지 · date · distance/time · +/-NNN METERS
///   - 배경 스캔라인/red·cyan glow 배경 오버레이
class CyberHistoryLayout extends StatefulWidget {
  final List<RunModel> runs;
  final void Function(RunModel run) onRunTap;
  final VoidCallback onClose;
  final void Function(RunModel run)? onRunChallenge;
  final void Function(RunModel run)? onRunEdit;
  final void Function(RunModel run)? onRunDelete;

  const CyberHistoryLayout({
    super.key,
    required this.runs,
    required this.onRunTap,
    required this.onClose,
    this.onRunChallenge,
    this.onRunEdit,
    this.onRunDelete,
  });

  // ── Cyber 팔레트 (cyber_home_layout 과 동일) ──
  static const _bg = Color(0xFF04040A);
  static const _red = Color(0xFFFF1744);
  static const _cyan = Color(0xFF4DD0E1);
  static const _text = Color(0xFFE8E8F0);
  static const _textDim = Color(0xFF9898A8);
  static const _textFade = Color(0xFF5A5A68);
  static const _textMute = Color(0xFF3A3A48);
  static const _borderCyan = Color(0x264DD0E1);
  static const _borderCyanLow = Color(0x194DD0E1);
  static const _panel = Color(0x0A4DD0E1);

  @override
  State<CyberHistoryLayout> createState() => _CyberHistoryLayoutState();
}

class _CyberHistoryLayoutState extends State<CyberHistoryLayout>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchOpen = false;
  bool _sortAsc = false; // false = 최신순

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() {
      if (!_tab.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<RunModel> get _visibleRuns {
    Iterable<RunModel> src = widget.runs;
    if (_tab.index == 1) src = src.where((r) => r.isChallenge);
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      src = src.where((r) {
        final n = (r.name ?? '').toLowerCase();
        final l = (r.location ?? '').toLowerCase();
        return n.contains(q) || l.contains(q) || r.date.contains(q);
      });
    }
    final list = src.toList();
    list.sort((a, b) {
      final cmp = a.date.compareTo(b.date);
      return _sortAsc ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.runs;
    final totalKm = all.fold<double>(0, (a, r) => a + r.distanceM) / 1000;
    final wins = all.where((r) => r.challengeResult == 'win').length;
    final losses = all.where((r) => r.challengeResult == 'lose').length;
    final (fromDate, toDate) = _dateRange(all);

    return Scaffold(
      backgroundColor: CyberHistoryLayout._bg,
      bottomNavigationBar: const BannerAdTile(),
      body: Stack(
        children: [
          // Red glow top-right
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -1.1),
                  radius: 1.1,
                  colors: [
                    CyberHistoryLayout._red.withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          // Cyan glow bottom-left
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.0, 1.0),
                  radius: 1.0,
                  colors: [
                    CyberHistoryLayout._cyan.withValues(alpha: 0.08),
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
                _topBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 6, 22, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _tagRow(),
                        const SizedBox(height: 18),
                        _titleChromatic(),
                        const SizedBox(height: 4),
                        _subtitle(all.length, fromDate, toDate),
                        const SizedBox(height: 18),
                        _summaryPanels(all.length, totalKm, wins, losses),
                        const SizedBox(height: 18),
                        _filters(),
                        if (_searchOpen) ...[
                          const SizedBox(height: 10),
                          _searchField(),
                        ],
                        const SizedBox(height: 14),
                        _listHeader(),
                        const SizedBox(height: 4),
                        if (_visibleRuns.isEmpty)
                          _empty()
                        else
                          for (int i = 0; i < _visibleRuns.length; i++)
                            _logRow(
                              _visibleRuns[i],
                              _visibleRuns[i].id ??
                                  (widget.runs.length - i),
                            ),
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

  // ── Top bar ──
  Widget _topBar() {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: CyberHistoryLayout._borderCyan, width: 1),
                ),
                child: Text(
                  '← HOME',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: CyberHistoryLayout._cyan,
                    letterSpacing: 2.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const Spacer(),
            _pulseTag('LOGS · ACTIVE'),
          ],
        ),
      ),
    );
  }

  Widget _pulseTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: CyberHistoryLayout._red, width: 1),
        color: const Color(0x0AFF1744),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: CyberHistoryLayout._red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CyberHistoryLayout._red.withValues(alpha: 0.8),
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
              color: CyberHistoryLayout._red,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tagRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: CyberHistoryLayout._cyan, width: 1),
            color: const Color(0x104DD0E1),
          ),
          child: Text(
            S.isKo ? '// 로그 · 아카이브' : 'LOGS · ARCHIVE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: CyberHistoryLayout._cyan,
              letterSpacing: 2.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            _searchOpen = !_searchOpen;
            if (!_searchOpen) {
              _query = '';
              _searchCtrl.clear();
            }
          }),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                color: _searchOpen
                    ? CyberHistoryLayout._cyan
                    : CyberHistoryLayout._borderCyan,
                width: 1,
              ),
            ),
            child: Icon(
              Icons.search,
              size: 14,
              color: _searchOpen
                  ? CyberHistoryLayout._cyan
                  : CyberHistoryLayout._textFade,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _sortAsc = !_sortAsc),
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(
                  color: CyberHistoryLayout._borderCyan, width: 1),
            ),
            child: Text(
              _sortAsc ? '△' : '▽',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: CyberHistoryLayout._textFade,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Title with chromatic aberration ──
  Widget _titleChromatic() {
    final title = 'LOGS · ${_todayMonthYearUpper()}';
    final baseStyle = GoogleFonts.playfairDisplay(
      fontSize: 30,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w900,
      height: 1,
      letterSpacing: -0.8,
    );
    return SizedBox(
      height: 36,
      child: Stack(
        children: [
          // cyan ghost
          Transform.translate(
            offset: const Offset(2, 0),
            child: Opacity(
              opacity: 0.55,
              child: Text(
                title,
                style: baseStyle.copyWith(color: CyberHistoryLayout._cyan),
              ),
            ),
          ),
          // red ghost
          Transform.translate(
            offset: const Offset(-2, 0),
            child: Opacity(
              opacity: 0.55,
              child: Text(
                title,
                style: baseStyle.copyWith(color: CyberHistoryLayout._red),
              ),
            ),
          ),
          // main
          Text(
            title,
            style: baseStyle.copyWith(color: CyberHistoryLayout._text),
          ),
        ],
      ),
    );
  }

  Widget _subtitle(int count, String fromDate, String toDate) {
    final rangeTxt = count == 0
        ? (S.isKo ? '데이터 없음' : 'NO DATA')
        : '$fromDate ${S.isKo ? "부터" : "TO"} $toDate';
    return RichText(
      text: TextSpan(
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          color: CyberHistoryLayout._textDim,
          letterSpacing: 2.4,
        ),
        children: [
          TextSpan(
            text: '${_pad3(count)} ${S.isKo ? "항목" : "ENTRIES"}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: CyberHistoryLayout._cyan,
              letterSpacing: 2.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: '  ·  '),
          TextSpan(text: rangeTxt),
        ],
      ),
    );
  }

  // ── Summary (3 cyan corner panels) ──
  Widget _summaryPanels(int runs, double km, int wins, int losses) {
    return Row(
      children: [
        Expanded(
          child: _statPanel(
            k: 'RUNS',
            v: _pad3(runs),
            unit: '',
            accent: CyberHistoryLayout._text,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _statPanel(
            k: 'DIST',
            v: RunModel.useMiles
                ? (km / 1.609344).toStringAsFixed(1)
                : km.toStringAsFixed(1),
            unit: RunModel.useMiles ? 'mi' : 'km',
            accent: CyberHistoryLayout._text,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _statPanel(
            k: 'W/L',
            v: '$wins',
            unit: ':$losses',
            accent: CyberHistoryLayout._cyan,
            negUnit: true,
          ),
        ),
      ],
    );
  }

  Widget _statPanel({
    required String k,
    required String v,
    required String unit,
    required Color accent,
    bool negUnit = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: CyberHistoryLayout._panel,
        border: Border.all(color: CyberHistoryLayout._borderCyan, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: CyberHistoryLayout._cyan,
                boxShadow: [
                  BoxShadow(
                    color:
                        CyberHistoryLayout._cyan.withValues(alpha: 0.8),
                    blurRadius: 6,
                  ),
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
                  colors: [
                    Colors.transparent,
                    CyberHistoryLayout._cyan,
                    Colors.transparent,
                  ],
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
                  color: CyberHistoryLayout._cyan,
                  letterSpacing: 2.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: v,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w700,
                        color: accent,
                        height: 1,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: unit,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: negUnit
                              ? CyberHistoryLayout._red
                              : CyberHistoryLayout._textFade,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w700,
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

  // ── Filters (tabs) ──
  Widget _filters() {
    return Row(
      children: [
        _filterBtn(0, S.isKo ? '전체' : 'ALL'),
        const SizedBox(width: 6),
        _filterBtn(1, S.isKo ? '도전' : 'CHALLENGE'),
        const Spacer(),
        Text(
          _sortAsc
              ? (S.isKo ? '↑ 오래된순' : '↑ OLDEST')
              : (S.isKo ? '↓ 최신순' : '↓ LATEST'),
          style: GoogleFonts.jetBrainsMono(
            fontSize: 8.5,
            color: CyberHistoryLayout._textFade,
            letterSpacing: 2.4,
          ),
        ),
      ],
    );
  }

  Widget _filterBtn(int i, String label) {
    final active = _tab.index == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab.index = i),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? CyberHistoryLayout._red.withValues(alpha: 0.12)
              : Colors.transparent,
          border: Border.all(
            color: active
                ? CyberHistoryLayout._red
                : CyberHistoryLayout._borderCyan,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: active
                ? CyberHistoryLayout._red
                : CyberHistoryLayout._textFade,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: CyberHistoryLayout._panel,
        border:
            Border.all(color: CyberHistoryLayout._borderCyan, width: 1),
      ),
      child: Row(
        children: [
          Text(
            '>',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: CyberHistoryLayout._cyan,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              cursorColor: CyberHistoryLayout._cyan,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 13,
                color: CyberHistoryLayout._text,
                letterSpacing: 1,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText:
                    S.isKo ? 'QUERY: 태그/날짜/장소' : 'QUERY: tag/date/loc',
                hintStyle: GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: CyberHistoryLayout._textFade,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── List header "// RECENT ENTRIES" ──
  Widget _listHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: CyberHistoryLayout._borderCyan, width: 1),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            _tab.index == 1
                ? (S.isKo ? '// 도전 기록' : '// CHALLENGE LOGS')
                : (S.isKo ? '// 최근 항목' : '// RECENT ENTRIES'),
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: CyberHistoryLayout._cyan,
              letterSpacing: 2.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'n=${_pad3(_visibleRuns.length)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8.5,
              color: CyberHistoryLayout._textFade,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Log row ──
  Widget _logRow(RunModel r, int logNo) {
    final isWin = r.challengeResult == 'win';
    final isLoss = r.challengeResult == 'lose';
    final gap = (r.finalShadowGapM ?? 0).toInt();
    final status = isWin
        ? 'ESCAPED'
        : isLoss
            ? 'CAPTURED'
            : 'LOGGED';
    final statusColor = isLoss
        ? CyberHistoryLayout._red
        : (isWin
            ? CyberHistoryLayout._cyan
            : CyberHistoryLayout._textDim);

    final valueText = r.isChallenge
        ? (gap >= 0
            ? '+${_pad3(gap)}'
            : '−${_pad3(gap.abs())}')
        : r.formattedDistance;
    final valueColor = isLoss
        ? CyberHistoryLayout._red
        : (isWin
            ? CyberHistoryLayout._cyan
            : CyberHistoryLayout._text);

    final name = r.name?.trim() ?? '';
    final loc = r.location?.trim() ?? '';
    final title = name.isNotEmpty
        ? name
        : (loc.isNotEmpty
            ? loc
            : (S.isKo ? '미식별' : 'UNMARKED'));
    final dateStr = _dateShort(r.date);

    return Dismissible(
      key: ValueKey('cy-${r.id ?? r.date}'),
      direction: widget.onRunDelete == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: CyberHistoryLayout._red.withValues(alpha: 0.18),
          border: Border.all(color: CyberHistoryLayout._red, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'rm -f',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: CyberHistoryLayout._red,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.delete_forever_outlined,
              size: 14,
              color: CyberHistoryLayout._red,
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        widget.onRunDelete?.call(r);
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onRunTap(r),
        onLongPress: widget.onRunEdit != null
            ? () => widget.onRunEdit!(r)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: CyberHistoryLayout._borderCyanLow,
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ID column
              Container(
                width: 44,
                padding: const EdgeInsets.only(right: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(
                      color: CyberHistoryLayout._borderCyan,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pad3(logNo),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: CyberHistoryLayout._cyan,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'LOG',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 7,
                        color: CyberHistoryLayout._textMute,
                        letterSpacing: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontStyle: FontStyle.italic,
                              color: CyberHistoryLayout._text,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: statusColor.withValues(alpha: 0.5),
                            ),
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
                      '$dateStr · ${r.formattedDistance} / ${r.formattedDuration}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 8.5,
                        color: CyberHistoryLayout._textFade,
                        letterSpacing: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Value
              RichText(
                textAlign: TextAlign.right,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: valueText,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 13,
                        color: valueColor,
                        letterSpacing: 0.4,
                        fontWeight: FontWeight.w700,
                        shadows: isLoss || isWin
                            ? [
                                Shadow(
                                  color:
                                      valueColor.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    TextSpan(
                      text: r.isChallenge ? '\nMETERS' : '\nDIST',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 7,
                        color: CyberHistoryLayout._textFade,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onRunEdit != null ||
                  widget.onRunDelete != null ||
                  widget.onRunChallenge != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showActionSheet(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 8),
                    margin: const EdgeInsets.only(left: 4),
                    child: Text(
                      '::',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 16,
                        color: CyberHistoryLayout._textFade,
                        fontWeight: FontWeight.w700,
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

  // ── Empty ──
  Widget _empty() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CyberHistoryLayout._panel,
        border: Border.all(
            color: CyberHistoryLayout._borderCyan, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '// NO DATA',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: CyberHistoryLayout._cyan,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
                color: CyberHistoryLayout._text,
                height: 1.2,
              ),
              children: [
                TextSpan(text: S.isKo ? '엔티티 ' : 'Entity '),
                TextSpan(
                  text: S.isKo ? '대기' : 'idle',
                  style: const TextStyle(
                    color: CyberHistoryLayout._red,
                  ),
                ),
                TextSpan(text: S.isKo ? ' 중.' : '.'),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            S.isKo
                ? 'EXECUTE NEW RUN TO WRITE LOG.0'
                : 'EXECUTE NEW RUN TO WRITE LOG.0',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: CyberHistoryLayout._textFade,
              letterSpacing: 2.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Action sheet ──
  void _showActionSheet(RunModel run) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CyberHistoryLayout._bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 1,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        CyberHistoryLayout._cyan,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: CyberHistoryLayout._red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: CyberHistoryLayout._red
                                .withValues(alpha: 0.9),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      S.isKo ? '// 작업' : '// OPERATIONS',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: CyberHistoryLayout._cyan,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (widget.onRunChallenge != null)
                  _CyberSheetItem(
                    command: 'exec --replay',
                    label: S.isKo
                        ? '도플갱어로 재실행'
                        : 'Challenge as doppelganger',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      widget.onRunChallenge!(run);
                    },
                  ),
                if (widget.onRunEdit != null)
                  _CyberSheetItem(
                    command: 'mv <log>',
                    label: S.isKo ? '로그명 변경' : 'Rename log',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      widget.onRunEdit!(run);
                    },
                  ),
                if (widget.onRunDelete != null)
                  _CyberSheetItem(
                    command: 'rm -f <log>',
                    label: S.isKo ? '로그 삭제' : 'Delete log',
                    danger: true,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      widget.onRunDelete!(run);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── helpers ──
  static String _pad3(int n) => n.toString().padLeft(3, '0');

  static String _dateShort(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }

  String _todayMonthYearUpper() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.year}';
  }

  (String, String) _dateRange(List<RunModel> rs) {
    if (rs.isEmpty) return ('--', '--');
    DateTime? minD;
    DateTime? maxD;
    for (final r in rs) {
      final dt = DateTime.tryParse(r.date);
      if (dt == null) continue;
      if (minD == null || dt.isBefore(minD)) minD = dt;
      if (maxD == null || dt.isAfter(maxD)) maxD = dt;
    }
    if (minD == null || maxD == null) return ('--', '--');
    String fmt(DateTime d) =>
        '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return (fmt(minD), fmt(maxD));
  }
}

// ===================== 내부 위젯 =====================

class _CyberSheetItem extends StatelessWidget {
  final String command;
  final String label;
  final bool danger;
  final VoidCallback onTap;

  const _CyberSheetItem({
    required this.command,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger
        ? CyberHistoryLayout._red
        : CyberHistoryLayout._cyan;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: danger
              ? CyberHistoryLayout._red.withValues(alpha: 0.06)
              : CyberHistoryLayout._panel,
          border: Border.all(color: accent, width: 1),
        ),
        child: Row(
          children: [
            Text(
              danger ? '!' : '>',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    command,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: accent,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w500,
                      color: danger
                          ? CyberHistoryLayout._red
                          : CyberHistoryLayout._text,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
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
      ..color = const Color(0x0A4DD0E1)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
