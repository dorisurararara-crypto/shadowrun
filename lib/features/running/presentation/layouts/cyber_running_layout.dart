import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T5 Neo-Noir Cyber 러닝 화면. Blade Runner HUD 톤.
class CyberRunningLayout extends StatelessWidget {
  final int elapsedSeconds;
  final double distanceM;
  final String paceText;
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

  const CyberRunningLayout({
    super.key,
    required this.elapsedSeconds,
    required this.distanceM,
    required this.paceText,
    required this.shadowGapM,
    required this.isPaused,
    required this.onPauseTap,
    required this.onStopTap,
    required this.isChallenge,
    required this.runMode,
    required this.mapChild,
    required this.ttsOn,
    required this.sfxOn,
    required this.onToggleTts,
    required this.onToggleSfx,
  });

  static const _bg = Color(0xFF04040A);
  static const _red = Color(0xFFFF1744);
  static const _cyan = Color(0xFF4DD0E1);
  static const _text = Color(0xFFE8E8F0);
  static const _textFade = Color(0xFF5A5A68);
  static const _borderCyan = Color(0x264DD0E1);
  static const _panel = Color(0x0A4DD0E1);

  String _fmtDuration(int s) {
    final v = s < 0 ? 0 : s;
    final h = v ~/ 3600;
    final m = (v % 3600) ~/ 60;
    final ss = v % 60;
    return h > 0
        ? '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}'
        : '${m.toString().padLeft(2, '0')}:${ss.toString().padLeft(2, '0')}';
  }

  ({String value, String unit}) _fmtDistance(double m) {
    if (RunModel.useMiles) {
      final miles = m / 1609.344;
      if (miles >= 0.1) return (value: miles.toStringAsFixed(2), unit: 'MI');
      return (value: (m * 1.09361).toInt().toString(), unit: 'YD');
    }
    if (m >= 1000) return (value: (m / 1000).toStringAsFixed(2), unit: 'KM');
    return (value: m.toInt().toString(), unit: 'M');
  }

  @override
  Widget build(BuildContext context) {
    final dist = _fmtDistance(distanceM);
    final gap = shadowGapM.isFinite ? shadowGapM.round() : null;
    final gapDanger = gap != null && gap < 0;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // Background glows
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.7, -1.1),
                  radius: 1.1,
                  colors: [_red.withValues(alpha: 0.14), Colors.transparent],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.0, 1.0),
                  radius: 1.0,
                  colors: [_cyan.withValues(alpha: 0.08), Colors.transparent],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _ScanLines()),

          SafeArea(
            child: Column(
              children: [
                // ── Tag + time ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: _red),
                          color: const Color(0x0AFF1744),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Blink(color: _red, size: 6),
                            const SizedBox(width: 8),
                            Text(
                              isPaused
                                  ? 'TRACKING · PAUSED'
                                  : (runMode == 'doppelganger' ? 'ENTITY · LIVE' : 'TRACKING · LIVE'),
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 9,
                                color: _red,
                                letterSpacing: 2.2,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _fmtDuration(elapsedSeconds),
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 18,
                          color: _cyan,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Coord line ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: [
                      Text(
                        '// DISTANCE TRAVELED',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: _cyan,
                          letterSpacing: 2.6,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        runMode == 'doppelganger' ? 'MODE · CHASE' : runMode == 'marathon' ? 'MODE · MARATHON' : 'MODE · FREE',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: _textFade,
                          letterSpacing: 2.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Distance hero with chromatic aberration ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 10),
                  child: _chromaticNumber(dist.value, dist.unit),
                ),

                // ── Entity gap or pace panel ──
                if (isChallenge && gap != null)
                  _entityBar(gap, gapDanger)
                else
                  _paceBar(),

                const SizedBox(height: 10),

                // ── Map ──
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 22),
                    decoration: BoxDecoration(
                      border: Border.all(color: _borderCyan),
                      color: _panel,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: mapChild,
                  ),
                ),

                const SizedBox(height: 12),

                // ── Metric strip ──
                _metricRow(),
                const SizedBox(height: 12),

                // ── Buttons ──
                _buttons(),
                const SizedBox(height: 10),
              ],
            ),
          ),

          Positioned(
            left: 10,
            top: MediaQuery.of(context).size.height * 0.34,
            child: _audioToggles(),
          ),
        ],
      ),
    );
  }

  Widget _chromaticNumber(String value, String unit) {
    final base = GoogleFonts.jetBrainsMono(
      fontSize: 92,
      fontWeight: FontWeight.w700,
      height: 0.9,
      letterSpacing: -4,
    );
    Widget layer(Color c, Offset o, double a) => Transform.translate(
          offset: o,
          child: Opacity(
            opacity: a,
            child: Text(value, style: base.copyWith(color: c)),
          ),
        );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox(
          height: 92,
          child: Stack(
            children: [
              layer(_cyan, const Offset(2, 0), 0.55),
              layer(_red, const Offset(-2, 0), 0.55),
              Text(value, style: base.copyWith(color: _text)),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            unit,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              color: _red,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _entityBar(int gap, bool danger) {
    final color = danger ? _red : _cyan;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.45)),
        color: color.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Text(
            danger ? '// ENTITY CLOSING' : '// ENTITY TRACE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: color,
              letterSpacing: 2.6,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            danger ? '−${gap.abs().toString().padLeft(3, '0')}m' : '+${gap.toString().padLeft(3, '0')}m',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 20,
              color: color,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: color.withValues(alpha: 0.5), blurRadius: 10)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _paceBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 22),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: _borderCyan),
        color: _panel,
      ),
      child: Row(
        children: [
          Text(
            '// CURRENT PACE',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: _cyan,
              letterSpacing: 2.6,
            ),
          ),
          const Spacer(),
          Text(
            '$paceText ${RunModel.useMiles ? "/mi" : "/km"}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 18,
              color: _text,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(child: _cell('PACE', '$paceText ${RunModel.useMiles ? "/mi" : "/km"}')),
          Container(width: 1, height: 30, color: _borderCyan),
          Expanded(child: _cell('T+', _fmtDuration(elapsedSeconds))),
        ],
      ),
    );
  }

  Widget _cell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 8,
              color: _cyan,
              letterSpacing: 2.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              color: _text,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onPauseTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: _cyan),
                  color: _panel,
                ),
                alignment: Alignment.center,
                child: Text(
                  isPaused ? '[ RESUME ]' : '[ PAUSE ]',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: _cyan,
                    letterSpacing: 2.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: onStopTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_red, Color(0xFFAA0A28)],
                  ),
                  border: Border.all(color: _red),
                  boxShadow: [
                    BoxShadow(
                      color: _red.withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                child: Text(
                  '[ TERMINATE ]',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: Colors.white,
                    letterSpacing: 2.8,
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

  Widget _audioToggles() {
    return Column(
      children: [
        _btn('VOX', ttsOn, onToggleTts),
        const SizedBox(height: 6),
        _btn('SFX', sfxOn, onToggleSfx),
      ],
    );
  }

  Widget _btn(String label, bool active, VoidCallback onTap) {
    final c = active ? _cyan : _textFade;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(border: Border.all(color: c), color: _panel),
        child: Text(
          active ? label : '$label:OFF',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9,
            color: c,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Blink extends StatefulWidget {
  final Color color;
  final double size;
  const _Blink({required this.color, required this.size});
  @override
  State<_Blink> createState() => _BlinkState();
}

class _BlinkState extends State<_Blink> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.25, end: 1.0).animate(_c),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: widget.color.withValues(alpha: 0.7), blurRadius: 8)],
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
