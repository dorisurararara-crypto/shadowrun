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

  void _refresh() => setState(() => _loadData());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SRColors.background,
      body: Column(
        children: [
          // Header (Stitch: px-6 py-4, bg-[#131313])
          Container(
            color: SRColors.surface,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24, right: 12, bottom: 16,
            ),
            child: Row(
              children: [
                Text('SHADOW RUN', style: GoogleFonts.spaceGrotesk(
                  fontSize: 24, fontWeight: FontWeight.w900,
                  color: SRColors.primary, letterSpacing: -0.5,
                )),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_month_outlined, color: SRColors.neutral500, size: 24),
                  onPressed: () => context.push('/analysis'),
                ),
                IconButton(
                  icon: const Icon(Icons.history, color: SRColors.neutral500, size: 24),
                  onPressed: () => context.push('/history'),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: SRColors.neutral500, size: 24),
                  onPressed: () => context.push('/settings'),
                ),
              ],
            ),
          ),
          // Body (Stitch: px-6 py-8 space-y-8)
          Expanded(
            child: RefreshIndicator(
              color: SRColors.primaryContainer,
              backgroundColor: SRColors.surface,
              onRefresh: () async => _refresh(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActionButtons(),
                    const SizedBox(height: 32),
                    _buildStatsCard(),
                    const SizedBox(height: 32),
                    if (!PurchaseService().isPro) _buildProBanner(),
                    if (!PurchaseService().isPro) const SizedBox(height: 32),
                    if (!PurchaseService().isPro) _buildDailyChallengeCard(),
                    if (!PurchaseService().isPro) const SizedBox(height: 32),
                    _buildRecentRunsSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Action Buttons (Stitch bottom nav style, but moved to top per user request) ---
  Widget _buildActionButtons() {
    return Row(
      children: [
        // NEW RUN (Stitch: gradient from-primary to-primary_container, rounded-full, py-4 px-6)
        Expanded(
          child: SizedBox(
            height: 56,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [SRColors.primary, SRColors.primaryContainer],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: SRColors.primaryContainer.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () => context.push('/prepare'),
                icon: const Icon(Icons.directions_run, size: 20),
                label: Text(S.newRun, style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3,
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, shadowColor: Colors.transparent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // CHALLENGE (Stitch: border border-[#ff5262], text-neutral-300)
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: () async {
                final count = await DatabaseHelper.getDailyChallengeCount();
                if (!mounted) return;
                if (count >= 3 && !PurchaseService().isPro) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.dailyLimitReached), backgroundColor: SRColors.surface),
                  );
                  return;
                }
                context.push('/prepare', extra: -1);
              },
              icon: const Icon(Icons.workspace_premium, size: 20),
              label: Text(S.challenge, style: GoogleFonts.inter(
                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 3, color: SRColors.onSurface.withValues(alpha: 0.7),
              )),
              style: OutlinedButton.styleFrom(
                foregroundColor: SRColors.primary,
                side: const BorderSide(color: SRColors.primaryContainer),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Stats Card (Stitch: bg-[#161616] rounded-xl p-6 border-white/5, grid-cols-2 gap-y-6 gap-x-4) ---
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Row(children: [
                Expanded(child: _statCell(S.totalDistance, distanceKm.toStringAsFixed(1), unit: 'km')),
                const SizedBox(width: 16),
                Expanded(child: _statCell(S.totalRuns, '$totalRuns')),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _statCell(S.record, '${wins}W ${losses}L',
                  valueColor: wins > losses ? SRColors.safe : null)),
                const SizedBox(width: 16),
                Expanded(child: _statCell(S.streak, '$streak',
                  valueColor: streak >= 3 ? SRColors.primaryContainer : null)),
              ]),
            ],
          ),
        );
      },
    );
  }

  // Stitch stat cell: label text-[10px] font-bold tracking-[0.1em] text-[#ff5262], value text-2xl font-bold
  Widget _statCell(String label, String value, {String? unit, Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.w700, color: SRColors.primaryContainer, letterSpacing: 1,
        )),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: GoogleFonts.spaceGrotesk(
              fontSize: 24, fontWeight: FontWeight.w700, color: valueColor ?? SRColors.onSurface,
            )),
            if (unit != null) ...[
              const SizedBox(width: 4),
              Text(unit, style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w400, color: SRColors.neutral500,
              )),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildProBanner() {
    return GestureDetector(
      onTap: () => context.push('/settings'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            SRColors.primaryContainer.withValues(alpha: 0.15),
            SRColors.proBadge.withValues(alpha: 0.08),
          ]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: SRColors.proBadge.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.workspace_premium, color: SRColors.proBadge, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SHADOW RUN PRO', style: GoogleFonts.spaceGrotesk(
                fontSize: 14, fontWeight: FontWeight.w800, color: SRColors.proBadge, letterSpacing: 1,
              )),
              const SizedBox(height: 2),
              Text(S.proBanner, style: GoogleFonts.inter(
                fontSize: 12, color: SRColors.onSurface.withValues(alpha: 0.5),
              )),
            ],
          )),
          Icon(Icons.chevron_right, color: SRColors.onSurface.withValues(alpha: 0.3), size: 22),
        ]),
      ),
    );
  }

  // --- Challenge Card (Stitch: p-5, left accent w-1 gradient, icon w-12 h-12, title text-lg, remaining text-xl) ---
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
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            // Left accent (Stitch: w-1 gradient)
            Container(
              width: 4, height: 88,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [SRColors.primary, SRColors.primaryContainer],
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Icon (Stitch: w-12 h-12 rounded-lg)
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: SRColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_fire_department, color: SRColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            // Text
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(S.todaysChallenge.toUpperCase(), style: GoogleFonts.spaceGrotesk(
                    fontSize: 18, fontWeight: FontWeight.w700, color: SRColors.onSurface, letterSpacing: -0.3,
                  )),
                  const SizedBox(height: 4),
                  Text(S.dailyObjective, style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500, color: SRColors.neutral500,
                  )),
                ],
              ),
            )),
            // Remaining (Stitch: text-xl font-black text-[#ff5262])
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Column(children: [
                Text(S.remaining.toUpperCase(), style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w700, color: SRColors.neutral500, letterSpacing: 1,
                )),
                const SizedBox(height: 4),
                Text('$remaining/$maxFree', style: GoogleFonts.spaceGrotesk(
                  fontSize: 20, fontWeight: FontWeight.w900, color: SRColors.primaryContainer,
                )),
              ]),
            ),
            if (remaining == 0)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: GestureDetector(
                  onTap: () async {
                    final success = await AdService().showRewardedAd(
                      onRewarded: () async {
                        final count = await DatabaseHelper.getDailyChallengeCount();
                        if (count > 0) await DatabaseHelper.setSetting('daily_challenges', '${count - 1}');
                        if (mounted) setState(() => _challengeCountFuture = DatabaseHelper.getDailyChallengeCount());
                      },
                    );
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(S.adLoading), backgroundColor: SRColors.surface),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: SRColors.warning.withValues(alpha: 0.4)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.play_circle_outline, size: 14, color: SRColors.warning),
                      const SizedBox(width: 4),
                      Text(S.adPlus1, style: GoogleFonts.inter(
                        fontSize: 10, fontWeight: FontWeight.w700, color: SRColors.warning,
                      )),
                    ]),
                  ),
                ),
              ),
          ]),
        );
      },
    );
  }

  // --- Recent Runs (Stitch: text-sm font-bold tracking-widest, space-y-4) ---
  Widget _buildRecentRunsSection() {
    return FutureBuilder<List<RunModel>>(
      future: _runsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: SRColors.primaryContainer, strokeWidth: 2),
          ));
        }

        final runs = snapshot.data ?? [];
        final recent = runs.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Stitch: text-sm font-headline font-bold text-neutral-400 tracking-widest)
            Row(children: [
              Text(S.recentRuns.toUpperCase(), style: GoogleFonts.spaceGrotesk(
                fontSize: 14, fontWeight: FontWeight.w700, color: SRColors.neutral500, letterSpacing: 3,
              )),
              const SizedBox(width: 16),
              Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.05))),
            ]),
            const SizedBox(height: 16),
            if (recent.isEmpty)
              // Stitch: py-20 border-2 border-dashed, w-16 h-16 icon
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 80),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(width: 2, color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(children: [
                  Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Icon(Icons.directions_run, size: 32, color: SRColors.onSurface.withValues(alpha: 0.15)),
                  ),
                  const SizedBox(height: 16),
                  Text(S.noRunsYet, style: GoogleFonts.inter(
                    fontSize: 14, fontWeight: FontWeight.w500, color: SRColors.neutral500,
                  )),
                  const SizedBox(height: 4),
                  Text(S.wakeUpShadow, style: GoogleFonts.inter(
                    fontSize: 14, color: SRColors.onSurface.withValues(alpha: 0.4),
                  )),
                ]),
              )
            else
              ...recent.map((run) => _RunTile(run: run)),
            if (runs.length > 3) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.push('/history'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(S.viewAll.toUpperCase(), style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: SRColors.onSurface.withValues(alpha: 0.4), letterSpacing: 2,
                    )),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, size: 16, color: SRColors.onSurface.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // --- Bottom Nav (Stitch style: bg-[#131313]/80 backdrop-blur, border-t border-white/5) ---
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: SRColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(Icons.directions_run, true, () {}),
          _navIcon(Icons.monitor_heart_outlined, false, () => context.push('/history')),
          _navIcon(Icons.settings_outlined, false, () => context.push('/settings')),
          _navIcon(Icons.analytics_outlined, false, () => context.push('/analysis')),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? SRColors.primaryContainer.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 22,
          color: isActive ? SRColors.primaryContainer : SRColors.onSurface.withValues(alpha: 0.4)),
      ),
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
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/prepare', extra: run.id),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: run.isChallenge
                      ? SRColors.primaryContainer.withValues(alpha: 0.12)
                      : SRColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  run.isChallenge ? Icons.flash_on : Icons.directions_run,
                  color: run.isChallenge ? SRColors.primaryContainer : SRColors.neutral500,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_formatDate(run.date), style: GoogleFonts.inter(
                    fontSize: 15, fontWeight: FontWeight.w600, color: SRColors.onSurface,
                  )),
                  const SizedBox(height: 4),
                  Text('${run.formattedDistance}  ·  ${run.formattedPace}/km', style: GoogleFonts.inter(
                    fontSize: 13, color: SRColors.onSurface.withValues(alpha: 0.4),
                  )),
                ],
              )),
              if (run.isChallenge && run.challengeResult != null)
                _ChallengeBadge(result: run.challengeResult!),
            ]),
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
    // Stitch: win=bg-[#2aa192]/20 text-[#6bd9c7], lose=bg-[#93000a]/20 text-[#ffb4ab]
    final bgColor = isWin ? const Color(0xFF2AA192) : const Color(0xFF93000A);
    final textColor = isWin ? const Color(0xFF6BD9C7) : const Color(0xFFFFB4AB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        isWin ? S.win : S.lose,
        style: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 1,
        ),
      ),
    );
  }
}
