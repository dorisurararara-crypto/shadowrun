import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';

/// 러닝 상세 화면 하단에 삽입되는 분석 섹션 — 공통 구현.
/// - 1km splits 막대
/// - 페이스 분포 (easy/chase/sprint) 스택 막대
class ResultDetailSection extends StatefulWidget {
  final int runId;
  final AnalyticsPalette palette;
  const ResultDetailSection({super.key, required this.runId, required this.palette});

  @override
  State<ResultDetailSection> createState() => _ResultDetailSectionState();
}

class _ResultDetailSectionState extends State<ResultDetailSection> {
  late Future<_DetailData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DetailData> _load() async {
    final splits = await DatabaseHelper.getSplits(widget.runId);
    final dist = await DatabaseHelper.getPaceDistribution(widget.runId);
    return _DetailData(splits: splits, distribution: dist);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DetailData>(
      future: _future,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const SizedBox(height: 40);
        }
        final d = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _splitsCard(d.splits),
            const SizedBox(height: 12),
            _paceDistributionCard(d.distribution),
          ],
        );
      },
    );
  }

  // ─── Splits card ───────────────────────────────────────────
  Widget _splitsCard(List<Map<String, dynamic>> splits) {
    if (splits.isEmpty) {
      return _labelBox(
        S.isKo ? '구간 기록' : 'splits',
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            S.isKo ? '1km 구간 데이터 부족' : 'not enough data for 1K splits',
            style: GoogleFonts.getFont(widget.palette.bodyFamily,
                fontSize: 12, color: widget.palette.muted),
          ),
        ),
      );
    }
    final maxSec = splits
        .map((s) => (s['seconds'] as int))
        .fold<int>(1, (p, v) => v > p ? v : p);

    return _labelBox(
      S.isKo ? '1km 구간' : '1K splits',
      Column(
        children: [
          const SizedBox(height: 10),
          for (final s in splits)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      'K${s['km']}',
                      style: GoogleFonts.getFont(widget.palette.numFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.palette.muted),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: (s['seconds'] as int) / maxSec,
                        minHeight: 8,
                        backgroundColor: widget.palette.fade.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation(widget.palette.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 50,
                    child: Text(
                      _fmtSec(s['seconds'] as int),
                      textAlign: TextAlign.right,
                      style: GoogleFonts.getFont(widget.palette.numFamily,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: widget.palette.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Pace distribution stacked bar ─────────────────────────
  Widget _paceDistributionCard(Map<String, int> dist) {
    final easy = dist['easy'] ?? 0;
    final chase = dist['chase'] ?? 0;
    final sprint = dist['sprint'] ?? 0;
    final total = easy + chase + sprint;
    if (total == 0) {
      return _labelBox(
        S.isKo ? '페이스 분포' : 'pace distribution',
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            S.isKo ? '페이스 데이터 부족' : 'no pace data',
            style: GoogleFonts.getFont(widget.palette.bodyFamily,
                fontSize: 12, color: widget.palette.muted),
          ),
        ),
      );
    }
    final sections = <PieChartSectionData>[];
    final legends = <Widget>[];

    void add(String label, int sec, Color color) {
      if (sec <= 0) return;
      sections.add(PieChartSectionData(
        value: sec.toDouble(),
        color: color,
        title: '',
        radius: 42,
      ));
      legends.add(Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.getFont(widget.palette.bodyFamily,
                  fontSize: 11, color: widget.palette.muted),
            ),
            const Spacer(),
            Text(
              _fmtSec(sec),
              style: GoogleFonts.getFont(widget.palette.numFamily,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.palette.text),
            ),
          ],
        ),
      ));
    }

    add(
      S.isKo ? '여유 (>6:30)' : 'easy (>6:30)',
      easy,
      widget.palette.fade,
    );
    add(
      S.isKo ? '추격 (5:00~6:30)' : 'chase (5:00~6:30)',
      chase,
      widget.palette.accent.withValues(alpha: 0.7),
    );
    add(
      S.isKo ? '스프린트 (<5:00)' : 'sprint (<5:00)',
      sprint,
      widget.palette.danger,
    );

    return _labelBox(
      S.isKo ? '페이스 분포' : 'pace distribution',
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              height: 110,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 28,
                ),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(child: Column(children: legends)),
          ],
        ),
      ),
    );
  }

  Widget _labelBox(String label, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: widget.palette.card,
        border: Border.all(color: widget.palette.border, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.getFont(widget.palette.bodyFamily,
                fontSize: 11,
                color: widget.palette.muted,
                letterSpacing: 1.5),
          ),
          child,
        ],
      ),
    );
  }

  static String _fmtSec(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return "$m'${sec.toString().padLeft(2, '0')}\"";
  }
}

class _DetailData {
  final List<Map<String, dynamic>> splits;
  final Map<String, int> distribution;
  _DetailData({required this.splits, required this.distribution});
}
