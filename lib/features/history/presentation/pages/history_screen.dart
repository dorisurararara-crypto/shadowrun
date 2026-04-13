import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<RunModel>> _runsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() { SfxService().toggle(); });
    _runsFuture = DatabaseHelper.getAllRuns();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _runsFuture = DatabaseHelper.getAllRuns();
    });
  }

  Future<void> _deleteRun(RunModel run) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SRColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          S.deleteRecord,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: SRColors.onSurface,
          ),
        ),
        content: Text(
          S.deleteRecordMessage,
          style: GoogleFonts.inter(
            color: SRColors.onSurface.withValues(alpha: 0.6),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              S.cancel,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SRColors.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              S.delete,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SRColors.primaryContainer,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && run.id != null) {
      await DatabaseHelper.deleteRun(run.id!);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
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
          S.records,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: SRColors.primary,
            letterSpacing: 1,
          ),
        ),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: SRColors.primaryContainer,
          indicatorWeight: 2.5,
          indicatorSize: TabBarIndicatorSize.label,
          labelColor: SRColors.onSurface,
          unselectedLabelColor: SRColors.onSurface.withValues(alpha: 0.4),
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
          unselectedLabelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: S.all),
            Tab(text: S.challenges),
          ],
        ),
      ),
      body: FutureBuilder<List<RunModel>>(
        future: _runsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: SRColors.primaryContainer,
                strokeWidth: 2,
              ),
            );
          }

          final allRuns = snapshot.data ?? [];
          final challengeRuns = allRuns.where((r) => r.isChallenge).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _RunList(
                runs: allRuns,
                onTap: (run) {
                  SfxService().tapCard();
                  context.push('/prepare', extra: run.id);
                },
                onDismiss: _deleteRun,
              ),
              _RunList(
                runs: challengeRuns,
                onTap: (run) {
                  SfxService().tapCard();
                  context.push('/prepare', extra: run.id);
                },
                onDismiss: _deleteRun,
                emptyMessage: S.noChallengesEmpty,
                emptySubtitle: S.noChallengesSubtitle,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RunList extends StatelessWidget {
  final List<RunModel> runs;
  final void Function(RunModel) onTap;
  final Future<void> Function(RunModel) onDismiss;
  final String emptyMessage;
  final String emptySubtitle;

  _RunList({
    required this.runs,
    required this.onTap,
    required this.onDismiss,
    String? emptyMessage,
    String? emptySubtitle,
  })  : emptyMessage = emptyMessage ?? S.noRunsEmpty,
        emptySubtitle = emptySubtitle ?? S.wakeUpShadow;

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.symmetric(vertical: 48),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_run,
                size: 36,
                color: SRColors.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                emptyMessage,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: SRColors.onSurface.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                emptySubtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: SRColors.onSurface.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<RunModel>>{};
    for (final run in runs) {
      final dateKey = run.date.length >= 10 ? run.date.substring(0, 10) : run.date;
      grouped.putIfAbsent(dateKey, () => []).add(run);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final dateKey = sortedKeys[index];
        final dayRuns = grouped[dateKey]!;
        return _DateSection(
          dateKey: dateKey,
          runs: dayRuns,
          onTap: onTap,
          onDismiss: onDismiss,
          showSwipeHintOnFirst: index == 0,
        );
      },
    );
  }
}

class _DateSection extends StatelessWidget {
  final String dateKey;
  final List<RunModel> runs;
  final void Function(RunModel) onTap;
  final Future<void> Function(RunModel) onDismiss;
  final bool showSwipeHintOnFirst;

  const _DateSection({
    required this.dateKey,
    required this.runs,
    required this.onTap,
    required this.onDismiss,
    this.showSwipeHintOnFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, top: 12),
          child: Text(
            _formatDateHeader(dateKey),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: SRColors.onSurface.withValues(alpha: 0.4),
              letterSpacing: 1.5,
            ),
          ),
        ),
        ...runs.asMap().entries.map((entry) => _HistoryTile(
              run: entry.value,
              onTap: () => onTap(entry.value),
              onDismiss: () => onDismiss(entry.value),
              showSwipeHint: showSwipeHintOnFirst && entry.key == 0,
            )),
        const SizedBox(height: 4),
      ],
    );
  }

  String _formatDateHeader(String date) {
    try {
      final dt = DateTime.parse(date);
      if (S.isKo) {
        const weekdaysKo = ['월', '화', '수', '목', '금', '토', '일'];
        return '${dt.month}월 ${dt.day}일 (${weekdaysKo[dt.weekday - 1]})';
      } else {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return '${months[dt.month - 1]} ${dt.day} (${weekdays[dt.weekday - 1]})';
      }
    } catch (_) {
      return date;
    }
  }
}

class _HistoryTile extends StatefulWidget {
  final RunModel run;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final bool showSwipeHint;

  const _HistoryTile({
    required this.run,
    required this.onTap,
    required this.onDismiss,
    this.showSwipeHint = false,
  });

  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile>
    with SingleTickerProviderStateMixin {
  AnimationController? _hintAnim;
  Animation<Offset>? _hintSlide;
  bool _hintVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.showSwipeHint) {
      _hintVisible = true;
      _hintAnim = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      _hintSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.08, 0),
      ).animate(CurvedAnimation(parent: _hintAnim!, curve: Curves.easeInOut));

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _hintAnim!.forward().then((_) {
            Future.delayed(const Duration(milliseconds: 400), () {
              if (mounted) {
                _hintAnim!.reverse().then((_) {
                  if (mounted) setState(() => _hintVisible = false);
                });
              }
            });
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _hintAnim?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget tile = _buildTile();
    if (_hintSlide != null && _hintVisible) {
      tile = SlideTransition(position: _hintSlide!, child: tile);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Stack(
        children: [
          // Delete hint background (visible during hint animation)
          if (_hintVisible)
            Positioned.fill(
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: SRColors.primaryContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: SRColors.primaryContainer.withValues(alpha: 0.6), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'swipe',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: SRColors.primaryContainer.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Dismissible(
            key: ValueKey(widget.run.id ?? widget.run.date),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: SRColors.primaryContainer.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: SRColors.primaryContainer),
            ),
            confirmDismiss: (_) async {
              widget.onDismiss();
              return false;
            },
            child: tile,
          ),
        ],
      ),
    );
  }

  Widget _buildTile() {
    final run = widget.run;
    return Material(
      color: SRColors.card,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: run.isChallenge
                      ? SRColors.primaryContainer.withValues(alpha: 0.12)
                      : SRColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  run.isChallenge ? Icons.flash_on : Icons.directions_run,
                  color: run.isChallenge
                      ? SRColors.primaryContainer
                      : SRColors.neutral500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          run.formattedDistance,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: SRColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (run.isChallenge && run.challengeResult != null)
                          _ChallengeBadge(result: run.challengeResult!),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _MetaChip(
                          icon: Icons.timer_outlined,
                          text: run.formattedDuration,
                        ),
                        const SizedBox(width: 12),
                        _MetaChip(
                          icon: Icons.speed,
                          text: '${run.formattedPace}/km',
                        ),
                        if (run.location != null && run.location!.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          _MetaChip(
                            icon: Icons.place_outlined,
                            text: run.location!,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: SRColors.onSurface.withValues(alpha: 0.2),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: SRColors.onSurface.withValues(alpha: 0.3)),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: SRColors.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
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
