import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

/// 테마 독립적인 분석 Overview.
/// 러닝 목표 링, streak, 주간 거리 막대, 히트맵 달력, PR 카드, 도플갱어 전적 카드를 한 컬럼에 표시.
///
/// 테마별 디자인은 주입된 [palette] 로 결정 — 색상/글꼴 family 만 다르고 구조는 공통.
class AnalyticsOverview extends StatefulWidget {
  final AnalyticsPalette palette;
  const AnalyticsOverview({super.key, required this.palette});

  @override
  State<AnalyticsOverview> createState() => _AnalyticsOverviewState();
}

class _AnalyticsOverviewState extends State<AnalyticsOverview> {
  late Future<_OverviewData> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadAll();
  }

  Future<_OverviewData> _loadAll() async {
    final results = await Future.wait([
      DatabaseHelper.getStats(),
      DatabaseHelper.getPersonalRecords(),
      DatabaseHelper.getDoppelgangerStats(),
      DatabaseHelper.getStreakInfo(),
      DatabaseHelper.getWeeklyStats(8),
      DatabaseHelper.getDailyDistanceMap(84),
      DatabaseHelper.getActiveGoal().then((g) => g ?? <String, dynamic>{}),
      DatabaseHelper.getGoalProgress('month'),
    ]);
    return _OverviewData(
      stats: results[0] as Map<String, dynamic>,
      records: results[1] as Map<String, dynamic>,
      dopp: results[2] as Map<String, dynamic>,
      streak: results[3] as Map<String, dynamic>,
      weekly: results[4] as List<Map<String, dynamic>>,
      dailyMap: results[5] as Map<String, double>,
      goal: results[6] as Map<String, dynamic>,
      goalProgress: results[7] as Map<String, dynamic>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OverviewData>(
      future: _future,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(
                color: widget.palette.accent,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final d = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _goalRing(d),
            const SizedBox(height: 12),
            _streakCard(d),
            const SizedBox(height: 12),
            _weeklyBar(d),
            const SizedBox(height: 12),
            _heatmapCalendar(d),
            const SizedBox(height: 12),
            _prCard(d),
            const SizedBox(height: 12),
            _doppelgangerCard(d),
          ],
        );
      },
    );
  }

  // ─── Goal ring ─────────────────────────────────────────────
  Widget _goalRing(_OverviewData d) {
    final target = (d.goal['target_value'] as num?)?.toDouble() ?? 0.0;
    final distKm = ((d.goalProgress['distance'] as num?)?.toDouble() ?? 0.0) / 1000;
    final progress = target > 0 ? (distKm / target).clamp(0.0, 1.0) : 0.0;
    final period = (d.goal['period'] as String?) ?? 'month';
    final periodLabel = S.isKo
        ? (period == 'week' ? '이번 주' : period == 'year' ? '올해' : '이번 달')
        : (period == 'week' ? 'this week' : period == 'year' ? 'this year' : 'this month');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardBox(),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 7,
                    backgroundColor: widget.palette.fade,
                    valueColor: AlwaysStoppedAnimation(widget.palette.accent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: GoogleFonts.getFont(
                        widget.palette.numFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: widget.palette.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.isKo ? '$periodLabel 목표' : '$periodLabel goal',
                  style: GoogleFonts.getFont(
                    widget.palette.bodyFamily,
                    fontSize: 11,
                    color: widget.palette.muted,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                if (target > 0)
                  Text(
                    '${distKm.toStringAsFixed(1)} / ${target.toStringAsFixed(0)} km',
                    style: GoogleFonts.getFont(
                      widget.palette.numFamily,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: widget.palette.text,
                    ),
                  )
                else
                  Text(
                    S.isKo ? '목표 설정 안 됨' : 'no goal set',
                    style: GoogleFonts.getFont(
                      widget.palette.bodyFamily,
                      fontSize: 14,
                      color: widget.palette.muted,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Streak card ───────────────────────────────────────────
  Widget _streakCard(_OverviewData d) {
    final current = (d.streak['current'] as int?) ?? 0;
    final longest = (d.streak['longest'] as int?) ?? 0;
    final warn = current == 0 && longest > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardBox(),
      child: Row(
        children: [
          Icon(
            warn ? Icons.warning_amber_rounded : Icons.local_fire_department,
            color: warn ? widget.palette.danger : widget.palette.accent,
            size: 34,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  warn
                      ? (S.isKo ? '도플갱어가 강해진다' : 'the doppelgänger grows stronger')
                      : (S.isKo ? '$current일 연속' : '$current day streak'),
                  style: GoogleFonts.getFont(
                    widget.palette.numFamily,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: widget.palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  S.isKo
                      ? '최장 연속 $longest일'
                      : 'longest streak $longest days',
                  style: GoogleFonts.getFont(
                    widget.palette.bodyFamily,
                    fontSize: 12,
                    color: widget.palette.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Weekly bar chart ──────────────────────────────────────
  Widget _weeklyBar(_OverviewData d) {
    final maxKm = d.weekly.isEmpty
        ? 1.0
        : d.weekly
            .map((w) => ((w['distance'] as num?)?.toDouble() ?? 0.0) / 1000)
            .fold<double>(1.0, (p, v) => v > p ? v : p);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.isKo ? '주간 거리 (최근 8주)' : 'weekly distance (last 8w)',
            style: GoogleFonts.getFont(
              widget.palette.bodyFamily,
              fontSize: 11,
              color: widget.palette.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxKm * 1.15,
                minY: 0,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= d.weekly.length) return const SizedBox.shrink();
                        final w = d.weekly[idx];
                        final ws = w['weekStart'] as DateTime;
                        return Text(
                          '${ws.month}/${ws.day}',
                          style: GoogleFonts.getFont(
                            widget.palette.bodyFamily,
                            fontSize: 9,
                            color: widget.palette.muted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: [
                  for (int i = 0; i < d.weekly.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: ((d.weekly[i]['distance'] as num?)?.toDouble() ?? 0.0) / 1000,
                          color: widget.palette.accent,
                          width: 10,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Heatmap calendar (12 weeks × 7 days) ──────────────────
  Widget _heatmapCalendar(_OverviewData d) {
    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    const weeks = 12;
    const days = weeks * 7;
    final cells = <Widget>[];
    double maxM = 1000;
    for (final v in d.dailyMap.values) {
      if (v > maxM) maxM = v;
    }
    for (int i = 0; i < days; i++) {
      final date = startOfToday.subtract(Duration(days: days - 1 - i));
      final key = date.toIso8601String().substring(0, 10);
      final m = d.dailyMap[key] ?? 0.0;
      final ratio = m / maxM;
      final color = m == 0
          ? widget.palette.fade.withValues(alpha: 0.3)
          : widget.palette.accent.withValues(alpha: (0.3 + ratio * 0.7).clamp(0.3, 1.0));
      cells.add(Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ));
    }
    // column-major: 7일 x 12주
    final columns = <Widget>[];
    for (int w = 0; w < weeks; w++) {
      final col = <Widget>[];
      for (int day = 0; day < 7; day++) {
        col.add(cells[w * 7 + day]);
      }
      columns.add(Column(children: col));
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.isKo ? '달린 날 (최근 12주)' : 'days run (last 12w)',
            style: GoogleFonts.getFont(
              widget.palette.bodyFamily,
              fontSize: 11,
              color: widget.palette.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: columns),
          ),
        ],
      ),
    );
  }

  // ─── PR card ───────────────────────────────────────────────
  Widget _prCard(_OverviewData d) {
    final best1K = (d.records['best1KPace'] as double?) ?? 0.0;
    final best5K = (d.records['best5KPace'] as double?) ?? 0.0;
    final bestDist = (d.records['bestDistanceM'] as double?) ?? 0.0;
    final bestEscape = (d.records['bestEscapeS'] as int?) ?? 0;

    String fmtPace(double p) {
      if (p <= 0) return '—';
      final m = p.floor();
      final s = ((p - m) * 60).round();
      return "$m'${s.toString().padLeft(2, '0')}\"";
    }

    String fmtSec(int s) {
      if (s <= 0) return '—';
      final m = s ~/ 60;
      final sec = s % 60;
      return "$m'${sec.toString().padLeft(2, '0')}\"";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.isKo ? '개인 최고 기록' : 'personal records',
            style: GoogleFonts.getFont(
              widget.palette.bodyFamily,
              fontSize: 11,
              color: widget.palette.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _prCell(S.isKo ? '1K 페이스' : '1K pace', fmtPace(best1K))),
              Expanded(child: _prCell(S.isKo ? '5K 페이스' : '5K pace', fmtPace(best5K))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _prCell(
                S.isKo ? '최장 거리' : 'longest run',
                bestDist > 0 ? '${(bestDist / 1000).toStringAsFixed(2)} km' : '—',
              )),
              Expanded(child: _prCell(
                S.isKo ? '최장 탈출' : 'longest escape',
                fmtSec(bestEscape),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _prCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.getFont(
            widget.palette.bodyFamily,
            fontSize: 10,
            color: widget.palette.muted,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.getFont(
            widget.palette.numFamily,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: widget.palette.text,
          ),
        ),
      ],
    );
  }

  // ─── Doppelgänger stats card ───────────────────────────────
  Widget _doppelgangerCard(_OverviewData d) {
    final total = (d.dopp['total'] as int?) ?? 0;
    final wins = (d.dopp['wins'] as int?) ?? 0;
    final losses = (d.dopp['losses'] as int?) ?? 0;
    final winRate = ((d.dopp['winRate'] as double?) ?? 0.0) * 100;
    final avgEscape = ((d.dopp['avgEscapeM'] as double?) ?? 0.0).round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardBox(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.isKo ? '도플갱어 전적' : 'doppelgänger record',
            style: GoogleFonts.getFont(
              widget.palette.bodyFamily,
              fontSize: 11,
              color: widget.palette.muted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _prCell(S.isKo ? '전체' : 'total', '$total')),
              Expanded(child: _prCell(S.isKo ? '승' : 'wins', '$wins')),
              Expanded(child: _prCell(S.isKo ? '패' : 'losses', '$losses')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _prCell(
                S.isKo ? '승률' : 'win rate',
                total > 0 ? '${winRate.toStringAsFixed(0)}%' : '—',
              )),
              Expanded(child: _prCell(
                S.isKo ? '평균 탈출' : 'avg escape',
                avgEscape > 0 ? '${avgEscape}m' : '—',
              )),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardBox() {
    return BoxDecoration(
      color: widget.palette.card,
      border: Border.all(color: widget.palette.border, width: 1),
      borderRadius: BorderRadius.circular(12),
    );
  }
}

/// 테마별 색상/폰트 주입 패키지. 각 레이아웃에서 테마 팔레트를 변환해 전달.
class AnalyticsPalette {
  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color fade;
  final Color accent;
  final Color danger;
  final String numFamily;
  final String bodyFamily;
  const AnalyticsPalette({
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.fade,
    required this.accent,
    required this.danger,
    required this.numFamily,
    required this.bodyFamily,
  });
}

class _OverviewData {
  final Map<String, dynamic> stats;
  final Map<String, dynamic> records;
  final Map<String, dynamic> dopp;
  final Map<String, dynamic> streak;
  final List<Map<String, dynamic>> weekly;
  final Map<String, double> dailyMap;
  final Map<String, dynamic> goal;
  final Map<String, dynamic> goalProgress;
  _OverviewData({
    required this.stats,
    required this.records,
    required this.dopp,
    required this.streak,
    required this.weekly,
    required this.dailyMap,
    required this.goal,
    required this.goalProgress,
  });
}
