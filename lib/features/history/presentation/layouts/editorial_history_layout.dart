import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

/// T4 Editorial Thriller 테마용 History(The Archive) 화면.
///
/// 구성 (designs/full-t4-editorial.html · 5. HISTORY / ARCHIVE):
///   - pagehead: "Archive · P. 05 / 2026 / shadowrun · history"
///   - "All Issues" eyebrow (red italic) + "The Archive · 2026" issue
///   - rule-thick(white 2px)
///   - huge title "The\nArchive." (Archive는 red italic)
///   - deck: "All issues · filed by month · back to January"
///   - summary 3열: Issues / Distance / Score
///   - 월별 묶음 라벨: "April 2026 · 12 Issues"
///   - arc-row: No.028 · 제목(italic red 강조) · 날짜·거리 · ESCAPED/CAUGHT 뱃지
///   - 하단 quote "어떤 밤은 이기고..."
class EditorialHistoryLayout extends StatefulWidget {
  final List<RunModel> runs;
  final void Function(RunModel run) onRunTap;
  final VoidCallback onClose;
  final void Function(RunModel run)? onRunChallenge;
  final void Function(RunModel run)? onRunEdit;
  final void Function(RunModel run)? onRunDelete;

  const EditorialHistoryLayout({
    super.key,
    required this.runs,
    required this.onRunTap,
    required this.onClose,
    this.onRunChallenge,
    this.onRunEdit,
    this.onRunDelete,
  });

  // Editorial 팔레트 (editorial_home_layout 과 동일)
  static const _ink = Color(0xFF0A0A0A);
  static const _white = Color(0xFFFFFFFF);
  static const _red = Color(0xFFDC2626);
  static const _redSoft = Color(0xFFF87171);
  static const _muted = Color(0xFF888888);
  static const _mutedDim = Color(0xFF555555);
  static const _hair = Color(0x1FFFFFFF);
  static const _hairLow = Color(0x14FFFFFF);

  @override
  State<EditorialHistoryLayout> createState() =>
      _EditorialHistoryLayoutState();
}

class _EditorialHistoryLayoutState extends State<EditorialHistoryLayout>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();
  bool _searchOpen = false;

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
    if (_tab.index == 1) {
      src = src.where((r) => r.isChallenge);
    }
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      src = src.where((r) {
        final n = (r.name ?? '').toLowerCase();
        final l = (r.location ?? '').toLowerCase();
        return n.contains(q) || l.contains(q) || r.date.contains(q);
      });
    }
    return src.toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleRuns;
    final grouped = _groupByMonth(visible);
    final monthKeysSorted = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final totalCount = widget.runs.length;
    final totalKm =
        widget.runs.fold<double>(0, (a, r) => a + r.distanceM) / 1000;
    final wins =
        widget.runs.where((r) => r.challengeResult == 'win').length;
    final losses =
        widget.runs.where((r) => r.challengeResult == 'lose').length;

    return Scaffold(
      backgroundColor: EditorialHistoryLayout._ink,
      bottomNavigationBar: const BannerAdTile(),
      body: Stack(
        children: [
          const Positioned.fill(child: _Grain()),
          SafeArea(
            child: Column(
              children: [
                _topBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(24, 4, 24, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _pagehead(),
                        const SizedBox(height: 10),
                        _edNo(),
                        const SizedBox(height: 3),
                        _edIssue(),
                        const SizedBox(height: 8),
                        Container(
                          height: 2,
                          color: EditorialHistoryLayout._white,
                        ),
                        const SizedBox(height: 12),
                        _hugeTitle(),
                        const SizedBox(height: 8),
                        _deck(),
                        const SizedBox(height: 16),
                        _summary(totalCount, totalKm, wins, losses),
                        const SizedBox(height: 16),
                        _tabs(),
                        if (_searchOpen) ...[
                          const SizedBox(height: 10),
                          _searchField(),
                        ],
                        const SizedBox(height: 14),
                        if (visible.isEmpty)
                          _empty()
                        else
                          for (final key in monthKeysSorted) ...[
                            _monthLabel(key, grouped[key]!.length),
                            for (int i = 0; i < grouped[key]!.length; i++)
                              _arcRow(
                                grouped[key]![i],
                                issueNo: grouped[key]![i].id ??
                                    (widget.runs.length -
                                        widget.runs.indexOf(grouped[key]![i])),
                              ),
                            const SizedBox(height: 14),
                          ],
                        _mastFootPrint(),
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

  // ── pagehead / pagination ──
  Widget _pagehead() {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: EditorialHistoryLayout._hair, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Archive · P. 05',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF7A7A7F),
              letterSpacing: 3.5,
            ),
          ),
          const Spacer(),
          Text(
            '${DateTime.now().year}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: EditorialHistoryLayout._redSoft,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            'SHADOWRUN/HISTORY',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              color: const Color(0xFF7A7A7F),
              letterSpacing: 3.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _edNo() {
    return Text(
      S.isKo ? '전체 호' : 'All Issues',
      style: GoogleFonts.playfairDisplay(
        fontSize: 11,
        fontStyle: FontStyle.italic,
        color: EditorialHistoryLayout._red,
        letterSpacing: 2.2,
      ),
    );
  }

  Widget _edIssue() {
    return Text(
      S.isKo
          ? '기록 보관함 · ${DateTime.now().year}'
          : 'The Archive · ${DateTime.now().year}',
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w200,
        color: const Color(0xFF888888),
        letterSpacing: 3.2,
      ),
    );
  }

  // ── HUGE title ──
  Widget _hugeTitle() {
    final t1 = S.isKo ? '기록\n' : 'The\n';
    final t2 = S.isKo ? '보관함' : 'Archive';
    return RichText(
      text: TextSpan(
        style: GoogleFonts.playfairDisplay(
          fontSize: 58,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          color: EditorialHistoryLayout._white,
          height: 0.9,
          letterSpacing: -2.8,
        ),
        children: [
          TextSpan(text: t1),
          TextSpan(
            text: t2,
            style: TextStyle(
              color: EditorialHistoryLayout._red,
              fontStyle: FontStyle.italic,
              fontSize: 58,
              fontWeight: FontWeight.w900,
              height: 0.9,
              letterSpacing: -2.8,
              fontFamily: GoogleFonts.playfairDisplay().fontFamily,
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _deck() {
    return Text(
      S.isKo
          ? '모든 호 · 월별 정리 · 첫 호까지'
          : 'All issues · filed by month · back to January',
      style: GoogleFonts.playfairDisplay(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: const Color(0xFFAAAAAA),
        fontWeight: FontWeight.w400,
        letterSpacing: 0.2,
      ),
    );
  }

  // ── Summary row ──
  Widget _summary(int issues, double km, int wins, int losses) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: EditorialHistoryLayout._hair, width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _sumCell(
              label: S.isKo ? '호' : 'ISSUES',
              value: '$issues',
              unit: '',
            ),
          ),
          Container(
            width: 1,
            height: 46,
            color: EditorialHistoryLayout._hair,
          ),
          Expanded(
            child: _sumCell(
              label: S.isKo ? '거리' : 'DISTANCE',
              value: RunModel.useMiles
                  ? (km / 1.609344).toStringAsFixed(1)
                  : km.toStringAsFixed(1),
              unit: RunModel.useMiles ? 'mi' : 'km',
            ),
          ),
          Container(
            width: 1,
            height: 46,
            color: EditorialHistoryLayout._hair,
          ),
          Expanded(
            child: _sumCell(
              label: S.isKo ? '전적' : 'SCORE',
              value: '$wins',
              unit: ':$losses',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumCell({
    required String label,
    required String value,
    required String unit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
                    fontSize: 26,
                    fontStyle: FontStyle.italic,
                    color: EditorialHistoryLayout._white,
                    height: 1,
                    letterSpacing: -0.6,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: EditorialHistoryLayout._redSoft,
                      letterSpacing: 0.8,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs (ALL · CHALLENGES) ──
  Widget _tabs() {
    return Row(
      children: [
        _tabItem(0, S.isKo ? '전체' : 'ALL'),
        const SizedBox(width: 16),
        _tabItem(1, S.isKo ? '도전' : 'CHALLENGES'),
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
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  size: 14,
                  color: _searchOpen
                      ? EditorialHistoryLayout._red
                      : EditorialHistoryLayout._muted,
                ),
                const SizedBox(width: 5),
                Text(
                  S.isKo ? '검색' : 'search',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: _searchOpen
                        ? EditorialHistoryLayout._red
                        : EditorialHistoryLayout._muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tabItem(int i, String label) {
    final active = _tab.index == i;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _tab.index = i),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active
                  ? EditorialHistoryLayout._red
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  '◆',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: EditorialHistoryLayout._red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: active
                    ? EditorialHistoryLayout._red
                    : EditorialHistoryLayout._muted,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchField() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: EditorialHistoryLayout._white, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            '◆',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: EditorialHistoryLayout._red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              cursorColor: EditorialHistoryLayout._red,
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: EditorialHistoryLayout._white,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                hintText: S.isKo ? '호·제목·날짜…' : 'issue · title · date…',
                hintStyle: GoogleFonts.playfairDisplay(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: EditorialHistoryLayout._mutedDim,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Month label ──
  Widget _monthLabel(String monthKey, int count) {
    // monthKey: YYYY-MM
    final parts = monthKey.split('-');
    final year = parts.isNotEmpty ? parts[0] : '';
    final mo = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthEn = mo >= 1 && mo <= 12 ? months[mo - 1] : '';
    final title = S.isKo ? '$mo월 $year · $count호' : '$monthEn $year · $count Issues';
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      padding: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: EditorialHistoryLayout._hair, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '◆',
            style: GoogleFonts.inter(
              fontSize: 9,
              color: EditorialHistoryLayout._red,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: EditorialHistoryLayout._red,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Arc row ──
  Widget _arcRow(RunModel r, {required int issueNo}) {
    final isWin = r.challengeResult == 'win';
    final isLoss = r.challengeResult == 'lose';
    final gap = (r.finalShadowGapM ?? 0).toInt();
    final status = isWin
        ? (S.isKo ? '탈출' : 'ESCAPED')
        : isLoss
            ? (S.isKo ? '잡힘' : 'CAUGHT')
            : (S.isKo ? '완주' : 'LOGGED');
    final gapText = r.isChallenge
        ? (gap >= 0 ? '+${_pad3(gap)}m' : '−${_pad3(gap.abs())}m')
        : r.formattedDistance;
    final name = r.name?.trim() ?? '';
    final loc = r.location?.trim() ?? '';
    final (head, emphasis) = _splitTitle(name, loc);
    final dateStr = _dateShort(r.date);

    return Dismissible(
      key: ValueKey('ed-${r.id ?? r.date}'),
      direction: widget.onRunDelete == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: EditorialHistoryLayout._red,
        child: Text(
          S.isKo ? '호 폐간 →' : '→ RETIRE ISSUE',
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: EditorialHistoryLayout._white,
            letterSpacing: 2.5,
          ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom:
                  BorderSide(color: EditorialHistoryLayout._hairLow),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 번호 No. 028
              SizedBox(
                width: 52,
                child: Text(
                  _pad3(issueNo),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontStyle: FontStyle.italic,
                    color: EditorialHistoryLayout._mutedDim,
                    height: 1,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          color: EditorialHistoryLayout._white,
                          height: 1.15,
                        ),
                        children: [
                          TextSpan(text: head),
                          if (emphasis.isNotEmpty) ...[
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: emphasis,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: EditorialHistoryLayout._red,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$dateStr · ${r.formattedDistance} · ${r.formattedDuration}',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w300,
                        color: EditorialHistoryLayout._muted,
                        letterSpacing: 2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Status badge + gap
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isLoss
                          ? EditorialHistoryLayout._mutedDim
                          : EditorialHistoryLayout._red,
                      letterSpacing: 2.8,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    gapText,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w700,
                      color: isLoss
                          ? EditorialHistoryLayout._mutedDim
                          : EditorialHistoryLayout._red,
                      letterSpacing: -0.2,
                      decoration: isLoss
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor:
                          EditorialHistoryLayout._mutedDim,
                    ),
                  ),
                ],
              ),
              if (widget.onRunEdit != null ||
                  widget.onRunDelete != null ||
                  widget.onRunChallenge != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showActionSheet(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    margin: const EdgeInsets.only(left: 4),
                    child: Text(
                      '⋯',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontStyle: FontStyle.italic,
                        color: EditorialHistoryLayout._muted,
                        fontWeight: FontWeight.w600,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontStyle: FontStyle.italic,
                color: EditorialHistoryLayout._white,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              children: [
                TextSpan(text: S.isKo ? '아직 ' : 'No issues '),
                TextSpan(
                  text: S.isKo ? '첫 호' : 'yet',
                  style: const TextStyle(color: EditorialHistoryLayout._red),
                ),
                TextSpan(text: S.isKo ? '가 없다.' : '.'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            S.isKo
                ? '오늘 밤, 창간호를 기록하라.'
                : 'File the inaugural issue tonight.',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: EditorialHistoryLayout._muted,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer quote ──
  Widget _mastFootPrint() {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: EditorialHistoryLayout._hair, width: 1),
          ),
        ),
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          S.isKo
              ? '"어떤 밤은 이기고, 어떤 밤은 진다. 모든 밤은 기록된다."'
              : '"Some nights you win. Some you lose. Every night is filed."',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: EditorialHistoryLayout._mutedDim,
            fontWeight: FontWeight.w400,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ── Top bar ──
  Widget _topBar() {
    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: widget.onClose,
              child: Row(
                children: [
                  Text(
                    '←',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: EditorialHistoryLayout._white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.isKo ? 'Cover' : 'cover',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: EditorialHistoryLayout._white,
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ── Action sheet ──
  void _showActionSheet(RunModel run) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: EditorialHistoryLayout._ink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 2,
                  width: double.infinity,
                  color: EditorialHistoryLayout._white,
                ),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    S.isKo ? '◆ 편집 · 교정' : '◆ EDITORIAL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: EditorialHistoryLayout._red,
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.onRunChallenge != null)
                  _EditorialSheetItem(
                    title: S.isKo
                        ? '도플갱어로 재연재'
                        : 'Re-run as doppelganger',
                    tag: S.isKo ? '속편' : 'SEQUEL',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      widget.onRunChallenge!(run);
                    },
                  ),
                if (widget.onRunEdit != null)
                  _EditorialSheetItem(
                    title: S.isKo ? '제목 교정' : 'Edit headline',
                    tag: S.isKo ? '교정' : 'EDIT',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      widget.onRunEdit!(run);
                    },
                  ),
                if (widget.onRunDelete != null)
                  _EditorialSheetItem(
                    title: S.isKo ? '호 폐간' : 'Retire issue',
                    tag: S.isKo ? '폐간' : 'RETIRE',
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
  Map<String, List<RunModel>> _groupByMonth(List<RunModel> list) {
    final out = <String, List<RunModel>>{};
    for (final r in list) {
      final dt = DateTime.tryParse(r.date);
      if (dt == null) continue;
      final key =
          '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}';
      out.putIfAbsent(key, () => []).add(r);
    }
    return out;
  }

  (String head, String emphasis) _splitTitle(String name, String loc) {
    final source = name.isNotEmpty
        ? name
        : (loc.isNotEmpty
            ? loc
            : (S.isKo ? '이름 없는 밤' : 'Unmarked Night'));
    // 마지막 단어(한글·영문 공통)를 italic red emphasis로.
    final parts = source.split(' ');
    if (parts.length >= 2) {
      final last = parts.removeLast();
      return (parts.join(' '), last);
    }
    // 한 단어면 전체를 head로, emphasis는 빈값 → 그냥 head 만.
    return (source, '');
  }

  static String _pad3(int n) => n.toString().padLeft(3, '0');

  static String _dateShort(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
  }
}

// ===================== 내부 위젯 =====================

class _EditorialSheetItem extends StatelessWidget {
  final String title;
  final String tag;
  final bool danger;
  final VoidCallback onTap;

  const _EditorialSheetItem({
    required this.title,
    required this.tag,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = danger
        ? EditorialHistoryLayout._red
        : EditorialHistoryLayout._white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom:
                BorderSide(color: EditorialHistoryLayout._hairLow),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: danger
                    ? EditorialHistoryLayout._red
                    : Colors.transparent,
                border: Border.all(color: accent, width: 1),
              ),
              child: Text(
                tag,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  color: danger
                      ? EditorialHistoryLayout._white
                      : accent,
                  letterSpacing: 2.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                  color: danger
                      ? EditorialHistoryLayout._red
                      : EditorialHistoryLayout._white,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Text(
              '›',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
