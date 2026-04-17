import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/features/running/data/legend_runners.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T1 Pure Cinematic 테마용 Prepare 화면 레이아웃.
/// 영화 한 편의 오프닝처럼 정적 위에 블러드 레드가 한 줄의 자막처럼 스며드는 무드.
class PurePrepareLayout extends StatelessWidget {
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

  // 러닝화
  final List<Map<String, dynamic>> shoes;
  final int? selectedShoeId;
  final ValueChanged<int?> onShoeChanged;

  // 전설의 마라토너 (marathon 모드일 때)
  final String? selectedLegendId;
  final ValueChanged<String> onLegendChanged;
  final bool isPro;
  final VoidCallback onLegendLocked;

  // 액션
  final VoidCallback onStart;
  final VoidCallback onBack;

  // 카운트다운 오버레이
  final bool countdownActive;
  final int countdownValue;

  const PurePrepareLayout({
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
    required this.shoes,
    required this.selectedShoeId,
    required this.onShoeChanged,
    required this.selectedLegendId,
    required this.onLegendChanged,
    required this.isPro,
    required this.onLegendLocked,
    required this.onStart,
    required this.onBack,
    required this.countdownActive,
    required this.countdownValue,
  });

  // Pure Cinematic 팔레트
  static const _bg = Color(0xFF000000);
  static const _bgPage = Color(0xFF050507);
  static const _ink = Color(0xFFF5F5F5);
  static const _inkDim = Color(0xFF9A9A9A);
  static const _inkFade = Color(0xFF5A5A5E);
  static const _inkGhost = Color(0xFF3A3A3E);
  static const _red = Color(0xFF8B0000);
  static const _redSub = Color(0xFFC83030);
  static const _hair = Color(0x14F5F5F5);
  static const _hairRed = Color(0x528B0000);

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
                    '←  back',
                    style: GoogleFonts.playfairDisplay(
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
            'BRIEFING',
            style: GoogleFonts.playfairDisplay(
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
          _articleRow('Subject', _subjectValue()),
          _articleDivider(),
          _articleRow('Equipment', _equipmentValue()),
          _articleDivider(),
          _articleRow('Distance', _distanceValue()),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '— Pre-game —',
          style: GoogleFonts.playfairDisplay(
            fontStyle: FontStyle.italic,
            fontSize: 11,
            color: _redSub,
            letterSpacing: 3.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),
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
            ok ? 'GPS connected · signal locked' : 'searching for signal…',
            style: GoogleFonts.playfairDisplay(
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
              'more than 200m from the starting point.',
              style: GoogleFonts.playfairDisplay(
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.notoSerif(
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
              style: GoogleFonts.playfairDisplay(
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
    if (isChallenge) {
      return 'The Doppelgänger';
    }
    return selectedMode == 'marathon' ? 'Legendary Marathoners' : 'The Free Runner';
  }

  String _equipmentValue() {
    if (shoes.isEmpty) return 'Bare feet';
    if (selectedShoeId == null) return 'Not chosen';
    final match = shoes.firstWhere(
      (s) => (s['id'] as int?) == selectedShoeId,
      orElse: () => shoes.first,
    );
    return (match['name'] as String?) ?? 'Running shoes';
  }

  String _distanceValue() {
    if (isChallenge && shadowRun != null) {
      return shadowRun!.formattedDistance;
    }
    return 'Free · open';
  }

  /// 챌린지 — 그림자의 속도 (slow 6:30 / mid 5:30 / fast 4:30)
  Widget _shadowSpeedSection() {
    final paceMin = shadowRun?.avgPace ?? 5.5;
    String current;
    if (paceMin >= 6.0) {
      current = 'slow';
    } else if (paceMin <= 5.0) {
      current = 'fast';
    } else {
      current = 'mid';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Doppelgänger Pace', 'auto'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _speedOption('slow', 'slow', '6:30', current)),
            const SizedBox(width: 8),
            Expanded(child: _speedOption('mid', 'medium', '5:30', current)),
            const SizedBox(width: 8),
            Expanded(child: _speedOption('fast', 'fast', '4:30', current)),
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
        SfxService().toggle();
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
                style: GoogleFonts.playfairDisplay(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Location', 'tap to change'),
        const SizedBox(height: 12),
        _locationOption('same', 'Same ground', 'follow the shadow\'s actual path'),
        const SizedBox(height: 8),
        _locationOption('different', 'Different ground', 'only the voice follows you'),
      ],
    );
  }

  Widget _locationOption(String key, String title, String desc) {
    final on = shadowLocationType == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().toggle();
        onShadowLocationChanged(key);
      },
      child: SizedBox(
        height: 66,
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
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        color: on ? _ink : _inkDim,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: GoogleFonts.notoSerif(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Mode', 'tonight\'s run'),
        const SizedBox(height: 12),
        _modeOption('marathon', 'The Marathoners', 'world records chase you'),
        const SizedBox(height: 8),
        _modeOption('freerun', 'Free Run', 'no one follows. only you.'),
      ],
    );
  }

  Widget _modeOption(String key, String title, String desc) {
    final on = selectedMode == key;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().toggle();
        onModeChanged(key);
      },
      child: SizedBox(
        height: 66,
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
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 15,
                        color: on ? _ink : _inkDim,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: GoogleFonts.notoSerif(
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
          'select',
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

  Widget _shoeCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _sectionHeader('Footwear', 'swap'),
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
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 13,
                                color: on ? _ink : _inkDim,
                                letterSpacing: 0.2,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$totalKm km walked together',
                              style: GoogleFonts.notoSerif(
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
        _sectionHeader('Target Distance', 'edit'),
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
                  isChallenge ? 'set' : 'free',
                  style: GoogleFonts.playfairDisplay(
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.notoSerif(
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
          style: GoogleFonts.playfairDisplay(
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
                        'Tonight\'s Chase',
                        style: GoogleFonts.playfairDisplay(
                          fontStyle: FontStyle.italic,
                          fontSize: 11,
                          color: active ? _redSub : _inkFade,
                          letterSpacing: 3.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Begin.',
                        style: GoogleFonts.playfairDisplay(
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
    final label = countdownValue > 0 ? '$countdownValue' : 'run';
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
              countdownValue > 0 ? '— ready —' : '— now —',
              style: GoogleFonts.playfairDisplay(
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
