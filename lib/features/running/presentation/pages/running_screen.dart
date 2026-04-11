import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/services/running_service.dart';
import 'package:shadowrun/core/services/horror_service.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class RunningScreen extends StatefulWidget {
  final int? shadowRunId;

  const RunningScreen({super.key, this.shadowRunId});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen>
    with TickerProviderStateMixin {
  late final RunningService _runService;
  late final HorrorService _horrorService;
  final PageController _pageController = PageController(initialPage: 0);
  NaverMapController? _mapController;

  Timer? _ticker;
  bool _paused = false;
  bool _stopping = false;
  late AnimationController _vignetteAnim;
  late AnimationController _shadowPingAnim;

  @override
  void initState() {
    super.initState();
    _runService = RunningService();
    _horrorService = HorrorService();
    _runService.addListener(_onRunUpdate);

    _vignetteAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _shadowPingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _startRun();
  }

  Future<void> _startRun() async {
    await _horrorService.initialize();
    final ok = await _runService.startRun(shadowRunId: widget.shadowRunId);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS 권한이 필요합니다')),
      );
      context.pop();
      return;
    }
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_paused && mounted) {
        setState(() {});
        _updateHorror();
        _updateMap();
      }
    });
  }

  void _onRunUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _updateHorror() async {
    if (widget.shadowRunId == null) return;
    final dist = _runService.shadowDistanceM;
    if (!dist.isInfinite) {
      await _horrorService.updateThreat(dist);
    }
  }

  void _updateMap() {
    final pos = _runService.currentPosition;
    if (pos == null || _mapController == null) return;
    final target = NLatLng(pos.latitude, pos.longitude);
    _updateMapOverlays(_mapController!, target);
  }

  void _updateMapOverlays(NaverMapController controller, NLatLng target) {
    controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: target),
    );

    // Runner marker
    controller.addOverlay(NMarker(
      id: 'runner',
      position: target,
      iconTintColor: SRColors.runner,
      size: const Size(24, 24),
    ));

    // Runner path polyline
    final runnerCoords = _runService.points
        .map((p) => NLatLng(p.latitude, p.longitude))
        .toList();
    if (runnerCoords.length >= 2) {
      controller.addOverlay(NPathOverlay(
        id: 'runner_path',
        coords: runnerCoords,
        color: SRColors.runner.withValues(alpha: 0.8),
        outlineColor: SRColors.runner.withValues(alpha: 0.3),
        width: 4,
      ));
    }

    // Shadow marker
    final shadowPoint = _runService.currentShadowPoint;
    debugPrint('SHADOW MAP: shadowPoint=$shadowPoint, shadowIdx=${_runService.currentShadowIndex}, shadowDist=${_runService.shadowDistanceM}');
    if (shadowPoint != null) {
      controller.addOverlay(NMarker(
        id: 'shadow',
        position: NLatLng(shadowPoint.latitude, shadowPoint.longitude),
        iconTintColor: SRColors.shadow,
        size: const Size(24, 24),
      ));
    }

    // Shadow path polyline (only up to current shadow index)
    final shadowPoints = _runService.shadowPoints;
    final shadowIdx = _runService.currentShadowIndex;
    if (shadowPoints != null && shadowIdx >= 1) {
      final shadowCoords = shadowPoints
          .take(shadowIdx + 1)
          .map((p) => NLatLng(p.latitude, p.longitude))
          .toList();
      if (shadowCoords.length >= 2) {
        controller.addOverlay(NPathOverlay(
          id: 'shadow_path',
          coords: shadowCoords,
          color: SRColors.shadow.withValues(alpha: 0.4),
          outlineColor: Colors.transparent,
          width: 3,
        ));
      }
    }
  }

  void _togglePause() {
    setState(() => _paused = !_paused);
  }

  Future<void> _confirmStop() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SRColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(S.stopRunTitle, style: SRTheme.headlineMedium.copyWith(fontSize: 20)),
        content: Text(
          S.stopRunMessage,
          style: SRTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(S.keepRunning,
                style: GoogleFonts.inter(color: SRColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(S.stop,
                style: GoogleFonts.inter(
                    color: SRColors.primaryContainer, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _stopRun();
    }
  }

  Future<void> _stopRun() async {
    if (_stopping) return;
    _stopping = true;
    _ticker?.cancel();
    final result = await _runService.stopRun();
    _horrorService.dispose();

    if (mounted) {
      if (result != null && result.id != null) {
        context.go('/result', extra: {
          'runId': result.id!,
          'result': result.challengeResult,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('기록이 너무 짧아 저장되지 않았습니다')),
        );
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _runService.removeListener(_onRunUpdate);
    _runService.dispose();
    _pageController.dispose();
    _vignetteAnim.dispose();
    _shadowPingAnim.dispose();
    super.dispose();
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmStop();
      },
      child: Scaffold(
        backgroundColor: SRColors.background,
        body: Stack(
          children: [
            // Full-screen dark map
            _buildNaverMap(onReady: (c) => _mapController = c),
            // Red vignette overlay
            _buildVignetteOverlay(),
            // Top HUD left: pace + distance
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 16,
              child: _buildHudPill(),
            ),
            // Top HUD right: shadow distance badge
            if (widget.shadowRunId != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 16,
                child: _buildDangerBadge(),
              ),
            // Speed warning banner
            if (_runService.speedWarning != null)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 40,
                right: 40,
                child: _buildSpeedWarningBanner(),
              ),
            // Bottom controls + threat bar
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomArea(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNaverMap({required void Function(NaverMapController) onReady}) {
    return NaverMap(
      options: const NaverMapViewOptions(
        mapType: NMapType.navi,
        nightModeEnable: true,
        initialCameraPosition: NCameraPosition(
          target: NLatLng(37.5665, 126.978),
          zoom: 16,
        ),
        scrollGesturesEnable: true,
        zoomGesturesEnable: true,
        rotationGesturesEnable: false,
        tiltGesturesEnable: false,
      ),
      onMapReady: onReady,
    );
  }

  Widget _buildVignetteOverlay() {
    final intensity = _horrorService.vignetteIntensity;
    return AnimatedBuilder(
      listenable: _vignetteAnim,
      builder: (context, _) {
        final pulse = 0.8 + _vignetteAnim.value * 0.2;
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                // Inner top/sides vignette
                BoxShadow(
                  color: const Color(0xFFFF0044)
                      .withValues(alpha: 0.15 * intensity * pulse),
                  blurRadius: 150,
                  spreadRadius: -20,
                ),
                // Inner bottom vignette (stronger)
                BoxShadow(
                  color: const Color(0xFFFF0044)
                      .withValues(alpha: 0.3 * intensity * pulse),
                  blurRadius: 200,
                  spreadRadius: -10,
                  offset: const Offset(0, 100),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHudPill() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: SRColors.surfaceContainerLow.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: SRColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _hudStat(S.pace, _runService.formattedPace),
              Container(
                width: 1,
                height: 28,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.white.withValues(alpha: 0.1),
              ),
              _hudStat(
                S.dist,
                _runService.totalDistanceM >= 1000
                    ? '${(_runService.totalDistanceM / 1000).toStringAsFixed(2)}km'
                    : '${_runService.totalDistanceM.toInt()}m',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hudStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: SRTheme.labelMedium.copyWith(
            color: SRColors.textMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
            color: SRColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDangerBadge() {
    final text = _formatShadowDistance();

    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: SRColors.secondaryContainer.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: SRColors.primaryContainer.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shadow ping indicator
              AnimatedBuilder(
                listenable: _shadowPingAnim,
                builder: (context, _) {
                  return Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: SRColors.primaryContainer,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: SRColors.primaryContainer
                              .withValues(alpha: 1.0 - _shadowPingAnim.value),
                          blurRadius: 8 * _shadowPingAnim.value,
                          spreadRadius: 2 * _shadowPingAnim.value,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Text(
                '${S.shadow} $text',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedWarningBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: SRColors.primaryContainer.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: SRColors.primaryContainer.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: SRColors.primaryContainer,
                size: 18,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _runService.speedWarning!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: SRColors.primaryContainer,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SRColors.background.withValues(alpha: 0),
            SRColors.background.withValues(alpha: 0.7),
            SRColors.background.withValues(alpha: 0.95),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Threat bar
          if (widget.shadowRunId != null) ...[
            _buildThreatBar(),
            const SizedBox(height: 20),
          ],
          // Control buttons
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildThreatBar() {
    final level = _horrorService.currentLevel;
    double progress;
    String levelLabel;
    switch (level) {
      case ThreatLevel.safe:
        progress = 0.15;
        levelLabel = '15%';
      case ThreatLevel.warning:
        progress = 0.45;
        levelLabel = '45%';
      case ThreatLevel.danger:
        progress = 0.70;
        levelLabel = '70%';
      case ThreatLevel.critical:
        progress = 1.0;
        levelLabel = '100%';
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              S.threatLevel,
              style: SRTheme.labelMedium.copyWith(
                color: SRColors.textMuted,
              ),
            ),
            Text(
              '$levelLabel ${S.proximity}',
              style: SRTheme.labelMedium.copyWith(
                color: SRColors.primaryContainer,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 4,
          width: double.infinity,
          decoration: BoxDecoration(
            color: SRColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  colors: [SRColors.secondaryContainer, SRColors.primaryContainer],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pause button
        GestureDetector(
          onTap: _togglePause,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SRColors.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: SRColors.divider),
            ),
            child: Icon(
              _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: SRColors.textPrimary,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Stop button
        GestureDetector(
          onTap: _confirmStop,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: SRColors.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SRColors.primaryContainer.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  String _formatShadowDistance() {
    final dist = _runService.shadowDistanceM;
    if (dist.isInfinite) return '---';
    return '${dist >= 0 ? '+' : ''}${dist.toInt()}m';
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}
