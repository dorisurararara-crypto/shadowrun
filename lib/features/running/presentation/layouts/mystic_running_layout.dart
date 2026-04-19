import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T3 Korean Mystic 테마의 러닝 중 화면.
///
/// 순수 StatelessWidget. 타이머·GPS·오디오·HealthService 등 실시간 로직은
/// 기존 [RunningScreen] 내부에서 이미 돌아가고 있으며, 그 값이 props로 주입된다.
/// 이 위젯은 값을 받아 "한국 민속 호러" 톤으로 그리기만 한다.
class MysticRunningLayout extends StatelessWidget {
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
  final Widget mapChild;
  final bool ttsOn;
  final bool sfxOn;
  final VoidCallback onToggleTts;
  final VoidCallback onToggleSfx;

  const MysticRunningLayout({
    super.key,
    required this.elapsedSeconds,
    required this.distanceM,
    required this.paceText,
    required this.shadowGapM,
    required this.isPaused,
    required this.onPauseTap,
    required this.onStopTap,
    required this.isChallenge,
    required this.mapChild,
    required this.ttsOn,
    required this.sfxOn,
    required this.onToggleTts,
    required this.onToggleSfx,
  });

  // Palette — mystic_home_layout.dart 와 동일 톤.
  static const _ink = Color(0xFF040202);
  static const _inkSoft = Color(0xFF0C0506);
  static const _rice = Color(0xFFF0EBE3);
  static const _riceFade = Color(0xFF7A6858);
  static const _bloodFresh = Color(0xFFC42029);
  static const _line = Color(0xFF241618);

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

  /// 도플갱어까지의 거리. 양수 = 뒤, 음수 = 앞(잡힘 직전).
  /// 미지/미시작 시 '--'.
  ({String num, String label, bool danger}) _shadowDisplay() {
    if (!isChallenge || shadowGapM.isInfinite || shadowGapM.isNaN) {
      return (num: '--', label: '그 림 자 없 음', danger: false);
    }
    final absVal = shadowGapM.abs().round();
    final behind = shadowGapM >= 0;
    return (
      num: absVal.toString(),
      label: behind ? '뒤 · B E H I N D' : '앞 · AHEAD · 위 험',
      danger: !behind,
    );
  }

  @override
  Widget build(BuildContext context) {
    final shadow = _shadowDisplay();
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          // 배경 한자 워터마크 (오른쪽 상단)
          Positioned(
            right: -50,
            top: screenSize.height * 0.16,
            child: const IgnorePointer(
              child: Text(
                '追',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 280,
                  color: Color(0xFF150606),
                  height: 0.9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          // 배경 한자 워터마크 (왼쪽 하단)
          const Positioned(
            left: -30,
            bottom: -40,
            child: IgnorePointer(
              child: Text(
                '走',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 200,
                  color: Color(0xFF0E0404),
                  height: 0.85,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          // 본문
          SafeArea(
            child: Column(
              children: [
                // 상단 헤더
                _buildHeader(shadow.danger),
                // 거대한 거리 숫자
                _buildShadowDistance(shadow.num, shadow.label, shadow.danger),
                // 미니맵
                _buildMapBox(),
                const SizedBox(height: 18),
                // 통계 3칸
                _buildStatsRow(),
                const Spacer(),
                // 하단 버튼 (숨 고르기 / 멈춘다)
                _buildBottomButtons(context),
              ],
            ),
          ),

          // 오디오 컨트롤 (왼쪽 중앙)
          Positioned(
            left: 12,
            top: screenSize.height * 0.45,
            child: _buildAudioToggles(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool danger) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          // "追" 한자
          Text(
            '追',
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 22,
              color: _bloodFresh,
              letterSpacing: 4,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          // 경고 배지 (깜빡이는 점)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x1AC42029),
              border: Border.all(color: const Color(0x59C42029), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BlinkingDot(color: _bloodFresh, size: 7),
                const SizedBox(width: 8),
                Text(
                  isPaused
                      ? '숨 · 고 르 는 · 중'
                      : (danger ? '지 금 · 경 고' : '지 금 · 추 격'),
                  style: GoogleFonts.gowunBatang(
                    fontSize: 11,
                    color: _bloodFresh,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowDistance(String num, String label, bool danger) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Column(
        children: [
          Text(
            '그 림 자 까 지',
            style: GoogleFonts.gowunBatang(
              fontSize: 10,
              color: _riceFade,
              letterSpacing: 5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          // 숫자 + 米
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                num,
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 108,
                  color: _rice,
                  height: 1.0,
                  letterSpacing: -1,
                  fontWeight: FontWeight.w800,
                  shadows: const [
                    Shadow(color: Color(0x66C42029), blurRadius: 24),
                    Shadow(color: Color(0x33C42029), blurRadius: 48),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  '米',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 36,
                    color: _bloodFresh,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.gowunBatang(
              fontSize: 11,
              color: _bloodFresh,
              letterSpacing: 4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: _inkSoft,
          border: Border.all(color: _line, width: 1),
          gradient: const RadialGradient(
            center: Alignment(0.4, -0.4),
            radius: 1.2,
            colors: [Color(0x26C42029), _inkSoft],
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(child: mapChild),
            // 범례 — 나 / 影
            Positioned(
              top: 8,
              right: 10,
              child: Row(
                children: [
                  _legendDot(color: _rice, label: '나', labelColor: _rice),
                  const SizedBox(width: 12),
                  _legendDot(color: _bloodFresh, label: '影', labelColor: _bloodFresh),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot({required Color color, required String label, required Color labelColor}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.gowunBatang(
            fontSize: 9,
            color: labelColor,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final dist = _fmtDistance(distanceM);
    final timeStr = _fmtDuration(elapsedSeconds);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: _line, width: 1),
          bottom: BorderSide(color: _line, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _statCell(label: '거 리', value: dist.value, unit: dist.unit)),
          Container(width: 1, height: 44, color: _line),
          Expanded(child: _statCell(label: '시 간', value: timeStr, unit: '')),
          Container(width: 1, height: 44, color: _line),
          Expanded(child: _statCell(label: '페 이 스', value: paceText, unit: '', red: true)),
        ],
      ),
    );
  }

  Widget _statCell({required String label, required String value, required String unit, bool red = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.gowunBatang(
              fontSize: 10,
              color: _riceFade,
              letterSpacing: 3,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 20,
                    color: red ? _bloodFresh : _rice,
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: GoogleFonts.gowunBatang(
                      fontSize: 10,
                      color: _riceFade,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 20),
      child: Row(
        children: [
          // 숨 고르기 (pause/resume)
          Expanded(
            child: InkWell(
              onTap: onPauseTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0x99100606),
                  border: Border.all(color: _line, width: 1),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: _rice,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPaused ? '다 시 · 뛰 다' : '숨 고 르 기',
                      style: GoogleFonts.gowunBatang(
                        fontSize: 12,
                        color: _rice,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 멈춘다 (stop)
          Expanded(
            child: InkWell(
              onTap: onStopTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0x1FC42029),
                  border: Border.all(color: _bloodFresh, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(
                  '멈 춘 다',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 13,
                    color: _bloodFresh,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioToggles() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _audioBtn(
          icon: ttsOn ? Icons.mic : Icons.mic_off,
          active: ttsOn,
          onTap: onToggleTts,
        ),
        const SizedBox(height: 8),
        _audioBtn(
          icon: sfxOn ? Icons.volume_up : Icons.volume_off,
          active: sfxOn,
          onTap: onToggleSfx,
        ),
      ],
    );
  }

  Widget _audioBtn({required IconData icon, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: active ? const Color(0x99100606) : const Color(0x4D100606),
          shape: BoxShape.circle,
          border: Border.all(color: _line, width: 1),
        ),
        child: Icon(
          icon,
          size: 14,
          color: active ? _rice : _riceFade,
        ),
      ),
    );
  }
}

/// 단순 깜빡이는 점. 애니메이션 최소화 — TweenAnimationBuilder로 반복.
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
      duration: const Duration(milliseconds: 1200),
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
        final op = _c.value < 0.55 ? 1.0 : 0.25;
        return Container(
          width: widget.size,
          height: widget.size,
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
        );
      },
    );
  }
}
