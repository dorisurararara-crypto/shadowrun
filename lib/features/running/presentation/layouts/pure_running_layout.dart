import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T1 Pure Cinematic 테마의 러닝 중 화면.
///
/// 순수 StatelessWidget. 타이머·GPS·오디오 등 실시간 로직은
/// [RunningScreen] 에서 이미 돌아가며 값만 props로 주입된다.
/// 이 위젯은 값을 받아 "순검정 · 오프화이트 · 블러드 레드"
/// 미니멀 시네마 톤으로 그리기만 한다.
class PureRunningLayout extends StatelessWidget {
  final int elapsedSeconds;
  final double distanceM;
  final String paceText;

  /// 도플갱어와의 거리(m). 양수 = 그림자가 뒤(안전), 음수 = 앞(위험).
  /// 도플갱어 모드가 아닐 때는 double.infinity 가능.
  final double shadowGapM;
  final bool isPaused;
  final VoidCallback onPauseTap;
  final VoidCallback onStopTap;
  final bool isChallenge;
  final String runMode;
  final Widget mapChild;
  final bool ttsOn;
  final bool sfxOn;
  final VoidCallback onToggleTts;
  final VoidCallback onToggleSfx;

  const PureRunningLayout({
    super.key,
    required this.elapsedSeconds,
    required this.distanceM,
    required this.paceText,
    required this.shadowGapM,
    required this.isPaused,
    required this.onPauseTap,
    required this.onStopTap,
    required this.isChallenge,
    this.runMode = 'freerun',
    required this.mapChild,
    required this.ttsOn,
    required this.sfxOn,
    required this.onToggleTts,
    required this.onToggleSfx,
  });

  // Palette — full-t1-pure.html 과 동일
  static const _bg = Color(0xFF000000);
  static const _bgPage = Color(0xFF050507);
  static const _ink = Color(0xFFF5F5F5);
  static const _inkDim = Color(0xFF9A9A9A);
  static const _inkFade = Color(0xFF5A5A5E);
  static const _redSub = Color(0xFFC83030);
  static const _hair = Color(0x14F5F5F5);          // rgba(245,245,245,0.08)
  static const _hairRed = Color(0x528B0000);       // rgba(139,0,0,0.32)

  String _fmtDuration(int sec) {
    final s = sec < 0 ? 0 : sec;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final ss = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  /// 거리(m) → "3.42" (km/mi) / "152" (m/yd). 단위 토글 반영.
  ({String value, String unit}) _fmtDistance(double m) {
    if (RunModel.useMiles) {
      final miles = m / 1609.344;
      if (miles >= 0.1) return (value: miles.toStringAsFixed(2), unit: 'mi');
      return (value: (m * 1.09361).toInt().toString(), unit: 'yd');
    }
    if (m >= 1000) {
      return (value: (m / 1000).toStringAsFixed(2), unit: 'km');
    }
    return (value: m.toInt().toString(), unit: 'm');
  }

  /// 도플갱어까지의 거리 표시. 양수 = 뒤(behind), 음수 = 앞(ahead · 위험).
  /// 미지/미시작 시 '--'.
  ({String num, String unit, String narr, bool danger}) _shadowDisplay() {
    final isKo = S.isKo;
    if (!isChallenge || shadowGapM.isInfinite || shadowGapM.isNaN) {
      final isMarathon = runMode == 'marathon';
      final useMi = RunModel.useMiles;
      final primary = useMi ? distanceM / 1609.344 : distanceM / 1000.0;
      final unitKo = useMi ? '마일' : '킬로미터';
      final unitEn = useMi ? 'miles' : 'kilometers';
      return (
        num: primary >= 10 ? primary.toStringAsFixed(1) : primary.toStringAsFixed(2),
        unit: isMarathon
            ? (isKo ? '$unitKo · 전설과 함께' : '$unitEn · chasing legends')
            : (isKo ? '$unitKo · 혼자 달리기' : '$unitEn · solo run'),
        narr: isMarathon ? '전설의 페이스가 곁을 달린다.' : '오늘은 혼자 달린다.',
        danger: false,
      );
    }
    final absVal = shadowGapM.abs().round();
    final behind = shadowGapM >= 0;
    if (behind) {
      return (
        num: absVal.toString(),
        unit: isKo ? '미터 · 뒤에 있다' : 'meters · behind you',
        narr: '그는 점점 가까워지고 있다.',
        danger: false,
      );
    }
    return (
      num: absVal.toString(),
      unit: isKo ? '미터 · 앞서 있다 · 위험' : 'meters · ahead · danger',
      narr: '그가 당신을 앞섰다.',
      danger: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shadow = _shadowDisplay();

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // 배경 — 살짝 red tint 그라디언트
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.5),
                    radius: 1.2,
                    colors: [
                      const Color(0xFF1A0606).withValues(alpha: 0.6),
                      _bgPage,
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // 상단 경고 배너 — ● CHASING ●
                _buildChasingBar(),
                // 중앙: 캡션 + 거대 숫자 + 나레이션
                _buildCenter(shadow),
                // 미니맵
                _buildMapBox(),
                const SizedBox(height: 14),
                // 하단 통계 3칸
                _buildStatsRow(),
                const Spacer(),
                // 일시정지 버튼 + 멈춘다 버튼
                _buildBottomButtons(context),
              ],
            ),
          ),

          // 오디오 토글 (왼쪽 중앙)
          Positioned(
            left: 12,
            top: MediaQuery.of(context).size.height * 0.45,
            child: _buildAudioToggles(),
          ),
        ],
      ),
    );
  }

  // === Chasing 배너 ===
  Widget _buildChasingBar() {
    final isKo = S.isKo;
    final label = isPaused
        ? (isKo ? '일시정지' : 'PAUSED')
        : (isChallenge ? (isKo ? '추격 중' : 'CHASING') : (isKo ? '진행 중' : 'LIVE'));
    return Container(
      margin: const EdgeInsets.fromLTRB(28, 12, 28, 0),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _hairRed, width: 1),
          bottom: BorderSide(color: _hairRed, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const _BlinkingDot(color: _redSub, size: 7),
          const SizedBox(width: 10),
          Text(
            label,
            style: isKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _redSub,
                    letterSpacing: 5,
                  )
                : GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w700,
                    color: _redSub,
                    letterSpacing: 5,
                  ),
          ),
          const SizedBox(width: 10),
          const _BlinkingDot(color: _redSub, size: 7),
        ],
      ),
    );
  }

  // === 중앙 큰 숫자 ===
  Widget _buildCenter(({String num, String unit, String narr, bool danger}) shadow) {
    final isSolo = !isChallenge || shadowGapM.isInfinite || shadowGapM.isNaN;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Column(
        children: [
          // Episode tag
          Text(
            isSolo
                ? (S.isKo ? '오늘의 거리' : 'tonight\'s distance')
                : (S.isKo ? '도플갱어와의 거리' : 'Distance from the Doppelgänger'),
            style: S.isKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 11,
                    color: _inkFade,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.playfairDisplay(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: _inkFade,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w400,
                  ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          // 거대 숫자 — Playfair Italic. 3자리 숫자가 아래 unit 라인과 겹치지 않게
          // fontSize 140 → 108, height 0.9 → 1.0, glow blur 축소, letterSpacing 0.
          Text(
            shadow.num,
            style: GoogleFonts.playfairDisplay(
              fontSize: 108,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              color: _ink,
              height: 1.0,
              letterSpacing: -3,
              shadows: const [
                Shadow(color: Color(0x668B0000), blurRadius: 24),
                Shadow(color: Color(0x338B0000), blurRadius: 48),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // meters · behind you
          Text(
            shadow.unit,
            style: S.isKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 15,
                    color: _redSub,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: _redSub,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w400,
                  ),
          ),
          const SizedBox(height: 10),
          // 나레이션 — 노토 세리프 KR
          Text(
            shadow.narr,
            style: GoogleFonts.notoSerifKr(
              fontSize: 12,
              color: _inkDim,
              fontWeight: FontWeight.w300,
              height: 1.5,
              fontStyle: shadow.danger ? FontStyle.italic : FontStyle.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // === 미니맵 ===
  Widget _buildMapBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          border: Border.all(color: _hair, width: 1),
          gradient: const RadialGradient(
            center: Alignment(0.3, -0.1),
            radius: 1.2,
            colors: [Color(0x47C83030), Color(0xFF0A0A0C)],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: mapChild),
            // 하단 페이드 그림자 (시네마틱 레터박스 느낌)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 30,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === 하단 통계 3칸 (상하 헤어라인) ===
  Widget _buildStatsRow() {
    final dist = _fmtDistance(distanceM);
    final timeStr = _fmtDuration(elapsedSeconds);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _hair, width: 1),
          bottom: BorderSide(color: _hair, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _statCell(label: S.isKo ? '시간' : 'ELAPSED', value: timeStr, unit: '')),
          Container(width: 1, height: 36, color: _hair),
          Expanded(child: _statCell(label: S.isKo ? '거리' : 'DISTANCE', value: dist.value, unit: dist.unit)),
          Container(width: 1, height: 36, color: _hair),
          Expanded(child: _statCell(label: S.isKo ? '페이스 /KM' : 'PACE /KM', value: paceText, unit: '')),
        ],
      ),
    );
  }

  Widget _statCell({required String label, required String value, required String unit}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    color: _ink,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 11,
                      color: _inkFade,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.normal,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: S.isKo
                ? GoogleFonts.notoSerifKr(
                    fontSize: 9.5,
                    color: _inkFade,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.playfairDisplay(
                    fontSize: 9.5,
                    fontStyle: FontStyle.italic,
                    color: _inkFade,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                  ),
          ),
        ],
      ),
    );
  }

  // === 하단 버튼 — 일시정지 원형 + 멈춘다 ===
  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 16, 28, MediaQuery.of(context).padding.bottom + 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 일시정지 원형 (blood red outline)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onPauseTap,
            child: SizedBox(
              width: 64,
              height: 64,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0A0405),
                  border: Border.all(color: _redSub, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _redSub.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: isPaused
                      ? Icon(Icons.play_arrow_rounded, color: _redSub, size: 26)
                      : _buildPauseBars(),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          // 멈춘다 (stop)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onStopTap,
              child: SizedBox(
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: _hair, width: 1),
                    color: const Color(0x66000000),
                  ),
                  child: Center(
                    child: Text(
                      S.isKo ? '필름 정지' : 'STOP THE FILM',
                      style: S.isKo
                          ? GoogleFonts.notoSerifKr(
                              fontSize: 12,
                              color: _inkDim,
                              letterSpacing: 5,
                              fontWeight: FontWeight.w500,
                            )
                          : GoogleFonts.playfairDisplay(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: _inkDim,
                              letterSpacing: 5,
                              fontWeight: FontWeight.w400,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseBars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 4, height: 18, color: _redSub),
        const SizedBox(width: 5),
        Container(width: 4, height: 18, color: _redSub),
      ],
    );
  }

  // === 오디오 토글 ===
  Widget _buildAudioToggles() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _audioBtn(icon: ttsOn ? Icons.mic : Icons.mic_off, active: ttsOn, onTap: onToggleTts),
        const SizedBox(height: 8),
        _audioBtn(icon: sfxOn ? Icons.volume_up : Icons.volume_off, active: sfxOn, onTap: onToggleSfx),
      ],
    );
  }

  Widget _audioBtn({required IconData icon, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? const Color(0x99100606) : const Color(0x4D100606),
            shape: BoxShape.circle,
            border: Border.all(color: _hair, width: 1),
          ),
          child: Icon(icon, size: 14, color: active ? _ink : _inkFade),
        ),
      ),
    );
  }
}

/// 깜빡이는 점. TweenAnimationBuilder 대신 AnimationController 반복.
class _BlinkingDot extends StatefulWidget {
  final Color color;
  final double size;
  const _BlinkingDot({required this.color, required this.size});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final op = _c.value < 0.6 ? 1.0 : 0.2;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: op),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.6 * op),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
