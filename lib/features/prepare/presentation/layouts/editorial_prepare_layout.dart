import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/features/running/data/legend_runners.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T4 Editorial Thriller 테마용 Prepare 화면 레이아웃.
/// GQ 매거진 스타일. 거대 세리프 로고 위에 붉은 헤드라인이 꽂히는 프레스 감성.
class EditorialPrepareLayout extends StatelessWidget {
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

  const EditorialPrepareLayout({
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

  // Editorial Thriller 팔레트
  static const _bg = Color(0xFF0A0A0A);
  static const _bgPage = Color(0xFF050507);
  static const _ink = Color(0xFFF5F2EA);
  static const _inkDim = Color(0xFF8A8A8F);
  static const _inkFade = Color(0xFF6A6A70);
  static const _inkGhost = Color(0xFF3A3A40);
  static const _red = Color(0xFFDC2626);
  static const _redSub = Color(0xFFF87171);
  static const _hair = Color(0x1FF5F2EA);
  static const _hairRed = Color(0x4CDC2626);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildScroll()),
                  _buildBeginButton(),
                ],
              ),
            ),
          ),
          if (countdownActive)
            Positioned.fill(child: _buildCountdownOverlay()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack,
            child: SizedBox(
              height: 32,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    S.isKo ? '←  뒤로' : '←  back',
                    style: S.isKo
                        ? GoogleFonts.notoSerif(
                            fontSize: 13,
                            color: _inkDim,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w400,
                          )
                        : GoogleFonts.playfairDisplay(
                            fontStyle: FontStyle.italic,
                            fontSize: 13,
                            color: _inkDim,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            S.isKo ? '브 리 핑' : 'BRIEFING',
            style: S.isKo
                ? GoogleFonts.notoSerif(
                    fontSize: 11,
                    color: _redSub,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.playfairDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                    color: _redSub,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w400,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScroll() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTitleBlock(),
          const SizedBox(height: 28),
          _gpsRow(),
          if (tooFarFromStart && isChallenge && shadowLocationType == 'same') ...[
            const SizedBox(height: 12),
            _tooFarWarn(),
          ],
          const SizedBox(height: 22),
          if (selectedQuote.isNotEmpty) ...[
            _quoteLine(),
            const SizedBox(height: 22),
          ],
          _articleRow(S.isKo ? '주인공' : 'Subject', _subjectValue()),
          _articleDivider(),
          _articleRow(S.isKo ? '장비' : 'Equipment', _equipmentValue()),
          _articleDivider(),
          _articleRow(S.isKo ? '거리' : 'Distance', _distanceValue()),
          const SizedBox(height: 26),
          if (isChallenge) ...[
            _shadowSpeedSection(),
            const SizedBox(height: 22),
            _locationSection(),
            const SizedBox(height: 22),
          ] else ...[
            _modeSection(),
            const SizedBox(height: 22),
            if (selectedMode == 'marathon') ...[
              _legendSection(),
              const SizedBox(height: 22),
            ],
            if (selectedMode == 'freerun') ...[
              _pacemakerSection(),
              const SizedBox(height: 22),
            ],
          ],
          if (shoes.isNotEmpty) ...[
            _shoeCard(),
            const SizedBox(height: 22),
          ],
          _goalCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTitleBlock() {
    final chapterNum = _chapterNumber();
    final isKo = S.isKo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isKo ? '— 출 발 전 —' : '— Pre-game —',
          style: isKo
              ? GoogleFonts.notoSerif(
                  fontSize: 11,
                  color: _redSub,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.w500,
                )
              : GoogleFonts.playfairDisplay(
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  color: _redSub,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.w400,
                ),
        ),
        const SizedBox(height: 14),
        if (isKo)
          RichText(
            text: TextSpan(
              style: GoogleFonts.notoSerifKr(
                fontSize: 34,
                color: _ink,
                height: 1.15,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(text: '제 '),
                TextSpan(
                  text: chapterNum,
                  style: GoogleFonts.notoSerifKr(
                    fontSize: 34,
                    color: _redSub,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const TextSpan(text: '밤의\n준비.'),
              ],
            ),
          )
        else
          RichText(
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontStyle: FontStyle.italic,
                fontSize: 36,
                color: _ink,
                height: 1.1,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(text: 'Preparing\n'),
                TextSpan(
                  text: 'Chapter $chapterNum',
                  style: GoogleFonts.playfairDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 36,
                    color: _redSub,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        if (isKo) ...[
          const SizedBox(height: 6),
          Text(
            'Chapter $chapterNum',
            style: GoogleFonts.playfairDisplay(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: _inkFade,
              letterSpacing: 3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          height: 1,
          width: 60,
          color: _red,
        ),
      ],
    );
  }

  String _chapterNumber() {
    // shadowRun.id가 있을 때는 그 다음 에피소드 느낌으로.
    final id = shadowRun?.id;
    if (id != null) return (id + 1).toString().padLeft(2, '0');
    return '29';
  }

  Widget _gpsRow() {
    final ok = gpsReady;
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: ok ? const Color(0xFF4ADE80) : _redSub,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: (ok ? const Color(0xFF4ADE80) : _redSub).withValues(alpha: 0.55),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            S.isKo
                ? (ok ? 'GPS 연결 · 신호 확보' : '신호 탐색 중…')
                : (ok ? 'GPS connected · signal locked' : 'searching for signal…'),
            style: S.isKo
                ? GoogleFonts.notoSerif(
                    fontSize: 12,
                    color: _inkDim,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w400,
                  )
                : GoogleFonts.playfairDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    color: _inkDim,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w400,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _tooFarWarn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: _hairRed),
      ),
      child: Row(
        children: [
          Text(
            '×',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: _redSub,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              S.isKo
                  ? '출발점에서 200m 이상 떨어져 있어요.'
                  : 'more than 200m from the starting point.',
              style: S.isKo
                  ? GoogleFonts.notoSerif(
                      fontSize: 11.5,
                      color: _redSub,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w400,
                    )
                  : GoogleFonts.playfairDisplay(
                      fontStyle: FontStyle.italic,
                      fontSize: 11.5,
                      color: _redSub,
                      letterSpacing: 0.5,
                      fontWeight: FontWeight.w400,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quoteLine() {
    return Text(
      '「 $selectedQuote 」',
      textAlign: TextAlign.center,
      style: GoogleFonts.notoSerif(
        fontSize: 13,
        color: _inkDim,
        height: 1.8,
        letterSpacing: 0.3,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _articleRow(String label, String value) {
    final isKo = S.isKo;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: isKo
                  ? GoogleFonts.notoSerifKr(
                      fontSize: 11,
                      color: _inkFade,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w400,
                    )
                  : GoogleFonts.notoSerif(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: _inkFade,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w300,
                    ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: isKo
                  ? GoogleFonts.notoSerifKr(
                      fontSize: 17,
                      color: _ink,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    )
                  : GoogleFonts.playfairDisplay(
                      fontSize: 17,
                      color: _ink,
                      letterSpacing: 0.1,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _articleDivider() {
    return Container(height: 1, color: _hair);
  }

  String _subjectValue() {
    final isKo = S.isKo;
    if (isChallenge) {
      return isKo ? '도플갱어' : 'The Doppelgänger';
    }
    if (selectedMode == 'marathon') {
      return isKo ? '전설의 마라토너' : 'Legendary Marathoners';
    }
    return isKo ? '자유 러너' : 'The Free Runner';
  }

  String _equipmentValue() {
    final isKo = S.isKo;
    if (shoes.isEmpty) return isKo ? '맨발' : 'Bare feet';
    if (selectedShoeId == null) return isKo ? '미정' : 'Not chosen';
    final match = shoes.firstWhere(
      (s) => (s['id'] as int?) == selectedShoeId,
      orElse: () => shoes.first,
    );
    return (match['name'] as String?) ?? (isKo ? '러닝화' : 'Running shoes');
  }

  String _distanceValue() {
    if (isChallenge && shadowRun != null) {
      return shadowRun!.formattedDistance;
    }
    return S.isKo ? '자유 · 열림' : 'Free · open';
  }

  /// 챌린지 — 그림자의 속도 (slow 6:30 / mid 5:30 / fast 4:30)
  /// shadowSpeedLevel props로 제어 — 사용자가 탭해서 변경.
  Widget _shadowSpeedSection() {
    final current = shadowSpeedLevel;
    final isKo = S.isKo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          isKo ? '도플갱어 속도' : 'Doppelgänger Pace',
          isKo ? '탭으로 변경' : 'tap to change',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _speedOption(
                  'slow', isKo ? '느림' : 'slow', '6:30', current),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _speedOption(
                  'mid', isKo ? '보통' : 'medium', '5:30', current),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _speedOption(
                  'fast', isKo ? '빠름' : 'fast', '4:30', current),
            ),
          ],
        ),
      ],
    );
  }

  Widget _speedOption(String key, String label, String pace, String current) {
    final on = key == current;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        onShadowSpeedChanged(key);
      },
      child: SizedBox(
        height: 96,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF0A0304) : _bgPage,
            border: Border.all(
              color: on ? _red : _inkGhost,
              width: on ? 1.2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: S.isKo
                    ? GoogleFonts.notoSerifKr(
                        fontSize: 12,
                        color: on ? _redSub : _inkFade,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      )
                    : GoogleFonts.playfairDisplay(
                        fontStyle: FontStyle.italic,
                        fontSize: 12,
                        color: on ? _redSub : _inkFade,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
              ),
              const SizedBox(height: 6),
              Text(
                pace,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  color: on ? _ink : _inkDim,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '/ km',
                style: GoogleFonts.notoSerif(
                  fontSize: 9,
                  color: _inkFade,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationSection() {
    final isKo = S.isKo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          isKo ? '장소' : 'Location',
          isKo ? '탭으로 변경' : 'tap to change',
        ),
        const SizedBox(height: 12),
        _locationOption(
          'same',
          isKo ? '같은 곳' : 'Same ground',
          isKo ? '그림자의 실제 경로를 따른다' : 'follow the shadow\'s actual path',
        ),
        const SizedBox(height: 8),
        _locationOption(
          'different',
          isKo ? '다른 곳' : 'Different ground',
          isKo ? '목소리만 따라온다' : 'only the voice follows you',
        ),
      ],
    );
  }

  Widget _locationOption(String key, String title, String desc) {
    final on = shadowLocationType == key;
    final isKo = S.isKo;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().toggle();
        onShadowLocationChanged(key);
      },
      child: SizedBox(
        height: 74,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF0A0304) : _bgPage,
            border: Border.all(
              color: on ? _red : _inkGhost,
              width: on ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: isKo
                          ? GoogleFonts.notoSerifKr(
                              fontSize: 15,
                              color: on ? _ink : _inkDim,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w500,
                            )
                          : GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              color: on ? _ink : _inkDim,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w400,
                            ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: isKo
                          ? GoogleFonts.notoSerifKr(
                              fontSize: 10.5,
                              color: _inkFade,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w300,
                            )
                          : GoogleFonts.notoSerif(
                              fontStyle: FontStyle.italic,
                              fontSize: 10.5,
                              color: _inkFade,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w300,
                            ),
                    ),
                  ],
                ),
              ),
              if (on)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: _redSub,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeSection() {
    final isKo = S.isKo;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          isKo ? '모드' : 'Mode',
          isKo ? '오늘 밤의 러닝' : 'tonight\'s run',
        ),
        const SizedBox(height: 12),
        _modeOption(
          'marathon',
          isKo ? '전설의 마라토너' : 'The Marathoners',
          isKo ? '세계 기록이 당신을 쫓는다' : 'world records chase you',
        ),
        const SizedBox(height: 8),
        _modeOption(
          'freerun',
          isKo ? '자유 러닝' : 'Free Run',
          isKo ? '아무도 따라오지 않는다. 오직 당신뿐.' : 'no one follows. only you.',
        ),
      ],
    );
  }

  Widget _modeOption(String key, String title, String desc) {
    final on = selectedMode == key;
    final isKo = S.isKo;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().toggle();
        onModeChanged(key);
      },
      child: SizedBox(
        height: 74,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF0A0304) : _bgPage,
            border: Border.all(
              color: on ? _red : _inkGhost,
              width: on ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: isKo
                          ? GoogleFonts.notoSerifKr(
                              fontSize: 15,
                              color: on ? _ink : _inkDim,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w500,
                            )
                          : GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              color: on ? _ink : _inkDim,
                              letterSpacing: 0.3,
                              fontWeight: FontWeight.w400,
                            ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: isKo
                          ? GoogleFonts.notoSerifKr(
                              fontSize: 10.5,
                              color: _inkFade,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w300,
                            )
                          : GoogleFonts.notoSerif(
                              fontStyle: FontStyle.italic,
                              fontSize: 10.5,
                              color: _inkFade,
                              letterSpacing: 0.4,
                              fontWeight: FontWeight.w300,
                            ),
                    ),
                  ],
                ),
              ),
              if (on)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: _redSub,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          S.isKo ? '전설과 함께 뛰기' : 'Chase a legend',
          S.isKo ? '선택' : 'select',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 186,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: LegendRunners.all.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return _legendCard(LegendRunners.all[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _legendCard(LegendRunner legend) {
    final on = selectedLegendId == legend.id;
    final locked = legend.isProOnly && !isPro;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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
        width: 200,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF0A0304) : _bgPage,
            border: Border.all(
              color: on ? _red : _inkGhost,
              width: on ? 1.2 : 1,
            ),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x558B0000),
                      blurRadius: 22,
                      spreadRadius: -8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(legend.flag, style: const TextStyle(fontSize: 32)),
                  const Spacer(),
                  if (locked)
                    const Icon(Icons.lock_rounded,
                        size: 15, color: Color(0xFFC83030))
                  else if (on)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: _redSub,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                legend.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.playfairDisplay(
                  fontStyle: FontStyle.italic,
                  fontSize: 17,
                  color: on ? _ink : _inkDim,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${legend.recordLabel}  ·  ${legend.paceLabel}',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 11.5,
                  color: on ? _redSub : _inkFade,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Container(height: 1, width: 24, color: on ? _red : _hair),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  legend.bio,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSerif(
                    fontStyle: FontStyle.italic,
                    fontSize: 10.5,
                    height: 1.45,
                    color: _inkFade,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pacemakerSection() {
    final isKo = S.isKo;
    final title = isKo ? '페이스메이커' : 'Pacemaker';
    final desc = isKo
        ? '유령이 이 페이스로 뛰어요. 앞서거나 뒤처지면 알려줘요.'
        : 'A ghost paces with you and tells you when you drift.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              title,
              style: isKo
                  ? GoogleFonts.notoSerifKr(
                      fontSize: 11,
                      color: _inkFade,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w400,
                    )
                  : GoogleFonts.notoSerif(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: _inkFade,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w300,
                    ),
            ),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                SfxService().toggle();
                onPacemakerToggled(!pacemakerEnabled);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: pacemakerEnabled ? _red : _inkGhost,
                    width: 1,
                  ),
                ),
                child: Text(
                  pacemakerEnabled ? (isKo ? 'ON' : 'on') : (isKo ? 'OFF' : 'off'),
                  style: GoogleFonts.playfairDisplay(
                    fontStyle: FontStyle.italic,
                    fontSize: 11,
                    color: pacemakerEnabled ? _redSub : _inkFade,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          desc,
          style: isKo
              ? GoogleFonts.notoSerifKr(
                  fontSize: 11,
                  color: _inkFade,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w300,
                  height: 1.6,
                )
              : GoogleFonts.notoSerif(
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  color: _inkFade,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w300,
                  height: 1.5,
                ),
        ),
        const SizedBox(height: 14),
        Opacity(
          opacity: pacemakerEnabled ? 1.0 : 0.35,
          child: IgnorePointer(
            ignoring: !pacemakerEnabled,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              decoration: BoxDecoration(
                color: pacemakerEnabled ? const Color(0xFF0A0304) : _bgPage,
                border: Border.all(
                  color: pacemakerEnabled ? _red : _inkGhost,
                  width: pacemakerEnabled ? 1.2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('👻', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Text(
                        _formatPace(pacemakerSecPerKm),
                        style: GoogleFonts.playfairDisplay(
                          fontStyle: FontStyle.italic,
                          fontSize: 22,
                          color: _ink,
                          letterSpacing: 0.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '/ km',
                        style: GoogleFonts.notoSerif(
                          fontSize: 10,
                          color: _inkFade,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: const SliderThemeData(
                      activeTrackColor: _red,
                      inactiveTrackColor: _inkGhost,
                      thumbColor: _redSub,
                      overlayColor: Color(0x338B0000),
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
                      Text("4'30\"",
                          style: GoogleFonts.playfairDisplay(
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                            color: _inkFade,
                            letterSpacing: 1,
                          )),
                      Text("8'00\"",
                          style: GoogleFonts.playfairDisplay(
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                            color: _inkFade,
                            letterSpacing: 1,
                          )),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatPace(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }

  Widget _shoeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          S.isKo ? '러닝화' : 'Footwear',
          S.isKo ? '교체' : 'swap',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shoes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final shoe = shoes[index];
              final shoeId = shoe['id'] as int;
              final name = shoe['name'] as String? ?? 'Running shoes';
              final totalM = (shoe['total_distance_m'] as num?)?.toDouble() ?? 0;
              final totalKm = (totalM / 1000).toStringAsFixed(0);
              final on = selectedShoeId == shoeId;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  SfxService().toggle();
                  onShoeChanged(on ? null : shoeId);
                },
                child: SizedBox(
                  height: 60,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: on ? const Color(0xFF0A0304) : _bgPage,
                      border: Border.all(
                        color: on ? _red : _inkGhost,
                        width: on ? 1.2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '◐',
                          style: TextStyle(
                            fontSize: 16,
                            color: on ? _redSub : _inkFade,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: S.isKo
                                  ? GoogleFonts.notoSerifKr(
                                      fontSize: 13,
                                      color: on ? _ink : _inkDim,
                                      letterSpacing: 0.2,
                                      fontWeight: FontWeight.w500,
                                    )
                                  : GoogleFonts.playfairDisplay(
                                      fontSize: 13,
                                      color: on ? _ink : _inkDim,
                                      letterSpacing: 0.2,
                                      fontWeight: FontWeight.w400,
                                    ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              S.isKo
                                  ? '$totalKm km 함께 걸었어요'
                                  : '$totalKm km walked together',
                              style: S.isKo
                                  ? GoogleFonts.notoSerifKr(
                                      fontSize: 9.5,
                                      color: _inkFade,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w300,
                                    )
                                  : GoogleFonts.notoSerif(
                                      fontStyle: FontStyle.italic,
                                      fontSize: 9.5,
                                      color: _inkFade,
                                      letterSpacing: 0.8,
                                      fontWeight: FontWeight.w300,
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _goalCard() {
    final distanceLabel = isChallenge && shadowRun != null
        ? shadowRun!.formattedDistance
        : '3.0 km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader(
          S.isKo ? '목표 거리' : 'Target Distance',
          S.isKo ? '수정' : 'edit',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _bgPage,
              border: Border.all(color: _inkGhost),
            ),
            child: Row(
              children: [
                Text(
                  distanceLabel,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    color: _ink,
                    letterSpacing: 0.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 16, color: _hair),
                const SizedBox(width: 10),
                Text(
                  S.isKo
                      ? (isChallenge ? '고정' : '자유')
                      : (isChallenge ? 'set' : 'free'),
                  style: S.isKo
                      ? GoogleFonts.notoSerifKr(
                          fontSize: 12,
                          color: _inkFade,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                        )
                      : GoogleFonts.playfairDisplay(
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                          color: _inkFade,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                        ),
                ),
                const Spacer(),
                Text(
                  '›',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 18,
                    color: _inkFade,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String action) {
    final isKo = S.isKo;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: isKo
              ? GoogleFonts.notoSerifKr(
                  fontSize: 11,
                  color: _inkFade,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w400,
                )
              : GoogleFonts.notoSerif(
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  color: _inkFade,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w300,
                ),
        ),
        const Spacer(),
        Text(
          action,
          style: isKo
              ? GoogleFonts.notoSerifKr(
                  fontSize: 10.5,
                  color: _redSub,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w400,
                )
              : GoogleFonts.playfairDisplay(
                  fontStyle: FontStyle.italic,
                  fontSize: 10.5,
                  color: _redSub,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w400,
                ),
        ),
      ],
    );
  }

  Widget _buildBeginButton() {
    final active = canStart;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 24),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: active
            ? () {
                SfxService().tapCard();
                onStart();
              }
            : null,
        child: SizedBox(
          height: 96,
          child: Container(
            decoration: BoxDecoration(
              color: _bg,
              border: Border.all(
                color: active ? _red : _red.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x558B0000),
                        blurRadius: 28,
                        spreadRadius: -6,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      margin: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: active
                              ? _redSub.withValues(alpha: 0.45)
                              : _red.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        S.isKo ? '오늘 밤의 추격' : 'Tonight\'s Chase',
                        style: S.isKo
                            ? GoogleFonts.notoSerifKr(
                                fontSize: 11,
                                color: active ? _redSub : _inkFade,
                                letterSpacing: 3.5,
                                fontWeight: FontWeight.w500,
                              )
                            : GoogleFonts.playfairDisplay(
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                                color: active ? _redSub : _inkFade,
                                letterSpacing: 3.5,
                                fontWeight: FontWeight.w400,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        S.isKo ? '시작.' : 'Begin.',
                        style: S.isKo
                            ? GoogleFonts.notoSerifKr(
                                fontSize: 34,
                                color: active
                                    ? _red
                                    : _red.withValues(alpha: 0.45),
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              )
                            : GoogleFonts.playfairDisplay(
                                fontStyle: FontStyle.italic,
                                fontSize: 34,
                                color: active
                                    ? _red
                                    : _red.withValues(alpha: 0.45),
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w900,
                                height: 1.05,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    final label =
        countdownValue > 0 ? '$countdownValue' : (S.isKo ? '달려' : 'run');
    return Container(
      color: _bg.withValues(alpha: 0.97),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.playfairDisplay(
                fontStyle: FontStyle.italic,
                fontSize: 180,
                color: _ink,
                height: 1,
                fontWeight: FontWeight.w900,
                shadows: const [
                  Shadow(color: Color(0xAA8B0000), blurRadius: 60),
                  Shadow(color: Color(0x88C83030), blurRadius: 120),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              S.isKo
                  ? (countdownValue > 0 ? '— 준비 —' : '— 지금 —')
                  : (countdownValue > 0 ? '— ready —' : '— now —'),
              style: S.isKo
                  ? GoogleFonts.notoSerifKr(
                      fontSize: 13,
                      color: _redSub,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w500,
                    )
                  : GoogleFonts.playfairDisplay(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: _redSub,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w400,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
