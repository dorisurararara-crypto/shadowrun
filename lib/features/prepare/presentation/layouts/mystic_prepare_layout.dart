import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/features/running/data/legend_runners.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T3 Korean Mystic 테마용 Prepare 화면 레이아웃.
/// PrepareScreen의 state에서 읽기 전용 데이터와 콜백만 주입받는다.
class MysticPrepareLayout extends StatelessWidget {
  final bool isChallenge;
  final bool gpsReady;
  final bool tooFarFromStart;
  final bool canStart;
  final String selectedQuote;

  // 비챌린지 — 모드 선택 (marathon / freerun)
  final String selectedMode;
  final ValueChanged<String> onModeChanged;

  // 챌린지 — 그림자 러닝 정보
  final RunModel? shadowRun;
  final String shadowLocationType; // 'same' | 'different'
  final ValueChanged<String> onShadowLocationChanged;

  // 챌린지 — 도플갱어 속도 3단 ('slow' | 'mid' | 'fast')
  final String shadowSpeedLevel;
  final ValueChanged<String> onShadowSpeedChanged;

  // 러닝화
  final List<Map<String, dynamic>> shoes;
  final int? selectedShoeId;
  final ValueChanged<int?> onShoeChanged;

  // 전설의 마라토너 (marathon 모드일 때)
  final String? selectedLegendId;
  final ValueChanged<String> onLegendChanged;
  final bool isPro;
  final VoidCallback onLegendLocked;

  // 페이스메이커 (freerun 모드일 때)
  final bool pacemakerEnabled;
  final ValueChanged<bool> onPacemakerToggled;
  final int pacemakerSecPerKm;
  final ValueChanged<int> onPacemakerPaceChanged;

  // 액션
  final VoidCallback onStart;
  final VoidCallback onBack;

  // 카운트다운 오버레이
  final bool countdownActive;
  final int countdownValue;

  const MysticPrepareLayout({
    super.key,
    required this.isChallenge,
    required this.gpsReady,
    required this.tooFarFromStart,
    required this.canStart,
    required this.selectedQuote,
    required this.selectedMode,
    required this.onModeChanged,
    required this.shadowRun,
    required this.shadowLocationType,
    required this.onShadowLocationChanged,
    required this.shadowSpeedLevel,
    required this.onShadowSpeedChanged,
    required this.shoes,
    required this.selectedShoeId,
    required this.onShoeChanged,
    required this.selectedLegendId,
    required this.onLegendChanged,
    required this.isPro,
    required this.onLegendLocked,
    required this.pacemakerEnabled,
    required this.onPacemakerToggled,
    required this.pacemakerSecPerKm,
    required this.onPacemakerPaceChanged,
    required this.onStart,
    required this.onBack,
    required this.countdownActive,
    required this.countdownValue,
  });

  // mystic_home_layout.dart과 동일한 팔레트
  static const _ink = Color(0xFF050302);
  static const _rice = Color(0xFFF0EBE3);
  static const _riceDim = Color(0xFFBFB3A3);
  static const _riceFade = Color(0xFF5A4840);
  static const _riceGhost = Color(0xFF8C7A6A);
  static const _bloodDry = Color(0xFF7A0A0E);
  static const _bloodFresh = Color(0xFFC42029);
  static const _outline = Color(0xFF7A6858);
  static const _line = Color(0xFF2A1A18);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          // 배경 한자 워터마크 始
          const Positioned(
            right: -40,
            top: 80,
            child: IgnorePointer(
              child: Text(
                '始',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 260,
                  color: Color(0x227A0A0E),
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          // 배경 한자 워터마크 走 (좌하)
          const Positioned(
            left: -30,
            bottom: -20,
            child: IgnorePointer(
              child: Text(
                '走',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 220,
                  color: Color(0x1A7A0A0E),
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(child: _buildScroll(context)),
                _buildGoButton(),
              ],
            ),
          ),
          if (countdownActive) _buildCountdownOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Text(
                    '‹ 돌아가기',
                    style: GoogleFonts.gowunBatang(
                      fontSize: 12,
                      color: _riceDim,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: _bloodDry, width: 1),
                ),
                child: Text(
                  '始',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 22,
                    color: _bloodFresh,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '오늘 밤의\n준비',
            textAlign: TextAlign.center,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 32,
              color: _rice,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '─ P R E P A R A T I O N ─',
            style: GoogleFonts.gowunBatang(
              fontSize: 11,
              color: _riceFade,
              letterSpacing: 4,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          // 얇은 붓 선
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 60),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x00000000), _bloodDry, Color(0x00000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScroll(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _gpsBlock(),
          if (tooFarFromStart && isChallenge && shadowLocationType == 'same') ...[
            const SizedBox(height: 10),
            _tooFarWarn(),
          ],
          const SizedBox(height: 18),
          _quoteBlock(),
          const SizedBox(height: 20),
          if (isChallenge) ...[
            _shadowSpeedSection(),
            const SizedBox(height: 18),
            _locationSection(),
            const SizedBox(height: 18),
          ] else ...[
            _modeSection(),
            const SizedBox(height: 18),
            if (selectedMode == 'marathon') ...[
              _legendSection(),
              const SizedBox(height: 18),
            ],
            if (selectedMode == 'freerun') ...[
              _pacemakerSection(),
              const SizedBox(height: 18),
            ],
          ],
          if (shoes.isNotEmpty) ...[
            _shoeSection(),
            const SizedBox(height: 18),
          ],
          _noticeRow(),
        ],
      ),
    );
  }

  Widget _gpsBlock() {
    final ok = gpsReady;
    final dotColor = ok ? const Color(0xFF4ADE80) : _bloodFresh;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: ok
            ? const Color(0x0F4ADE80)
            : const Color(0x14C42029),
        border: Border.all(
          color: ok ? const Color(0x334ADE80) : const Color(0x33C42029),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: dotColor.withValues(alpha: 0.6), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ok ? '위치 확인됨 · 정상' : '위치 탐색 중…',
              style: GoogleFonts.gowunBatang(
                fontSize: 12,
                color: _riceDim,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Text(
            ok ? '正 常' : '探 索',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 11,
              color: ok ? _bloodFresh : _bloodDry,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tooFarWarn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x14C42029),
        border: Border.all(color: const Color(0x66C42029)),
      ),
      child: Row(
        children: [
          Text(
            '離',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 14,
              color: _bloodFresh,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '출발점에서 200m 이상 떨어져 있다.',
              style: GoogleFonts.gowunBatang(
                fontSize: 11,
                color: _bloodFresh,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteBlock() {
    if (selectedQuote.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: CustomPaint(
              size: const Size(16, 16),
              painter: _CornerPainter(_bloodFresh, topLeft: true),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: CustomPaint(
              size: const Size(16, 16),
              painter: _CornerPainter(_bloodFresh, topLeft: false),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Text(
              '「 $selectedQuote 」',
              textAlign: TextAlign.center,
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 14,
                color: _rice,
                height: 1.7,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 챌린지 — 그림자의 속도 3단. shadowSpeedLevel props로 제어.
  Widget _shadowSpeedSection() {
    final current = shadowSpeedLevel;
    return _sectionFrame(
      title: '그림자의 속도',
      english: 'S H A D O W   S P E E D',
      child: Row(
        children: [
          Expanded(child: _speedOption('slow', '緩', '느린 그림자', '6:30 / km', current)),
          const SizedBox(width: 6),
          Expanded(child: _speedOption('mid', '中', '보통', '5:30 / km', current)),
          const SizedBox(width: 6),
          Expanded(child: _speedOption('fast', '急', '빠른 그림자', '4:30 / km', current)),
        ],
      ),
    );
  }

  Widget _speedOption(String key, String hanja, String label, String sub, String current) {
    final on = key == current;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onShadowSpeedChanged(key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: on ? const Color(0xFF0F0505) : const Color(0x990A0606),
          border: Border.all(
            color: on ? _bloodDry : _line,
            width: on ? 1.2 : 1,
          ),
          boxShadow: on
              ? const [
                  BoxShadow(
                    color: Color(0x407A0A0E),
                    blurRadius: 18,
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(
              hanja,
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 20,
                color: on ? _bloodFresh : _riceGhost,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.gowunBatang(
                fontSize: 11,
                color: on ? _rice : _riceDim,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              sub,
              style: GoogleFonts.gowunBatang(
                fontSize: 9,
                color: _riceFade,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 챌린지 — 장소 선택 (same / different)
  Widget _locationSection() {
    return _sectionFrame(
      title: '러닝 장소',
      english: 'L O C A T I O N',
      child: Column(
        children: [
          _locationOption(
            'same',
            '同',
            '같은 장소',
            '그림자의 실제 경로를 따라간다',
          ),
          const SizedBox(height: 8),
          _locationOption(
            'different',
            '異',
            '다른 장소',
            '음성만 듣고 달린다',
          ),
        ],
      ),
    );
  }

  Widget _locationOption(String key, String hanja, String title, String desc) {
    final on = shadowLocationType == key;
    return InkWell(
      onTap: () {
        SfxService().toggle();
        onShadowLocationChanged(key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: on ? const Color(0x147A0A0E) : const Color(0x660A0606),
          border: Border.all(
            color: on ? _bloodDry : _line,
            width: on ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: on ? _bloodFresh : _riceFade,
                  width: 1,
                ),
              ),
              child: Text(
                hanja,
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 14,
                  color: on ? _bloodFresh : _riceDim,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 14,
                      color: on ? _rice : _riceDim,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.gowunBatang(
                      fontSize: 11,
                      color: _riceFade,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (on)
              Text(
                '●',
                style: TextStyle(color: _bloodFresh, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  /// 비챌린지 — 모드 선택 (marathon / freerun)
  Widget _modeSection() {
    return _sectionFrame(
      title: '오늘의 길',
      english: 'M O D E',
      child: Column(
        children: [
          _modeOption(
            'marathon',
            '勝',
            '전설의 마라토너',
            '세계 기록들이 당신을 쫓는다',
          ),
          const SizedBox(height: 8),
          _modeOption(
            'freerun',
            '自',
            '자 유',
            '그저 달린다. 누구도 없이.',
          ),
        ],
      ),
    );
  }

  Widget _modeOption(String key, String hanja, String title, String desc) {
    final on = selectedMode == key;
    return InkWell(
      onTap: () {
        SfxService().toggle();
        onModeChanged(key);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: on ? const Color(0x147A0A0E) : const Color(0x660A0606),
          border: Border.all(
            color: on ? _bloodDry : _line,
            width: on ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: on ? _bloodFresh : _riceFade,
                  width: 1,
                ),
              ),
              child: Text(
                hanja,
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 14,
                  color: on ? _bloodFresh : _riceDim,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 14,
                      color: on ? _rice : _riceDim,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    desc,
                    style: GoogleFonts.gowunBatang(
                      fontSize: 11,
                      color: _riceFade,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (on)
              Text(
                '●',
                style: TextStyle(color: _bloodFresh, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendSection() {
    return _sectionFrame(
      title: S.isKo ? '전설과 함께 뛰기' : 'Chase a Legend',
      english: 'L E G E N D',
      child: SizedBox(
        height: 198,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: LegendRunners.all.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            return _legendCard(LegendRunners.all[index]);
          },
        ),
      ),
    );
  }

  Widget _legendCard(LegendRunner legend) {
    final on = selectedLegendId == legend.id;
    final locked = legend.isProOnly && !isPro;
    return InkWell(
      onTap: () {
        if (locked) {
          SfxService().toggle();
          onLegendLocked();
          return;
        }
        SfxService().toggle();
        onLegendChanged(legend.id);
      },
      child: SizedBox(
        width: 196,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF0F0505) : const Color(0x990A0606),
            border: Border.all(
              color: on ? _bloodDry : _line,
              width: on ? 1.2 : 1,
            ),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x557A0A0E),
                      blurRadius: 20,
                      spreadRadius: -8,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -4,
                top: -6,
                child: Text(
                  '走',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 54,
                    color: on
                        ? _bloodDry.withValues(alpha: 0.35)
                        : _bloodDry.withValues(alpha: 0.12),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(legend.flag, style: const TextStyle(fontSize: 30)),
                      const Spacer(),
                      if (locked)
                        const Icon(Icons.lock_rounded,
                            size: 14, color: _bloodFresh)
                      else if (on)
                        Text('●',
                            style: const TextStyle(
                                color: _bloodFresh, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    legend.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 16,
                      color: on ? _rice : _riceDim,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${legend.recordLabel}  ·  ${legend.paceLabel}',
                    style: GoogleFonts.gowunBatang(
                      fontSize: 11,
                      color: on ? _bloodFresh : _riceFade,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    width: 24,
                    color: on ? _bloodDry : _line,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      legend.bio,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.gowunBatang(
                        fontSize: 10.5,
                        height: 1.55,
                        color: _riceFade,
                        fontWeight: FontWeight.w400,
                      ),
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

  Widget _pacemakerSection() {
    final isKo = S.isKo;
    return _sectionFrame(
      title: isKo ? '페이스 메이커' : 'Pacemaker',
      english: 'P A C E M A K E R   ·   助 伴',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              SfxService().toggle();
              onPacemakerToggled(!pacemakerEnabled);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: pacemakerEnabled
                    ? const Color(0x147A0A0E)
                    : const Color(0x660A0606),
                border: Border.all(
                  color: pacemakerEnabled ? _bloodDry : _line,
                  width: pacemakerEnabled ? 1.2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: pacemakerEnabled ? _bloodFresh : _riceFade,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '助',
                      style: GoogleFonts.nanumMyeongjo(
                        fontSize: 14,
                        color: pacemakerEnabled ? _bloodFresh : _riceDim,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKo ? '유령 페이서 동반' : 'Ghost pacer',
                          style: GoogleFonts.nanumMyeongjo(
                            fontSize: 14,
                            color: pacemakerEnabled ? _rice : _riceDim,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isKo
                              ? '유령이 이 페이스로 뛰어요. 앞서/뒤처지면 알려줘요.'
                              : 'A ghost paces with you and tells you when you drift.',
                          style: GoogleFonts.gowunBatang(
                            fontSize: 11,
                            color: _riceFade,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: pacemakerEnabled,
                    activeThumbColor: _bloodFresh,
                    activeTrackColor: _bloodDry,
                    inactiveThumbColor: _riceGhost,
                    inactiveTrackColor: _line,
                    onChanged: (v) {
                      SfxService().toggle();
                      onPacemakerToggled(v);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Opacity(
            opacity: pacemakerEnabled ? 1.0 : 0.35,
            child: IgnorePointer(
              ignoring: !pacemakerEnabled,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: BoxDecoration(
                  color: pacemakerEnabled
                      ? const Color(0xFF0F0505)
                      : const Color(0x660A0606),
                  border: Border.all(
                    color: pacemakerEnabled ? _bloodDry : _line,
                    width: pacemakerEnabled ? 1.2 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '伴',
                          style: GoogleFonts.nanumMyeongjo(
                            fontSize: 22,
                            color: pacemakerEnabled ? _bloodFresh : _riceGhost,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formatPace(pacemakerSecPerKm),
                          style: GoogleFonts.nanumMyeongjo(
                            fontSize: 22,
                            color: _rice,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '/ km',
                          style: GoogleFonts.gowunBatang(
                            fontSize: 10,
                            color: _riceFade,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: const SliderThemeData(
                        activeTrackColor: _bloodFresh,
                        inactiveTrackColor: _line,
                        thumbColor: _bloodFresh,
                        overlayColor: Color(0x557A0A0E),
                        trackHeight: 2,
                      ),
                      child: Slider(
                        min: 270,
                        max: 480,
                        divisions: 14,
                        value: pacemakerSecPerKm.toDouble(),
                        onChanged: (v) => onPacemakerPaceChanged(v.round()),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "4'30\"",
                          style: GoogleFonts.nanumMyeongjo(
                            fontSize: 10,
                            color: _riceFade,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          '血',
                          style: GoogleFonts.nanumMyeongjo(
                            fontSize: 12,
                            color: _bloodDry,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "8'00\"",
                          style: GoogleFonts.nanumMyeongjo(
                            fontSize: 10,
                            color: _riceFade,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPace(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  Widget _shoeSection() {
    return _sectionFrame(
      title: '신 발',
      english: 'S H O E S',
      child: SizedBox(
        height: 56,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: shoes.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final shoe = shoes[index];
            final shoeId = shoe['id'] as int;
            final name = shoe['name'] as String? ?? '러닝화';
            final totalM = (shoe['total_distance_m'] as num?)?.toDouble() ?? 0;
            final totalKm = (totalM / 1000).toStringAsFixed(0);
            final on = selectedShoeId == shoeId;
            return InkWell(
              onTap: () {
                SfxService().toggle();
                onShoeChanged(on ? null : shoeId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: on ? const Color(0x147A0A0E) : const Color(0x660A0606),
                  border: Border.all(
                    color: on ? _bloodDry : _line,
                    width: on ? 1.2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: on ? _bloodFresh : _riceFade,
                        ),
                      ),
                      child: Text(
                        index == 0 ? '鞋' : '履',
                        style: GoogleFonts.nanumMyeongjo(
                          fontSize: 12,
                          color: on ? _bloodFresh : _riceDim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.gowunBatang(
                            fontSize: 12,
                            color: on ? _rice : _riceDim,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${totalKm}km',
                          style: GoogleFonts.gowunBatang(
                            fontSize: 9.5,
                            color: _riceFade,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionFrame({required String title, required String english, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 13,
                color: _rice,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              english,
              style: GoogleFonts.gowunBatang(
                fontSize: 10,
                color: _riceFade,
                letterSpacing: 3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }

  Widget _noticeRow() {
    return Center(
      child: Text(
        '─   심 호 흡   ·   준 비   ─',
        style: GoogleFonts.nanumMyeongjo(
          fontSize: 10,
          color: _outline,
          letterSpacing: 4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildGoButton() {
    final active = canStart;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
      child: InkWell(
        onTap: active ? () {
          SfxService().tapCard();
          onStart();
        } : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: active
                  ? const [Color(0xFF1D0609), Color(0xFF080202)]
                  : const [Color(0xFF120405), Color(0xFF070202)],
            ),
            border: Border.all(
              color: active ? _bloodFresh : _bloodDry.withValues(alpha: 0.4),
            ),
            boxShadow: active
                ? const [
                    BoxShadow(
                      color: Color(0x66C42029),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Color(0x997A0A0E),
                      blurRadius: 40,
                      spreadRadius: -10,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              // 이중 괘선
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    margin: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: active
                            ? _bloodFresh.withValues(alpha: 0.4)
                            : _bloodDry.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
              // 우상단 한자
              Positioned(
                right: 4,
                top: 0,
                child: Text(
                  '始',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 18,
                    color: active ? _bloodFresh : _bloodDry,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '走',
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 30,
                      color: active ? _bloodFresh : _bloodDry,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '뛰  어  라',
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 26,
                      color: active ? _rice : _rice.withValues(alpha: 0.35),
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 6,
                      shadows: active
                          ? const [
                              Shadow(
                                color: Color(0x66C42029),
                                blurRadius: 20,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '지  금  시  작',
                    style: GoogleFonts.gowunBatang(
                      fontSize: 11,
                      color: active ? _bloodFresh : _bloodDry,
                      letterSpacing: 8,
                      fontWeight: FontWeight.w700,
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

  Widget _buildCountdownOverlay() {
    final label = countdownValue > 0 ? _hanjaDigit(countdownValue) : '走';
    return Container(
      color: _ink.withValues(alpha: 0.96),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 180,
                color: _rice,
                height: 1,
                fontWeight: FontWeight.w800,
                shadows: const [
                  Shadow(color: Color(0xAAC42029), blurRadius: 60),
                  Shadow(color: Color(0x887A0A0E), blurRadius: 120),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              countdownValue > 0 ? '준  비' : '지  금',
              style: GoogleFonts.gowunBatang(
                fontSize: 14,
                color: _bloodFresh,
                letterSpacing: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _hanjaDigit(int n) {
    const d = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];
    if (n < 0 || n > 9) return '$n';
    return d[n];
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

