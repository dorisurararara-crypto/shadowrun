import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/services/ad_service.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _statsFuture;
  late Future<List<RunModel>> _runsFuture;
  late Future<int> _challengeCountFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _statsFuture = DatabaseHelper.getStats();
    _runsFuture = DatabaseHelper.getAllRuns();
    _challengeCountFuture = DatabaseHelper.getDailyChallengeCount();
  }

  void _refresh() {
    setState(() {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SRColors.background,
      body: Column(
        children: [
          // Sticky header
          Container(
            color: SRColors.surface,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 12,
              left: 20,
              right: 12,
              bottom: 12,
            ),
            child: Row(
              children: [
                Text(
                  'SHADOW RUN',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: SRColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history, color: SRColors.neutral500, size: 22),
                  onPressed: () => context.push('/history'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: SRColors.neutral500, size: 22),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: RefreshIndicator(
              color: SRColors.primaryContainer,
              backgroundColor: SRColors.surface,
              onRefresh: () async => _refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsCard(),
                    const SizedBox(height: 20),
                    _buildDailyChallengeCard(),
                    const SizedBox(height: 28),
                    _buildRecentRunsSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final totalRuns = stats?['totalRuns'] ?? 0;
        final totalDistanceM = (stats?['totalDistanceM'] ?? 0.0) as double;
        final wins = stats?['wins'] ?? 0;
        final losses = stats?['losses'] ?? 0;
        final streak = stats?['streak'] ?? 0;

        final distanceKm = totalDistanceM / 1000;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: S.totalDistance,
                      value: distanceKm.toStringAsFixed(1),
                      unit: 'km',
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: S.totalRuns,
                      value: '$totalRuns',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(
                      label: S.record,
                      value: '${wins}W ${losses}L',
                      valueColor: wins > losses ? SRColors.safe : SRColors.onSurface,
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      label: S.streak,
                      value: '$streak',
                      valueColor: streak >= 3 ? SRColors.primaryContainer : SRColors.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDailyChallengeCard() {
    return FutureBuilder<int>(
      future: _challengeCountFuture,
      builder: (context, snapshot) {
        final used = snapshot.data ?? 0;
        const maxFree = 3;
        final remaining = (maxFree - used).clamp(0, maxFree);

        return Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              // Left accent bar gradient
              Container(
                width: 4,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [SRColors.primary, SRColors.primaryContainer],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Fire icon in rounded container
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SRColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: SRColors.primaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.todaysChallenge,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: SRColors.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${S.remaining}: $remaining/$maxFree',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SRColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (remaining == 0)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: GestureDetector(
                    onTap: () async {
                      final success = await AdService().showRewardedAd(
                        onRewarded: () async {
                          // 도전 횟수를 -1로 롤백 (기회 +1)
                          final db = await DatabaseHelper.database;
                          final count = await DatabaseHelper.getDailyChallengeCount();
                          if (count > 0) {
                            await DatabaseHelper.setSetting(
                              'daily_challenges', '${count - 1}');
                          }
                          if (mounted) {
                            setState(() {
                              _challengeCountFuture = DatabaseHelper.getDailyChallengeCount();
                            });
                          }
                        },
                      );
                      if (!success && mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('광고를 불러오는 중입니다. 잠시 후 다시 시도해주세요.'),
                            backgroundColor: SRColors.surface,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: SRColors.warning.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_circle_outline, size: 14, color: SRColors.warning),
                          const SizedBox(width: 4),
                          Text(
                            S.adPlus1,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: SRColors.warning,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentRunsSection() {
    return FutureBuilder<List<RunModel>>(
      future: _runsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(
                color: SRColors.primaryContainer,
                strokeWidth: 2,
              ),
            ),
          );
        }

        final runs = snapshot.data ?? [];
        final recent = runs.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label with line
            Row(
              children: [
                Text(
                  S.recentRuns,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: SRColors.primaryContainer,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 0.5,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recent.isEmpty)
              // Empty state with dashed border
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 48),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_run,
                      size: 36,
                      color: SRColors.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      S.noRunsYet,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: SRColors.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.wakeUpShadow,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: SRColors.onSurface.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recent.map((run) => _RunTile(run: run)),
            if (runs.length > 3) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => context.push('/history'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      S.viewAll,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: SRColors.onSurface.withValues(alpha: 0.4),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 14, color: SRColors.onSurface.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      color: SRColors.background,
      child: Row(
        children: [
          // NEW RUN - gradient filled pill
          Expanded(
            child: SizedBox(
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [SRColors.primary, SRColors.primaryContainer],
                  ),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: ElevatedButton(
                  onPressed: () => context.push('/prepare'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    S.newRun,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // CHALLENGE - outlined pill
          Expanded(
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: () async {
                  final count = await DatabaseHelper.getDailyChallengeCount();
                  if (!mounted) return;
                  if (count >= 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          S.dailyLimitReached,
                          style: GoogleFonts.inter(),
                        ),
                        backgroundColor: SRColors.surface,
                      ),
                    );
                    return;
                  }
                  context.push('/prepare', extra: -1);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: SRColors.primary,
                  side: const BorderSide(color: SRColors.primaryContainer, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  S.challenge,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.unit,
    this.valueColor = SRColors.onSurface,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: SRColors.primaryContainer,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
            if (unit != null) ...[
              const SizedBox(width: 2),
              Text(
                unit!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: SRColors.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RunTile extends StatelessWidget {
  final RunModel run;

  const _RunTile({required this.run});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: SRColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/prepare', extra: run.id),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: run.isChallenge
                        ? SRColors.primaryContainer.withValues(alpha: 0.12)
                        : SRColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    run.isChallenge ? Icons.flash_on : Icons.directions_run,
                    color: run.isChallenge ? SRColors.primaryContainer : SRColors.neutral500,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(run.date),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: SRColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${run.formattedDistance}  ·  ${run.formattedPace}/km',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: SRColors.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                if (run.isChallenge && run.challengeResult != null)
                  _ChallengeBadge(result: run.challengeResult!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }
}

class _ChallengeBadge extends StatelessWidget {
  final String result;

  const _ChallengeBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    final isWin = result == 'win';
    final color = isWin ? SRColors.safe : SRColors.primaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isWin ? S.win : S.lose,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
