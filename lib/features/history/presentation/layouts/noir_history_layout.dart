import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

/// T2 Film Noir 테마용 History(Case Archive) 화면.
///
/// 구성 (designs/full-t2-noir.html · 5) HISTORY / ARCHIVE):
///   - 상단바 "‹"(home) + "Case Archive" (Cormorant Italic) + "⌕" 검색/탭
///   - 월간 리포트 헤더 "Monthly Report / April 2026"
///   - 3열 요약 (Cases · Solved · Cold) 브래스·와인 accent
///   - 탭: ALL FILES / COLD CASES (ALL · Challenges)
///   - CASE 카드 리스트: CASE No. 배지(브래스 or 와인) + 날짜/장소/지표 + 판결 (Solved/Cold/Logged)
///   - 스와이프 삭제 · 액션 시트(도전/이름변경/삭제)
class NoirHistoryLayout extends StatefulWidget {
  final List<RunModel> runs;
  final void Function(RunModel run) onRunTap;
  final VoidCallback onClose;
  final void Function(RunModel run)? onRunChallenge;
  final void Function(RunModel run)? onRunEdit;
  final void Function(RunModel run)? onRunDelete;

  const NoirHistoryLayout({
    super.key,
    required this.runs,
    required this.onRunTap,
    required this.onClose,
    this.onRunChallenge,
    this.onRunEdit,
    this.onRunDelete,
  });

  // ── Film Noir 팔레트 (noir_home_layout 과 동일) ──
  static const _ink = Color(0xFF0D0907);
  static const _ink2 = Color(0xFF160E08);
  static const _paper = Color(0xFFE8DCC4);
  static const _paperDim = Color(0xFFA89A80);
  static const _paperFade = Color(0xFF6A5D48);
  static const _brass = Color(0xFFB89660);
  static const _brassDim = Color(0xFF8A6F48);
  static const _wine = Color(0xFF8B2635);
  static const _line = Color(0xFF2A1D10);

  @override
  State<NoirHistoryLayout> createState() => _NoirHistoryLayoutState();
}

class _NoirHistoryLayoutState extends State<NoirHistoryLayout>
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

  // ── 헬퍼: 월간 집계 ──
  List<RunModel> _monthRuns(DateTime now) {
    return widget.runs.where((r) {
      final dt = DateTime.tryParse(r.date);
      if (dt == null) return false;
      return dt.year == now.year && dt.month == now.month;
    }).toList();
  }

  List<RunModel> get _visibleRuns {
    Iterable<RunModel> src = widget.runs;
    if (_tab.index == 1) {
      src = src.where((r) => r.isChallenge);
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
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
    final now = DateTime.now();
    final monthRuns = _monthRuns(now);
    final solved = monthRuns.where((r) => r.challengeResult == 'win').length;
    final cold = monthRuns.where((r) => r.challengeResult == 'lose').length;

    return Scaffold(
      backgroundColor: NoirHistoryLayout._ink,
      bottomNavigationBar: const BannerAdTile(),
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _archHead(now, monthRuns.length, solved, cold),
                          const SizedBox(height: 18),
                          _tabs(),
                          const SizedBox(height: 8),
                          if (_searchOpen) _searchField(),
                        ],
                      ),
                    ),
                  ),
                  if (_visibleRuns.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _empty(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
                      sliver: SliverList.builder(
                        itemCount: _visibleRuns.length,
                        itemBuilder: (context, i) {
                          final r = _visibleRuns[i];
                          final caseNo = r.id ?? (widget.runs.length - i);
                          return _caseItem(r, caseNo);
                        },
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

  // ── 상단 바 ──
  Widget _topBar() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: NoirHistoryLayout._line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onClose,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '‹',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 26,
                  color: NoirHistoryLayout._brass,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                S.isKo ? 'Case Archive' : 'Case Archive',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                  color: NoirHistoryLayout._paper,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
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
              padding: const EdgeInsets.all(8),
              child: Text(
                '⌕',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  color: _searchOpen
                      ? NoirHistoryLayout._brass
                      : NoirHistoryLayout._paperDim,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Monthly Report 헤더 ──
  Widget _archHead(DateTime now, int cases, int solved, int cold) {
    const monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border:
                      Border.all(color: NoirHistoryLayout._brass, width: 1),
                ),
                child: Text(
                  S.isKo ? '월간 리포트' : 'MONTHLY REPORT',
                  style: GoogleFonts.oswald(
                    fontSize: 9,
                    color: NoirHistoryLayout._brass,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _todayEn(),
                style: GoogleFonts.oswald(
                  fontSize: 9,
                  color: NoirHistoryLayout._paperFade,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            S.isKo
                ? '${_hanjaOrNumMonth(now.month)} ${now.year}년'
                : '${monthsEn[now.month - 1]} ${now.year}',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 30,
              fontStyle: FontStyle.italic,
              color: NoirHistoryLayout._paper,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.isKo
                ? '— 사건 기록부 · 보관 중 —'
                : '— CASE LEDGER · ON FILE —',
            style: GoogleFonts.oswald(
              fontSize: 9,
              color: NoirHistoryLayout._wine,
              letterSpacing: 3.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          // 3열 요약 (Cases · Solved · Cold)
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: NoirHistoryLayout._line, width: 1),
                bottom: BorderSide(color: NoirHistoryLayout._line, width: 1),
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: _sumCell(
                    value: '$cases',
                    label: S.isKo ? '사건' : 'CASES',
                    color: NoirHistoryLayout._paper,
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: NoirHistoryLayout._line,
                ),
                Expanded(
                  child: _sumCell(
                    value: '$solved',
                    label: S.isKo ? '해결' : 'SOLVED',
                    color: NoirHistoryLayout._brass,
                  ),
                ),
                Container(
                  width: 1,
                  height: 44,
                  color: NoirHistoryLayout._line,
                ),
                Expanded(
                  child: _sumCell(
                    value: '$cold',
                    label: S.isKo ? '미해결' : 'COLD',
                    color: NoirHistoryLayout._wine,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sumCell({
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontStyle: FontStyle.italic,
            color: color,
            fontWeight: FontWeight.w700,
            height: 1,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 9,
            color: NoirHistoryLayout._paperFade,
            letterSpacing: 3,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ── 탭 (ALL · COLD) ──
  Widget _tabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: NoirHistoryLayout._line, width: 1),
        ),
      ),
      child: Row(
        children: [
          _tabItem(0, S.isKo ? '전체' : 'ALL FILES'),
          _tabItem(1, S.isKo ? '도전' : 'CHALLENGES'),
        ],
      ),
    );
  }

  Widget _tabItem(int i, String label) {
    final active = _tab.index == i;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _tab.index = i),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color:
                    active ? NoirHistoryLayout._brass : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.oswald(
              fontSize: 10,
              color: active
                  ? NoirHistoryLayout._brass
                  : NoirHistoryLayout._paperFade,
              letterSpacing: 4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  // ── 검색 필드 ──
  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: NoirHistoryLayout._ink2,
          border:
              Border.all(color: NoirHistoryLayout._brassDim, width: 0.8),
        ),
        child: Row(
          children: [
            Text(
              '⌕',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                color: NoirHistoryLayout._brass,
                fontWeight: FontWeight.w500,
                height: 1,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                cursorColor: NoirHistoryLayout._brass,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  color: NoirHistoryLayout._paper,
                  fontStyle: FontStyle.italic,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: S.isKo ? '파일·장소·날짜' : 'case · place · date',
                  hintStyle: GoogleFonts.cormorantGaramond(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: NoirHistoryLayout._paperFade,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 빈 상태 ──
  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: NoirHistoryLayout._wine, width: 1),
              ),
              child: Transform.rotate(
                angle: -0.05,
                child: Text(
                  S.isKo ? '파일 없음' : 'NO FILE',
                  style: GoogleFonts.oswald(
                    fontSize: 10,
                    color: NoirHistoryLayout._wine,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              S.isKo ? '사건 기록 없음.' : 'no case on file.',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontStyle: FontStyle.italic,
                color: NoirHistoryLayout._paperDim,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              S.isKo ? '오늘 밤, 첫 사건을 열어라.' : 'Open the first file tonight.',
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: NoirHistoryLayout._paperFade,
                letterSpacing: 3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Case row ──
  Widget _caseItem(RunModel r, int caseNo) {
    final isWin = r.challengeResult == 'win';
    final isLoss = r.challengeResult == 'lose';
    final badgeColor =
        isLoss ? NoirHistoryLayout._wine : NoirHistoryLayout._brass;
    final verdict = isWin
        ? (S.isKo ? '해결' : 'Solved')
        : isLoss
            ? (S.isKo ? '미해결' : 'Cold')
            : (S.isKo ? '기록' : 'Logged');
    final verdictColor = isLoss
        ? NoirHistoryLayout._wine
        : (isWin ? NoirHistoryLayout._brass : NoirHistoryLayout._paperDim);
    final gap = (r.finalShadowGapM ?? 0).toInt();
    final gapText = r.isChallenge
        ? (gap >= 0 ? '+${gap}m' : '${gap}m')
        : r.formattedDistance;

    final name = r.name?.trim() ?? '';
    final loc = r.location?.trim() ?? '';
    final locText = name.isNotEmpty
        ? name
        : (loc.isNotEmpty ? loc : (S.isKo ? '미식별 장소' : 'unmarked location'));

    final dt = DateTime.tryParse(r.date);
    final dateTitle = dt == null
        ? r.date
        : (S.isKo ? _dateKo(dt) : _dateEnLong(dt));
    final pace = r.formattedPace;

    return Dismissible(
      key: ValueKey('noir-${r.id ?? r.date}'),
      direction: widget.onRunDelete == null
          ? DismissDirection.none
          : DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: NoirHistoryLayout._wine.withValues(alpha: 0.18),
          border:
              Border.all(color: NoirHistoryLayout._wine, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.delete_outline,
              size: 16,
              color: NoirHistoryLayout._wine,
            ),
            const SizedBox(width: 6),
            Text(
              S.isKo ? '폐기' : 'DESTROY',
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: NoirHistoryLayout._wine,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
              ),
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
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: NoirHistoryLayout._line, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Case badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  border: Border.all(color: badgeColor, width: 1),
                  color: NoirHistoryLayout._ink2,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CASE',
                      style: GoogleFonts.oswald(
                        fontSize: 7.5,
                        color: badgeColor,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _pad3(caseNo),
                      style: GoogleFonts.oswald(
                        fontSize: 14,
                        color: badgeColor,
                        fontWeight: FontWeight.w600,
                        height: 1,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateTitle,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: NoirHistoryLayout._paper,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      locText,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: NoirHistoryLayout._paperDim,
                        fontWeight: FontWeight.w400,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${r.formattedDistance} · ${r.formattedDuration} · avg $pace',
                      style: GoogleFonts.oswald(
                        fontSize: 9,
                        color: NoirHistoryLayout._paperFade,
                        letterSpacing: 2.2,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Verdict
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    verdict,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: verdictColor,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gapText,
                    style: GoogleFonts.oswald(
                      fontSize: 10,
                      color: isLoss
                          ? NoirHistoryLayout._wine
                          : NoirHistoryLayout._paperDim,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // 액션 버튼
              if (widget.onRunEdit != null ||
                  widget.onRunDelete != null ||
                  widget.onRunChallenge != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showActionSheet(r),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    margin: const EdgeInsets.only(left: 4),
                    child: Text(
                      '⋯',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 20,
                        color: NoirHistoryLayout._paperFade,
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

  // ── 액션 바텀시트 ──
  void _showActionSheet(RunModel run) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NoirHistoryLayout._ink,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 1,
                  margin: const EdgeInsets.only(top: 2, bottom: 14),
                  color: NoirHistoryLayout._brassDim,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: NoirHistoryLayout._brass,
                          width: 1,
                        ),
                      ),
                    ),
                    Text(
                      S.isKo ? '조치' : 'DISPOSITION',
                      style: GoogleFonts.oswald(
                        fontSize: 10,
                        color: NoirHistoryLayout._brass,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: NoirHistoryLayout._brass,
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (widget.onRunChallenge != null)
                  _NoirSheetItem(
                    label: S.isKo
                        ? '도플갱어로 도전'
                        : 'Challenge as doppelganger',
                    mark: 'CHASE',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      widget.onRunChallenge!(run);
                    },
                  ),
                if (widget.onRunEdit != null)
                  _NoirSheetItem(
                    label: S.isKo ? '사건명 변경' : 'Rename case',
                    mark: 'RE-FILE',
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      widget.onRunEdit!(run);
                    },
                  ),
                if (widget.onRunDelete != null)
                  _NoirSheetItem(
                    label: S.isKo ? '파일 파기' : 'Destroy file',
                    mark: 'BURN',
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

  String _dateKo(DateTime dt) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${dt.month}월 ${dt.day}일 · ${weekdays[dt.weekday - 1]}';
  }

  String _dateEnLong(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${months[dt.month - 1]} ${dt.day} · ${weekdays[dt.weekday - 1]}';
  }

  String _todayEn() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]} · ${months[now.month - 1]} ${now.day}';
  }

  String _hanjaOrNumMonth(int m) {
    // 한국어 표시: "4월" 형식
    return '$m월';
  }
}

// ===================== 내부 위젯 =====================

class _NoirSheetItem extends StatelessWidget {
  final String label;
  final String mark;
  final bool danger;
  final VoidCallback onTap;

  const _NoirSheetItem({
    required this.label,
    required this.mark,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        danger ? NoirHistoryLayout._wine : NoirHistoryLayout._brass;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1),
          color: NoirHistoryLayout._ink2,
        ),
        child: Row(
          children: [
            Transform.rotate(
              angle: -0.04,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(color: color, width: 1),
                ),
                child: Text(
                  mark,
                  style: GoogleFonts.oswald(
                    fontSize: 8.5,
                    color: color,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: danger
                      ? NoirHistoryLayout._wine
                      : NoirHistoryLayout._paper,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              '›',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                color: color,
                fontWeight: FontWeight.w400,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
