import 'package:flutter/material.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/features/analysis/presentation/widgets/nrc_sections.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';

/// 분석 탭 공통 대시보드.
/// - 팔레트만 주입해 테마별 (Default/Mystic/Pure) 렌더를 통일.
/// - NRC 스타일 섹션(월타일/레벨/배지/12개월/태그) + 기존 AnalyticsOverview 조합.
class AnalysisDashboard extends StatefulWidget {
  final AnalyticsPalette palette;
  const AnalysisDashboard({super.key, required this.palette});

  @override
  State<AnalysisDashboard> createState() => _AnalysisDashboardState();
}

class _AnalysisDashboardState extends State<AnalysisDashboard> {
  late Future<_DashData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashData> _load() async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final results = await Future.wait([
      DatabaseHelper.getTotalLifetimeDistance(),
      DatabaseHelper.getMonthlyDistanceLast12(),
      DatabaseHelper.getRunsByMode(),
      DatabaseHelper.getEarnedBadges(),
      DatabaseHelper.getRunsByDateRange(monthStart, nextMonth),
    ]);
    final thisMonthRuns = results[4] as List;
    final thisMonthKm = thisMonthRuns.fold<double>(
      0,
      (a, r) => a + (r.distanceM as num).toDouble(),
    ) / 1000;
    return _DashData(
      lifetimeKm: (results[0] as double) / 1000,
      monthly12: results[1] as List<Map<String, dynamic>>,
      byMode: results[2] as Map<String, Map<String, dynamic>>,
      earned: results[3] as Set<String>,
      thisMonthKm: thisMonthKm,
      thisMonthRuns: thisMonthRuns.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_DashData>(
      future: _future,
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return SizedBox(
            height: 240,
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
            MonthTileCard(
              palette: widget.palette,
              thisMonthKm: d.thisMonthKm,
              runs: d.thisMonthRuns,
            ),
            const SizedBox(height: 12),
            LevelCard(palette: widget.palette, lifetimeKm: d.lifetimeKm),
            const SizedBox(height: 12),
            // 기존 섹션(목표링 + streak + 주간 + 히트맵 + PR + 도플갱어 전적)
            AnalyticsOverview(palette: widget.palette),
            const SizedBox(height: 12),
            Monthly12Card(palette: widget.palette, monthly: d.monthly12),
            const SizedBox(height: 12),
            BadgeGalleryCard(palette: widget.palette, earned: d.earned),
            const SizedBox(height: 12),
            TagSummaryCard(palette: widget.palette, byMode: d.byMode),
          ],
        );
      },
    );
  }
}

class _DashData {
  final double lifetimeKm;
  final List<Map<String, dynamic>> monthly12;
  final Map<String, Map<String, dynamic>> byMode;
  final Set<String> earned;
  final double thisMonthKm;
  final int thisMonthRuns;
  _DashData({
    required this.lifetimeKm,
    required this.monthly12,
    required this.byMode,
    required this.earned,
    required this.thisMonthKm,
    required this.thisMonthRuns,
  });
}
