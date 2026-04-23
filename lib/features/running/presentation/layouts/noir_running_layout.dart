import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/shared/models/run_model.dart';

/// T2 Film Noir 러닝 화면. 1940s 탐정 파일 톤.
class NoirRunningLayout extends StatelessWidget {
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

  const NoirRunningLayout({
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

  static const _ink = Color(0xFF0D0907);
  static const _paper = Color(0xFFE8DCC4);
  static const _paperFade = Color(0xFF6A5D48);
  static const _brass = Color(0xFFB89660);
  static const _wine = Color(0xFF8B2635);
  static const _line = Color(0xFF2A1D10);

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
      backgroundColor: _ink,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Status stamp + time ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(border: Border.all(color: _brass)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _Dot(color: isPaused ? _paperFade : _wine, size: 6),
                            const SizedBox(width: 8),
                            Text(
                              isPaused ? 'CASE ON HOLD' : 'CASE LIVE',
                              style: GoogleFonts.oswald(
                                fontSize: 10,
                                color: _brass,
                                letterSpacing: 3.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _fmtDuration(elapsedSeconds),
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontStyle: FontStyle.italic,
                          color: _paper,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Hero distance ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Text(
                        'DISTANCE ON FOOT',
                        style: GoogleFonts.oswald(
                          fontSize: 9,
                          color: _paperFade,
                          letterSpacing: 4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: dist.value,
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 100,
                                fontStyle: FontStyle.italic,
                                color: _paper,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                letterSpacing: -2,
                                shadows: const [
                                  Shadow(color: Color(0x40B89660), blurRadius: 24),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: ' ${dist.unit}',
                              style: GoogleFonts.oswald(
                                fontSize: 22,
                                color: _brass,
                                letterSpacing: 3,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                // ── Subject gap (challenge) OR pace/time info ──
                if (isChallenge && gap != null)
                  _statBar(
                    label: gapDanger ? 'SUBJECT CLOSING' : 'SUBJECT BEHIND',
                    value: gapDanger ? '−${gap.abs()}' : '+$gap',
                    unit: 'M',
                    color: gapDanger ? _wine : _brass,
                  )
                else
                  _statBar(
                    label: 'CURRENT PACE',
                    value: paceText,
                    unit: RunModel.useMiles ? '/MI' : '/KM',
                    color: _brass,
                  ),

                const SizedBox(height: 14),

                // ── Map ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: _brass.withValues(alpha: 0.4)),
                        color: const Color(0xFF160E08),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: mapChild,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Bottom: pace / time row ──
                _bottomStats(),
                const SizedBox(height: 16),

                // ── Action buttons ──
                _actionButtons(),
                const SizedBox(height: 10),
              ],
            ),

            // Audio toggles (left-center)
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

  Widget _statBar({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        border: const Border(
          top: BorderSide(color: _line),
          bottom: BorderSide(color: _line),
        ),
        color: color.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.oswald(
              fontSize: 10,
              color: color,
              letterSpacing: 3,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 24,
                    fontStyle: FontStyle.italic,
                    color: color,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.oswald(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(child: _metricCell('PACE', paceText, RunModel.useMiles ? '/MI' : '/KM')),
          Container(width: 1, height: 36, color: _line),
          Expanded(child: _metricCell('ELAPSED', _fmtDuration(elapsedSeconds), '')),
        ],
      ),
    );
  }

  Widget _metricCell(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 9,
            color: _paperFade,
            letterSpacing: 3,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 22,
                  fontStyle: FontStyle.italic,
                  color: _paper,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              if (unit.isNotEmpty)
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.oswald(
                    fontSize: 9,
                    color: _paperFade,
                    letterSpacing: 2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButtons() {
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
                decoration: BoxDecoration(
                  border: Border.all(color: _brass),
                  color: _brass.withValues(alpha: 0.06),
                ),
                alignment: Alignment.center,
                child: Text(
                  isPaused ? 'RESUME CHASE' : 'CATCH BREATH',
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    color: _brass,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w500,
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: _wine),
                  color: _wine.withValues(alpha: 0.12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'CLOSE CASE',
                  style: GoogleFonts.oswald(
                    fontSize: 12,
                    color: _wine,
                    letterSpacing: 3.5,
                    fontWeight: FontWeight.w600,
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
        _audioBtn(
          label: ttsOn ? 'VOX' : 'VOX·OFF',
          onTap: onToggleTts,
          active: ttsOn,
        ),
        const SizedBox(height: 6),
        _audioBtn(
          label: sfxOn ? 'SFX' : 'SFX·OFF',
          onTap: onToggleSfx,
          active: sfxOn,
        ),
      ],
    );
  }

  Widget _audioBtn({required String label, required VoidCallback onTap, required bool active}) {
    final c = active ? _brass : _paperFade;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(border: Border.all(color: c)),
        child: Text(
          label,
          style: GoogleFonts.oswald(
            fontSize: 9,
            color: c,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  final double size;
  const _Dot({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 6)],
      ),
    );
  }
}
