import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/shared/widgets/bgm_toggle_button.dart';
import 'package:shadowrun/shared/widgets/challenge_run_picker.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class MysticHomeLayout extends StatelessWidget {
  final Future<Map<String, dynamic>> statsFuture;
  final Future<List<RunModel>> runsFuture;
  final VoidCallback onRefresh;

  const MysticHomeLayout({
    super.key,
    required this.statsFuture,
    required this.runsFuture,
    required this.onRefresh,
  });

  static const _ink = Color(0xFF050302);
  static const _rice = Color(0xFFF0EBE3);
  static const _bloodDry = Color(0xFF7A0A0E);
  static const _bloodFresh = Color(0xFFC42029);
  static const _outline = Color(0xFF7A6858);
  static const _fade = Color(0xFF5A4840);
  static const _borderInk = Color(0xFF2A1518);

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

  static String _korWordsUnder1000(int n) {
    // 1000+ 또는 음수는 숫자 그대로 (함수명 그대로 1000 미만만 한글 표기)
    if (n < 0 || n >= 1000) return '$n';
    const units = ['', '일', '이', '삼', '사', '오', '육', '칠', '팔', '구'];
    const tens = ['', '열', '스물', '서른', '마흔', '쉰', '예순', '일흔', '여든', '아흔'];
    const teens = ['열', '열한', '열두', '열세', '열네', '열다섯', '열여섯', '열일곱', '열여덟', '열아홉'];
    const tens2 = ['', '', '스물', '서른', '마흔', '쉰', '예순', '일흔', '여든', '아흔'];
    const ones2 = ['', '한', '두', '세', '네', '다섯', '여섯', '일곱', '여덟', '아홉'];
    String sub2(int x) {
      if (x == 0) return '';
      if (x < 10) return ones2[x];
      if (x < 20) return teens[x - 10];
      return '${tens2[x ~/ 10]}${x % 10 > 0 ? ones2[x % 10] : ''}';
    }
    if (n < 100) {
      if (n == 0) return '영';
      if (n < 10) return ones2[n];
      if (n < 20) return teens[n - 10];
      return '${tens[n ~/ 10]}${n % 10 > 0 ? ones2[n % 10] : ''}';
    }
    final h = n ~/ 100;
    final rest = n % 100;
    final hundred = '${h == 1 ? '' : units[h]}백';
    return rest > 0 ? '$hundred ${sub2(rest)}' : hundred;
  }

  /// 어제 러닝 결과 → 3줄 시적 카피 (Mystic 톤: 한국 민속 호러).
  /// [line1, highlight, line3] 반환. 승/패·모드별 분기.
  List<String> _narrativeLines(RunModel? last) {
    final ko = S.isKo;
    if (last == null) {
      return ko
          ? ['그 놈은', '당신을', '기다린다.']
          : ['The shadow', 'waits', 'for you.'];
    }
    if (last.isChallenge) {
      final r = last.challengeResult;
      // 최종 간격(finalShadowGapM) 우선.
      final gap = (last.finalShadowGapM ?? 0).abs().toInt();
      if (r == 'lose') {
        return ko
            ? ['어젯밤, 그 놈이', '너의 숨을', '먹었다.']
            : ['Last night, he', 'took', 'your breath.'];
      }
      if (r == 'win') {
        if (gap >= 500) {
          final words = ko ? _korWordsUnder1000(gap.clamp(0, 999)) : '$gap';
          return ko
              ? ['어젯밤, 그 놈을', '$words 걸음', '밖에 두었다.']
              : ['Last night,', '${gap}m', 'left behind.'];
        }
        if (gap >= 100) {
          final words = ko ? _korWordsUnder1000(gap.clamp(0, 999)) : '$gap';
          return ko
              ? ['어젯밤, 그 놈을', '$words 걸음', '앞서 벗어났다.']
              : ['Last night,', '${gap}m', 'escaped.'];
        }
        return ko
            ? ['어젯밤,', '간신히', '빠져나왔다.']
            : ['Last night,', 'just barely,', 'you slipped free.'];
      }
    }
    // 자유 · 마라톤
    final km = (last.distanceM / 1000).toStringAsFixed(1);
    return ko
        ? ['어제의', '${km}km', '발걸음.']
        : ['Yesterday', '${km}km', 'of footfalls.'];
  }

  @override
  Widget build(BuildContext context) {
    // codex 진단 반영: Stack 기본 fit:loose 때문에 non-positioned SingleChildScrollView의
    // hit test가 깨져 자식 GestureDetector가 탭을 못 받음.
    // 해결: SingleChildScrollView(+RefreshIndicator)를 Positioned.fill로 감싸 전체 크기 보장.
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          // 배경 한자 워터마크 (오른쪽 상단)
          const Positioned(
            right: -60,
            top: 60,
            child: IgnorePointer(
              child: Text(
                '影',
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
                '追',
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

          Positioned.fill(
            child: RefreshIndicator(
              color: _bloodFresh,
              backgroundColor: _ink,
              onRefresh: () async => onRefresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 24,
                  left: 22,
                  right: 22,
                  bottom: 32,
                ),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: statsFuture,
                  builder: (context, statsSnap) {
                    final stats = statsSnap.data ?? const {};
                    final totalRuns = (stats['totalRuns'] ?? 0) as int;
                    final totalDistanceM = ((stats['totalDistanceM'] ?? 0.0) as num).toDouble();
                    final weeklyKm = (totalDistanceM / 1000);
                    return FutureBuilder<List<RunModel>>(
                      future: runsFuture,
                      builder: (context, runsSnap) {
                        final runs = runsSnap.data ?? const <RunModel>[];
                        final lastRun = runs.isNotEmpty ? runs.first : null;
                        final bestEscape = runs.isEmpty
                            ? 0
                            : runs.map((r) => r.distanceM.toInt()).reduce((a, b) => a > b ? a : b);
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
    final now = DateTime.now();
    // 曜日: 月 火 水 木 金 土 日 (전통 한자 요일)
    const weekDaysHanja = ['月', '火', '水', '木', '金', '土', '日'];
    const weekDaysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthsEn = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final weekdayHanja = weekDaysHanja[(now.weekday - 1).clamp(0, 6)];
    final dateHanja = '${_hanjaDigits(now.month)}月${_hanjaDigits(now.day)}日';
    final weekdayEn = weekDaysEn[(now.weekday - 1).clamp(0, 6)];
    final dateEn = '${monthsEn[(now.month - 1).clamp(0, 11)]} ${now.day}';
    final dateLine = S.isKo
        ? '$weekdayHanja曜日 · $dateHanja'
        : '$weekdayEn · $dateEn';
    // "제 005 밤" 이 무슨 뜻인지 불명확하다는 사용자 피드백 반영:
    // padding 제거 + "N번째 달리기"로 의미 명확화.
    final runCount = totalRuns + 1;
    final episodeLabel = S.isKo
        ? '$runCount번째 달리기'
        : 'Your run #$runCount';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 상단 한자 헤더 + 우측 BGM 토글
        Row(
          children: [
            const SizedBox(width: 44), // 좌우 대칭용 여백
            Expanded(
              child: Center(
                child: Text(
                  '影      追      夜',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 15,
                    color: _bloodDry,
                    letterSpacing: 8,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            BgmToggleButton(color: _bloodDry),
          ],
        ),
        const SizedBox(height: 22),

        // 쉐도우런 큰 제목
        Center(
          child: Text(
            S.isKo ? '쉐도우런' : 'Shadow Run',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 46,
              color: _rice,
              height: 1.0,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // SHADOW RUN 영문 서브
        Center(
          child: Text(
            'S H A D O W   R U N',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 11,
              color: _outline,
              letterSpacing: 4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 태그라인
        Center(
          child: Text(
            S.isKo
                ? '— 그림자는 쉬지 않는다 —'
                : '— The shadow never rests —',
            style: GoogleFonts.gowunBatang(
              fontSize: 13,
              color: _bloodFresh,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 에피소드 번호
        Center(
          child: Text(
            episodeLabel,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 13,
              color: _rice.withValues(alpha: 0.8),
              letterSpacing: 4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 4),

        // 요일 · 날짜 (한국어: 金曜日 · 四月十七日 / 영문: Fri · Apr 17)
        Center(
          child: Text(
            dateLine,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 11,
              color: _fade,
              letterSpacing: 4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 30),

        // 코너 꺾쇠 장식 박스 (인용구)
        _quoteBlock(lastRun: lastRun),

        const SizedBox(height: 28),

        // 구분선: "─ 지난 밤의 기록 ─"
        Center(
          child: Text(
            S.isKo
                ? '─   지난 밤의 기록   ─'
                : '─   Chronicles of past nights   ─',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 11,
              color: _outline,
              letterSpacing: 3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 통계 3칸
        _statsRow(weeklyKm: weeklyKm, totalRuns: totalRuns, bestEscapeM: bestEscapeM),

        const SizedBox(height: 28),

        // 시작 카드 2종: 도플갱어 추격(=챌린지) + 새 기록(=자유/전설)
        _doppelgangerCard(context),
        const SizedBox(height: 12),
        _newRecordCard(context),

        const SizedBox(height: 28),

        // 최근 러닝 제목
        if (runs.isNotEmpty) ...[
          Text(
            S.isKo
                ? '─   최근 세 밤   ─'
                : '─   Recent Three Nights   ─',
            textAlign: TextAlign.center,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 11,
              color: _outline,
              letterSpacing: 3,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          for (final r in runs) _recentRow(r),
        ],
      ],
    );
  }

  Widget _quoteBlock({required RunModel? lastRun}) {
    final parts = _narrativeLines(lastRun);
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 좌상 꺾쇠
            Positioned(
              left: 0,
              top: 0,
              child: CustomPaint(
                size: const Size(18, 18),
                painter: _CornerPainter(_bloodFresh, topLeft: true),
              ),
            ),
            // 우하 꺾쇠
            Positioned(
              right: 0,
              bottom: 0,
              child: CustomPaint(
                size: const Size(18, 18),
                painter: _CornerPainter(_bloodFresh, topLeft: false),
              ),
            ),
            // 본문 — 명시적 중앙 정렬 보장
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    parts.isNotEmpty ? parts[0] : '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 16,
                      color: _rice,
                      height: 1.7,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (parts.length > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      parts[1],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nanumMyeongjo(
                        fontSize: 20,
                        color: _bloodFresh,
                        height: 1.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  if (parts.length > 2) ...[
                    const SizedBox(height: 2),
                    Text(
                      parts[2],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nanumMyeongjo(
                        fontSize: 16,
                        color: _rice,
                        height: 1.7,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsRow({required double weeklyKm, required int totalRuns, required int bestEscapeM}) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _borderInk, width: 1),
          bottom: BorderSide(color: _borderInk, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: _statCell(
              label: S.isKo ? '이번 주' : 'This week',
              hanjaValue: S.isKo
                  ? _hanjaDigits(weeklyKm.round())
                  : weeklyKm.round().toString(),
              unit: 'km',
              korSub: S.isKo
                  ? '${_korWordsUnder1000(weeklyKm.round())} 킬로미터'
                  : '${weeklyKm.round()} kilometers',
            ),
          ),
          Container(width: 1, height: 48, color: _borderInk),
          Expanded(
            child: _statCell(
              label: S.isKo ? '밤의 기록' : 'Nights run',
              hanjaValue: S.isKo
                  ? _hanjaDigits(totalRuns)
                  : totalRuns.toString(),
              unit: '',
              korSub: S.isKo
                  ? '${_korWordsUnder1000(totalRuns)} 밤'
                  : '$totalRuns nights',
            ),
          ),
          Container(width: 1, height: 48, color: _borderInk),
          Expanded(
            child: _statCell(
              label: S.isKo ? '최장 거리' : 'Best escape',
              hanjaValue: S.isKo
                  ? _hanjaDigits(bestEscapeM)
                  : bestEscapeM.toString(),
              unit: 'm',
              korSub: S.isKo
                  ? '${_korWordsUnder1000(bestEscapeM)} 걸음'
                  : '$bestEscapeM steps',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCell({required String label, required String hanjaValue, required String unit, required String korSub}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 10,
            color: _fade,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: hanjaValue,
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 22,
                  color: _rice,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: unit,
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 10,
                    color: _outline,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          korSub,
          style: GoogleFonts.gowunBatang(
            fontSize: 10,
            color: _outline,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// 도플갱어 추격 카드 — 챌린지 모드(/prepare extra: -1)
  Widget _doppelgangerCard(BuildContext context) {
    return _actionCard(
      context: context,
      minHeight: 120,
      title: S.isKo
          ? '오늘 밤,\n다시 뛰어라.'
          : 'Tonight,\nrun again.',
      subtitle: S.isKo
          ? '도 플 갱 어   추 격'
          : 'D O P P E L · C H A S E',
      cornerHanja: '追',
      hanjaColor: _bloodDry,
      subtitleColor: _bloodFresh,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF3B0006), Color(0xFF0D0607)],
        ),
        border: Border.all(color: _bloodDry, width: 1),
      ),
      onTap: () async {
        SfxService().tapChallenge();
        final runId = await pickChallengeRun(context);
        if (runId != null && context.mounted) {
          context.push('/prepare', extra: runId);
        }
      },
    );
  }

  /// 새 기록 카드 — 전설의 마라토너 or 자유 러닝 선택(/prepare)
  Widget _newRecordCard(BuildContext context) {
    return _actionCard(
      context: context,
      minHeight: 120,
      title: S.isKo
          ? '홀로,\n새 기록을 남겨라.'
          : 'Alone,\nset a new record.',
      subtitle: S.isKo
          ? '전 설 의   마 라 토 너   ·   자 유'
          : 'L E G E N D · F R E E',
      cornerHanja: '記',
      hanjaColor: _outline,
      subtitleColor: _outline,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0607),
        border: Border(
          top: BorderSide(color: _borderInk, width: 1),
          bottom: BorderSide(color: _borderInk, width: 1),
          left: BorderSide(color: _borderInk, width: 1),
          right: BorderSide(color: _borderInk, width: 1),
        ),
      ),
      onTap: () {
        debugPrint('[MysticHome] 새 기록 카드 TAP');
        SfxService().tapNewRun();
        context.push('/prepare');
      },
    );
  }

  /// 공통 액션 카드 위젯 — 명시적 크기로 hit test 보장
  Widget _actionCard({
    required BuildContext context,
    required double minHeight,
    required String title,
    required String subtitle,
    required String cornerHanja,
    required Color hanjaColor,
    required Color subtitleColor,
    required Decoration decoration,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: minHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          // Stack 제거 → Column + Row로 한자 배치 (hit test 단순화)
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.nanumMyeongjo(
                        fontSize: 22,
                        color: _rice,
                        height: 1.3,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    cornerHanja,
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 14,
                      color: hanjaColor,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.gowunBatang(
                  fontSize: 10,
                  color: subtitleColor,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _recentRow(RunModel r) {
    final isWin = r.challengeResult == 'win';
    final isLoss = r.challengeResult == 'lose';
    final label = isWin
        ? (S.isKo ? '살았다' : 'escaped')
        : isLoss
            ? (S.isKo ? '잡혔다' : 'caught')
            : (S.isKo ? '뛰었다' : 'ran');
    final labelColor = isWin ? _rice : isLoss ? _bloodFresh : _outline;
    final date = r.date.length >= 10 ? r.date.substring(5, 10).replaceAll('-', '.') : r.date;
    final userName = r.name?.trim() ?? '';
    final autoLoc = r.location?.trim() ?? '';
    final location = userName.isNotEmpty
        ? userName
        : (autoLoc.isNotEmpty ? autoLoc : (S.isKo ? '이름 없는 길' : 'Unnamed path'));
    final shortLoc = location.length > 12 ? '${location.substring(0, 12)}…' : location;
    final distKm = (r.distanceM / 1000).toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _borderInk, style: BorderStyle.solid, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$date · $shortLoc',
              style: GoogleFonts.gowunBatang(
                fontSize: 12,
                color: _outline,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            '${distKm}km',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 12,
              color: _rice.withValues(alpha: 0.75),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 12,
              color: labelColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(top: BorderSide(color: _borderInk, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, '家', S.isKo ? '오늘' : 'today', active: true, onTap: () {}),
            _navItem(context, '夜', S.isKo ? '지난 밤' : 'past', onTap: () {
              SfxService().tapCard();
              context.push('/history');
            }),
            _navItem(context, '分', S.isKo ? '분 석' : 'analysis', onTap: () {
              SfxService().tapCard();
              context.push('/analysis');
            }),
            _navItem(context, '設', S.isKo ? '설 정' : 'settings', onTap: () {
              SfxService().tapCard();
              context.push('/settings');
            }),
          ],
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, String hanja, String label, {bool active = false, required VoidCallback onTap}) {
    final c = active ? _bloodFresh : _outline;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hanja,
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 20,
                  color: c,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.gowunBatang(
                  fontSize: 9,
                  color: c.withValues(alpha: 0.8),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final bool topLeft;
  _CornerPainter(this.color, {required this.topLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    if (topLeft) {
      canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
    } else {
      canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), paint);
      canvas.drawLine(Offset(size.width, size.height), Offset(size.width, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
