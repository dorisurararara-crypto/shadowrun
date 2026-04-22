import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/banner_ad_tile.dart';

/// T3 Korean Mystic 테마용 History(지난 밤들) 화면.
///
/// 구성:
///   - 상단 "← 홈" + "夜" 한자 헤더
///   - 대제목 "지난 밤들 · 四月"
///   - 월간 요약 카드 (이중 괘선 상하)
///   - 에피소드 리스트: 한자 숫자 배지 · 장소 · 한자 날짜/거리/시간 · 결과
///   - 배경 "夜"/"過" 워터마크
class MysticHistoryLayout extends StatelessWidget {
  final List<RunModel> runs;
  final void Function(RunModel run) onRunTap;
  final VoidCallback onClose;
  final void Function(RunModel run)? onRunChallenge;
  final void Function(RunModel run)? onRunEdit;
  final void Function(RunModel run)? onRunDelete;

  const MysticHistoryLayout({
    super.key,
    required this.runs,
    required this.onRunTap,
    required this.onClose,
    this.onRunChallenge,
    this.onRunEdit,
    this.onRunDelete,
  });

  // 먹빛 호러 팔레트 (mystic_home_layout 과 동일)
  static const _ink = Color(0xFF050302);
  static const _rice = Color(0xFFF0EBE3);
  static const _bloodDry = Color(0xFF7A0A0E);
  static const _bloodFresh = Color(0xFFC42029);
  static const _outline = Color(0xFF7A6858);
  static const _fade = Color(0xFF5A4840);
  static const _borderInk = Color(0xFF2A1518);

  // ---------- 한자 숫자 유틸 ----------
  static String _hanjaDigits(int n) {
    const d = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    if (n < 0) return '$n';
    if (n < 10) return d[n];
    if (n < 20) return '十${n > 10 ? d[n - 10] : ''}';
    if (n < 30) return '廿${n > 20 ? d[n - 20] : ''}';
    if (n < 40) return '卅${n > 30 ? d[n - 30] : ''}';
    if (n < 100) return '${d[n ~/ 10]}十${n % 10 > 0 ? d[n % 10] : ''}';
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  /// 한자 10진 날짜: 16 -> 十六, 3 -> 三
  static String _hanjaDay(int n) => _hanjaDigits(n);

  /// 한자 소수 거리(xx.xxkm): 3.42 -> 三·四二, 64.8 -> 六四·八
  static String _hanjaDecimal(double value, {int frac = 2}) {
    const d = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    final sign = value < 0 ? '-' : '';
    final v = value.abs();
    final fixed = v.toStringAsFixed(frac);
    final parts = fixed.split('.');
    final intPart = parts[0]
        .split('')
        .map((c) => d[int.parse(c)])
        .join();
    if (parts.length == 1 || frac == 0) return '$sign$intPart';
    final fracPart =
        parts[1].split('').map((c) => d[int.parse(c)]).join();
    return '$sign$intPart·$fracPart';
  }

  /// 한자 시간 mm:ss 혹은 h:mm:ss
  static String _hanjaDuration(int durationS) {
    const d = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    String pad2(int n) =>
        n.toString().padLeft(2, '0').split('').map((c) => d[int.parse(c)]).join();
    final h = durationS ~/ 3600;
    final m = (durationS % 3600) ~/ 60;
    final s = durationS % 60;
    if (h > 0) return '${pad2(h)}:${pad2(m)}:${pad2(s)}';
    return '${pad2(m)}:${pad2(s)}';
  }

  // ---------- 월간 집계 ----------
  List<RunModel> _runsThisMonth(DateTime now) {
    return runs.where((r) {
      final dt = DateTime.tryParse(r.date);
      if (dt == null) return false;
      return dt.year == now.year && dt.month == now.month;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthRuns = _runsThisMonth(now);
    final totalRuns = monthRuns.length;
    final totalKm = monthRuns.fold<double>(0, (a, r) => a + r.distanceM) / 1000;
    final wins = monthRuns.where((r) => r.challengeResult == 'win').length;
    final losses = monthRuns.where((r) => r.challengeResult == 'lose').length;

    return Scaffold(
      backgroundColor: _ink,
      bottomNavigationBar: const BannerAdTile(),
      body: Stack(
        children: [
          // 배경 한자 워터마크 (오른쪽 상단)
          const Positioned(
            right: -60,
            top: 60,
            child: IgnorePointer(
              child: Text(
                '夜',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 320,
                  color: Color(0x26B00A12),
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          // 배경 한자 워터마크 (왼쪽 하단)
          const Positioned(
            left: -40,
            bottom: 180,
            child: IgnorePointer(
              child: Text(
                '過',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 260,
                  color: Color(0x1C7A0A0E),
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(22, 4, 22, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(now),
                        const SizedBox(height: 18),
                        _buildMonthlySummary(
                          totalRuns: totalRuns,
                          totalKm: totalKm,
                          wins: wins,
                          losses: losses,
                        ),
                        const SizedBox(height: 22),
                        _buildSectionLabel(),
                        const SizedBox(height: 10),
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
        ],
      ),
    );
  }

  // ---------- 상단 바 "← 홈" + "夜" ----------
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 22, 6),
      child: Row(
        children: [
          InkWell(
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                '← 홈',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 13,
                  color: _rice.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const Spacer(),
          Text(
            '夜',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 18,
              color: _bloodDry,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 제목 블록 "지난 밤들 · 四月" ----------
  Widget _buildHeader(DateTime now) {
    final monthHanja = _hanjaDigits(now.month);
    final yearHanja = now.year
        .toString()
        .split('')
        .map((c) {
          const d = ['〇', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
          return d[int.parse(c)];
        })
        .join();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 부제 한자 바 (過 去)
        Text(
          '過 去',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 11,
            color: _outline,
            letterSpacing: 6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        // 지난 밤들 (나눔명조 800) + · 四月
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '지난 밤들',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 34,
                  color: _rice,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              TextSpan(
                text: '  · $monthHanja月',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 18,
                  color: _bloodDry,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'R E C O R D S  ·  $yearHanja · $monthHanja月',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 10,
            color: _outline,
            letterSpacing: 3,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ---------- 월간 요약 (이중 괘선 상하) ----------
  Widget _buildMonthlySummary({
    required int totalRuns,
    required double totalKm,
    required int wins,
    required int losses,
  }) {
    return _DoubleRulingBox(
      color: _borderInk,
      accent: _bloodDry,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '이  달  의  기  록',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 10,
              color: _outline,
              letterSpacing: 4,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${_hanjaDigits(totalRuns)} 밤',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 18,
                    color: _rice,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                TextSpan(
                  text: '  ·  ',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 18,
                    color: _fade,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextSpan(
                  text: _hanjaDecimal(
                    RunModel.useMiles ? (totalKm / 1.609344) : totalKm,
                    frac: 1,
                  ),
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 22,
                    color: _rice,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                TextSpan(
                  text: RunModel.useMiles ? ' mi' : ' km',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 11,
                    color: _outline,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_hanjaDigits(wins)} 승  ·  ${_hanjaDigits(losses)} 패',
            style: GoogleFonts.gowunBatang(
              fontSize: 12,
              color: _bloodFresh,
              fontWeight: FontWeight.w400,
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- 섹션 라벨 "─ 에피소드 ─" ----------
  Widget _buildSectionLabel() {
    return Row(
      children: [
        Text(
          '에  피  소  드',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 11,
            color: _rice.withValues(alpha: 0.85),
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(height: 1, color: _borderInk),
        ),
        const SizedBox(width: 10),
        Text(
          'E P I S O D E S',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 9,
            color: _outline,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.5,
          ),
        ),
      ],
    );
  }

  // ---------- 빈 상태 ----------
  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: Column(
        children: [
          Text(
            '기록된 밤이 없다.',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 14,
              color: _outline,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '그 놈보다 먼저 뛰어라.',
            style: GoogleFonts.gowunBatang(
              fontSize: 11,
              color: _fade,
              fontWeight: FontWeight.w400,
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
    final dateHanja = dt != null
        ? '${_hanjaDigits(dt.month)}月 ${_hanjaDay(dt.day)}日'
        : '';

    final useMi = RunModel.useMiles;
    final distPrimary = useMi ? run.distanceM / 1609.344 : run.distanceM / 1000;
    final distHanja = _hanjaDecimal(distPrimary, frac: 2);
    final distUnit = useMi ? 'mi' : 'km';
    final durHanja = _hanjaDuration(run.durationS);

    final isWin = run.challengeResult == 'win';
    final isLoss = run.challengeResult == 'lose';
    final resultLabel = isWin ? '살았다' : isLoss ? '잡혔다' : '뛰 었 다';
    final resultColor = isWin ? _rice : isLoss ? _bloodFresh : _outline;

    // 사용자 지정 이름(run.name) 우선, 없으면 자동 장소(run.location)
    final userName = run.name?.trim() ?? '';
    final autoLoc = run.location?.trim() ?? '';
    final location = userName.isNotEmpty
        ? userName
        : (autoLoc.isNotEmpty ? autoLoc : '이름 없는 길');

    return InkWell(
      onTap: () => onRunTap(run),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _borderInk, width: 0.8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 좌측 한자 숫자 배지 (네모 박스)
            _EpisodeBadge(no: episodeNo),
            const SizedBox(width: 14),
            // 중앙: 한국어 날짜 + 장소 + 한자 날짜/거리/시간
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$dateKo · $location',
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 14,
                      color: _rice,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$dateHanja  ·  $distHanja $distUnit  ·  $durHanja',
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 10.5,
                      color: _outline,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // 우측: 결과
            Text(
              resultLabel,
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 13,
                color: resultColor,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            // 우측 끝: ⋯ 액션 버튼 (수정/삭제)
            if (onRunEdit != null || onRunDelete != null || onRunChallenge != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showActionSheet(context, run),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(left: 6),
                  child: Text(
                    '⋯',
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 20,
                      color: _outline,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- 액션 바텀시트 (수정/삭제/도전) ----------
  void _showActionSheet(BuildContext context, RunModel run) {
    final isKo = S.isKo;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0D0607),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들
                Container(
                  width: 36,
                  height: 2,
                  margin: const EdgeInsets.only(top: 4, bottom: 14),
                  color: _borderInk,
                ),
                // 상단 작은 한자 라벨
                Text(
                  '選 · 択',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 10,
                    color: _outline,
                    letterSpacing: 5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 10),
                if (onRunChallenge != null)
                  _MysticSheetItem(
                    label: isKo ? '도플갱어로 도전' : 'Challenge as doppelganger',
                    hanja: '追',
                    color: _rice,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onRunChallenge!(run);
                    },
                  ),
                if (onRunEdit != null)
                  _MysticSheetItem(
                    label: isKo ? '이름 변경' : 'Rename',
                    hanja: '改',
                    color: _rice,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onRunEdit!(run);
                    },
                  ),
                if (onRunDelete != null)
                  _MysticSheetItem(
                    label: isKo ? '삭제' : 'Delete',
                    hanja: '消',
                    color: _rice,
                    dangerBg: _bloodFresh,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onRunDelete!(run);
                    },
                  ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===================== 내부 위젯 =====================

/// 이중 괘선(double ruling) 상하 박스. 월간 요약 카드용.
class _DoubleRulingBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color accent;
  final EdgeInsets padding;

  const _DoubleRulingBox({
    required this.child,
    required this.color,
    required this.accent,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 1, color: color),
        const SizedBox(height: 3),
        Container(height: 0.6, color: accent),
        Padding(padding: padding, child: child),
        Container(height: 0.6, color: accent),
        const SizedBox(height: 3),
        Container(height: 1, color: color),
      ],
    );
  }
}

/// Mystic 바텀시트 액션 아이템. dangerBg를 주면 血 배경 + 쌀빛 텍스트.
class _MysticSheetItem extends StatelessWidget {
  final String label;
  final String hanja;
  final Color color;
  final Color? dangerBg;
  final VoidCallback onTap;

  const _MysticSheetItem({
    required this.label,
    required this.hanja,
    required this.color,
    required this.onTap,
    this.dangerBg,
  });

  @override
  Widget build(BuildContext context) {
    final isDanger = dangerBg != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(18, 4, 18, 4),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: isDanger ? dangerBg : Colors.transparent,
          border: Border.all(
            color: isDanger
                ? dangerBg!
                : MysticHistoryLayout._borderInk,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                hanja,
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 18,
                  color: isDanger
                      ? MysticHistoryLayout._rice
                      : MysticHistoryLayout._bloodDry,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 14,
                  color: isDanger
                      ? MysticHistoryLayout._rice
                      : color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 에피소드 번호 배지: 네모 박스 + 상단 "제/밤" + 큰 한자 숫자
class _EpisodeBadge extends StatelessWidget {
  final int no;
  const _EpisodeBadge({required this.no});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 56,
      decoration: BoxDecoration(
        border: Border.all(
          color: MysticHistoryLayout._borderInk,
          width: 1,
        ),
        color: const Color(0xFF0D0607),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '제 / 밤',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 8,
              color: MysticHistoryLayout._fade,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            MysticHistoryLayout._hanjaDigits(no),
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 20,
              color: MysticHistoryLayout._rice,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
