import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T4 Editorial Thriller 러닝 화면. 매거진 라이브 이슈 스타일.
class EditorialRunningLayout extends StatelessWidget {
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

  const EditorialRunningLayout({
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

  static const _ink = Color(0xFF0A0A0A);
  static const _white = Color(0xFFFFFFFF);
  static const _red = Color(0xFFDC2626);
  static const _redSoft = Color(0xFFF87171);
  static const _muted = Color(0xFF888888);
  static const _hair = Color(0x1FFFFFFF);

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
      if (miles >= 0.1) return (value: miles.toStringAsFixed(2), unit: 'mi');
      return (value: (m * 1.09361).toInt().toString(), unit: 'yd');
    }
    if (m >= 1000) return (value: (m / 1000).toStringAsFixed(2), unit: 'km');
    return (value: m.toInt().toString(), unit: 'm');
  }

  @override
  Widget build(BuildContext context) {
    final dist = _fmtDistance(distanceM);
    final gap = shadowGapM.isFinite ? shadowGapM.round() : null;
    final gapDanger = gap != null && gap < 0;

    return Scaffold(
      backgroundColor: _ink,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Live page head ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: _white, width: 2)),
                  ),
                  child: Row(
                    children: [
                      Row(
                        children: [
                          _BlinkDot(color: _red, size: 7),
                          const SizedBox(width: 8),
                          Text(
                            'LIVE · P. 03',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: _red,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 3,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        _fmtDuration(elapsedSeconds),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontStyle: FontStyle.italic,
                          color: _white,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Issue kicker ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
                  child: Row(
                    children: [
                      Text(
                        isPaused ? 'ON BREAK' : (runMode == 'doppelganger' ? 'COVER STORY' : 'FEATURE'),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: _redSoft,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(height: 1, color: _hair),
                      ),
                    ],
                  ),
                ),

                // ── Hero distance ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 24, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dist.value,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 120,
                          fontStyle: FontStyle.italic,
                          color: _white,
                          fontWeight: FontWeight.w900,
                          height: 0.9,
                          letterSpacing: -5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          dist.unit,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            color: _red,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Subject / pace line ──
                if (isChallenge && gap != null) _subjectLine(gap, gapDanger) else _paceLine(),

                const SizedBox(height: 10),

                // ── Map (borderless, thin hair top) ──
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      border: Border.all(color: _hair),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: mapChild,
                  ),
                ),

                const SizedBox(height: 14),

                // ── Metric strip ──
                _metricRow(),
                const SizedBox(height: 14),

                // ── Buttons ──
                _buttons(),
                const SizedBox(height: 10),
              ],
            ),
            Positioned(
              left: 12,
              top: MediaQuery.of(context).size.height * 0.34,
              child: _audioToggles(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subjectLine(int gap, bool danger) {
    final color = danger ? _red : _redSoft;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: danger ? _red : Colors.transparent,
        border: danger
            ? null
            : Border.all(color: _hair),
      ),
      child: Row(
        children: [
          Text(
            danger ? 'SUBJECT CLOSING' : 'SUBJECT',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: danger ? _white : _redSoft,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            danger ? '−${gap.abs()} m' : '+$gap m',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: danger ? _white : color,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paceLine() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _hair), bottom: BorderSide(color: _hair)),
      ),
      child: Row(
        children: [
          Text(
            'CURRENT PACE',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: _muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            '$paceText ${RunModel.useMiles ? "/mi" : "/km"}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: _white,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _cell('PACE', '$paceText ${RunModel.useMiles ? "/mi" : "/km"}')),
          Container(width: 1, height: 36, color: _hair),
          Expanded(child: _cell('ELAPSED', _fmtDuration(elapsedSeconds))),
        ],
      ),
    );
  }

  Widget _cell(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 8.5,
              color: _muted,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: _white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buttons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onPauseTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(border: Border.all(color: _white, width: 1.5)),
                alignment: Alignment.center,
                child: Text(
                  isPaused ? 'RESUME' : 'BREAK',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _white,
                    letterSpacing: 3.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: onStopTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: _red,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: _white.withValues(alpha: 0.3)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'STOP PRESS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _white,
                      letterSpacing: 3.5,
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
    final c = active ? _white : _muted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(border: Border.all(color: c)),
        child: Text(
          active ? label : '$label·OFF',
          style: GoogleFonts.inter(
            fontSize: 9,
            color: c,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}

class _BlinkDot extends StatefulWidget {
  final Color color;
  final double size;
  const _BlinkDot({required this.color, required this.size});

  @override
  State<_BlinkDot> createState() => _BlinkDotState();
}

class _BlinkDotState extends State<_BlinkDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
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
