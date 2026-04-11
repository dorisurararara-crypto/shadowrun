import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  Map<String, List<RunModel>> _monthRuns = {};
  String? _selectedDate;
  List<Map<String, dynamic>> _weeklyStats = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final monthRuns = await DatabaseHelper.getRunsGroupedByDate(_currentMonth);
    final weeklyStats = await DatabaseHelper.getWeeklyStats(8);
    if (mounted) {
      setState(() {
        _monthRuns = monthRuns;
        _weeklyStats = weeklyStats;
        _loading = false;
      });
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
      _selectedDate = null;
      _loading = true;
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final isPro = PurchaseService().isPro;

    return Scaffold(
      backgroundColor: SRColors.background,
      appBar: AppBar(
        backgroundColor: SRColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SRColors.onSurface),
          onPressed: () => context.go('/'),
        ),
        title: Text(
          S.isKo ? '분석' : 'ANALYSIS',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20, fontWeight: FontWeight.w900,
            color: SRColors.primary, letterSpacing: 1,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: SRColors.primaryContainer, strokeWidth: 2))
          : Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    _buildCalendar(),
                    if (_selectedDate != null) ...[
                      const SizedBox(height: 16),
                      _buildSelectedDateRuns(),
                    ],
                    const SizedBox(height: 24),
                    _buildWeeklyDistanceChart(),
                    const SizedBox(height: 24),
                    _buildPaceTrendChart(),
                  ],
                ),
                if (!isPro) _buildProOverlay(),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Calendar ---
  Widget _buildCalendar() {
    final year = _currentMonth.year;
    final month = _currentMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = DateTime(year, month, 1).weekday; // 1=Mon, 7=Sun
    final monthLabel = S.isKo
        ? '$year년 ${month}월'
        : '${_monthNames[month - 1]} $year';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SRColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Month navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _changeMonth(-1),
                child: const Icon(Icons.chevron_left, color: SRColors.onSurface, size: 24),
              ),
              Text(monthLabel, style: GoogleFonts.spaceGrotesk(
                fontSize: 16, fontWeight: FontWeight.w700, color: SRColors.onSurface,
              )),
              GestureDetector(
                onTap: () => _changeMonth(1),
                child: const Icon(Icons.chevron_right, color: SRColors.onSurface, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Weekday headers
          Row(
            children: (S.isKo
                ? ['월', '화', '수', '목', '금', '토', '일']
                : ['M', 'T', 'W', 'T', 'F', 'S', 'S']
            ).map((d) => Expanded(
              child: Center(child: Text(d, style: GoogleFonts.inter(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: SRColors.onSurface.withValues(alpha: 0.3),
              ))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          // Days grid
          ...List.generate(6, (week) {
            return Row(
              children: List.generate(7, (weekday) {
                final dayIndex = week * 7 + weekday - (firstWeekday - 1);
                if (dayIndex < 1 || dayIndex > daysInMonth) {
                  return const Expanded(child: SizedBox(height: 44));
                }
                final dateKey = '$year-${month.toString().padLeft(2, '0')}-${dayIndex.toString().padLeft(2, '0')}';
                final hasRun = _monthRuns.containsKey(dateKey);
                final isSelected = _selectedDate == dateKey;
                final isToday = dateKey == DateTime.now().toIso8601String().substring(0, 10);
                final dayRuns = _monthRuns[dateKey];
                final totalDist = dayRuns?.fold<double>(0, (sum, r) => sum + r.distanceM) ?? 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: hasRun ? () => setState(() => _selectedDate = isSelected ? null : dateKey) : null,
                    child: Container(
                      height: 44,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF0044).withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday ? Border.all(color: SRColors.runner.withValues(alpha: 0.4), width: 1) : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$dayIndex',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: hasRun ? FontWeight.w700 : FontWeight.w400,
                              color: hasRun ? SRColors.onSurface : SRColors.onSurface.withValues(alpha: 0.3),
                            ),
                          ),
                          if (hasRun) ...[
                            const SizedBox(height: 2),
                            Text(
                              totalDist >= 1000 ? '${(totalDist / 1000).toStringAsFixed(1)}k' : '${totalDist.toInt()}m',
                              style: GoogleFonts.inter(
                                fontSize: 8, fontWeight: FontWeight.w600,
                                color: SRColors.runner,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  static const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  // --- Selected date runs ---
  Widget _buildSelectedDateRuns() {
    final runs = _monthRuns[_selectedDate] ?? [];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SRColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_selectedDate ?? '', style: GoogleFonts.spaceGrotesk(
            fontSize: 14, fontWeight: FontWeight.w700, color: SRColors.primaryContainer,
          )),
          const SizedBox(height: 12),
          ...runs.map((run) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  run.isChallenge ? Icons.flash_on : Icons.directions_run,
                  size: 16,
                  color: run.isChallenge ? SRColors.primaryContainer : SRColors.runner,
                ),
                const SizedBox(width: 10),
                Text(run.formattedDistance, style: GoogleFonts.spaceGrotesk(
                  fontSize: 15, fontWeight: FontWeight.w700, color: SRColors.onSurface,
                )),
                const SizedBox(width: 12),
                Text(run.formattedPace, style: GoogleFonts.inter(
                  fontSize: 13, color: SRColors.onSurface.withValues(alpha: 0.5),
                )),
                const SizedBox(width: 12),
                Text(run.formattedDuration, style: GoogleFonts.inter(
                  fontSize: 13, color: SRColors.onSurface.withValues(alpha: 0.5),
                )),
                const Spacer(),
                if (run.challengeResult != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (run.challengeResult == 'win' ? SRColors.safe : SRColors.primaryContainer).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      run.challengeResult == 'win' ? S.win : S.lose,
                      style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w800,
                        color: run.challengeResult == 'win' ? SRColors.safe : SRColors.primaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // --- Weekly Distance Chart ---
  Widget _buildWeeklyDistanceChart() {
    if (_weeklyStats.isEmpty) return const SizedBox.shrink();

    final maxDist = _weeklyStats.fold<double>(0, (max, s) {
      final d = (s['distance'] as double) / 1000;
      return d > max ? d : max;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(S.isKo ? '주간 거리' : 'WEEKLY DISTANCE'),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: BarChart(
            BarChartData(
              maxY: maxDist > 0 ? maxDist * 1.3 : 5,
              barGroups: List.generate(_weeklyStats.length, (i) {
                final dist = (_weeklyStats[i]['distance'] as double) / 1000;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: dist,
                    width: 16,
                    color: SRColors.runner,
                    borderRadius: BorderRadius.circular(4),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxDist > 0 ? maxDist * 1.3 : 5,
                      color: SRColors.surfaceContainerHighest,
                    ),
                  ),
                ]);
              }),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 32,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toStringAsFixed(1)}',
                    style: GoogleFonts.inter(fontSize: 9, color: SRColors.onSurface.withValues(alpha: 0.3)),
                  ),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= _weeklyStats.length) return const SizedBox.shrink();
                    final ws = _weeklyStats[idx]['weekStart'] as DateTime;
                    return Text('${ws.month}/${ws.day}', style: GoogleFonts.inter(
                      fontSize: 9, color: SRColors.onSurface.withValues(alpha: 0.3),
                    ));
                  },
                )),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Pace Trend Chart ---
  Widget _buildPaceTrendChart() {
    final paceData = _weeklyStats.where((s) => (s['avgPace'] as double) > 0).toList();
    if (paceData.isEmpty) return const SizedBox.shrink();

    final minPace = paceData.fold<double>(99, (min, s) {
      final p = s['avgPace'] as double;
      return p < min ? p : min;
    });
    final maxPace = paceData.fold<double>(0, (max, s) {
      final p = s['avgPace'] as double;
      return p > max ? p : max;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(S.isKo ? '페이스 추세' : 'PACE TREND'),
        Container(
          height: 180,
          padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: LineChart(
            LineChartData(
              minY: (minPace - 1).clamp(0, 99),
              maxY: maxPace + 1,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(paceData.length, (i) =>
                    FlSpot(i.toDouble(), paceData[i]['avgPace'] as double)),
                  isCurved: true,
                  color: SRColors.primaryContainer,
                  barWidth: 3,
                  dotData: FlDotData(show: true, getDotPainter: (spot, _, __, ___) =>
                    FlDotCirclePainter(radius: 4, color: SRColors.primaryContainer,
                      strokeWidth: 2, strokeColor: SRColors.background)),
                  belowBarData: BarAreaData(
                    show: true,
                    color: SRColors.primaryContainer.withValues(alpha: 0.1),
                  ),
                ),
              ],
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final min = value.floor();
                    final sec = ((value - min) * 60).round();
                    return Text("$min'${sec.toString().padLeft(2, '0')}\"",
                      style: GoogleFonts.inter(fontSize: 9, color: SRColors.onSurface.withValues(alpha: 0.3)));
                  },
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= paceData.length) return const SizedBox.shrink();
                    final ws = paceData[idx]['weekStart'] as DateTime;
                    return Text('${ws.month}/${ws.day}', style: GoogleFonts.inter(
                      fontSize: 9, color: SRColors.onSurface.withValues(alpha: 0.3),
                    ));
                  },
                )),
              ),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.white.withValues(alpha: 0.05), strokeWidth: 1,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(text.toUpperCase(), style: GoogleFonts.spaceGrotesk(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: SRColors.primary.withValues(alpha: 0.6), letterSpacing: 3,
      )),
    );
  }

  // --- PRO Overlay ---
  Widget _buildProOverlay() {
    return Positioned.fill(
      child: Container(
        color: SRColors.background.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: SRColors.proBadge, size: 48),
              const SizedBox(height: 16),
              Text('PRO', style: GoogleFonts.spaceGrotesk(
                fontSize: 28, fontWeight: FontWeight.w900, color: SRColors.proBadge, letterSpacing: 4,
              )),
              const SizedBox(height: 8),
              Text(
                S.isKo ? '러닝 분석은 PRO 전용 기능입니다' : 'Running analysis requires PRO',
                style: GoogleFonts.inter(fontSize: 14, color: SRColors.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200, height: 48,
                child: ElevatedButton(
                  onPressed: () => context.push('/settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0044),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(S.upgradeToPro, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Bottom Nav ---
  Widget _buildBottomNav() {
    return Container(
      color: SRColors.surface,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(Icons.directions_run, false, () => context.go('/')),
          _navIcon(Icons.monitor_heart_outlined, false, () => context.go('/history')),
          _navIcon(Icons.settings_outlined, false, () => context.go('/settings')),
          _navIcon(Icons.analytics_outlined, true, () {}),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isActive ? SRColors.primaryContainer.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22,
          color: isActive ? SRColors.primaryContainer : SRColors.onSurface.withValues(alpha: 0.3)),
      ),
    );
  }
}
