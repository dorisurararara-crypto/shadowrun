import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/services/running_service.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/services/horror_service.dart';
import 'package:shadowrun/core/services/marathon_service.dart';
import 'package:shadowrun/core/services/solo_tts_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/shared/models/run_model.dart';

class RunningScreen extends StatefulWidget {
  final int? shadowRunId;
  final String runMode; // 'doppelganger', 'marathon', 'freerun'
  final bool sameLocation; // 도플갱어: 같은 장소 vs 다른 장소

  const RunningScreen({super.key, this.shadowRunId, this.runMode = 'freerun', this.sameLocation = true});

  @override
  State<RunningScreen> createState() => _RunningScreenState();
}

class _RunningScreenState extends State<RunningScreen>
    with TickerProviderStateMixin {
  late final RunningService _runService;
  late final HorrorService _horrorService;
  MarathonService? _marathonService;
  SoloTtsService? _soloTtsService;
  final AudioPlayer _stadiumPlayer = AudioPlayer();
  final PageController _pageController = PageController(initialPage: 0);
  int _lastMarathonKm = 0;
  bool _stadiumFinaleEnabled = false;
  bool _stadiumFinalePlaying = false;
  late bool _isSameLocation;
  NaverMapController? _mapController;

  Timer? _ticker;
  bool _paused = false;
  bool _stopping = false;
  String _runMode = 'fullmap';
  late AnimationController _vignetteAnim;
  late AnimationController _shadowPingAnim;

  // Jumpscare
  late AnimationController _jumpscareFlashAnim;
  late AnimationController _jumpscareShakeAnim;
  bool _jumpscareTriggered = false;

  // 차량 감지 자동 일시정지
  int _vehicleDetectCount = 0;

  // 화살표 마커 아이콘
  NOverlayImage? _runnerArrowIcon;
  NOverlayImage? _shadowArrowIcon;
  NOverlayImage? _kmSplitIcon;

  @override
  void initState() {
    super.initState();
    _runService = RunningService();
    _horrorService = HorrorService();
    _isSameLocation = widget.sameLocation;
    _runService.addListener(_onRunUpdate);
    _loadRunMode();

    _vignetteAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _shadowPingAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _jumpscareFlashAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );

    _jumpscareShakeAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );

    _startRun();
    _createMarkerIcons();
  }

  Future<void> _createMarkerIcons() async {
    _runnerArrowIcon = await NOverlayImage.fromWidget(
      widget: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: SRColors.runner,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: SRColors.runner.withValues(alpha: 0.6), blurRadius: 8)],
        ),
        child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 18),
      ),
      size: const Size(32, 32),
      context: context,
    );
    _shadowArrowIcon = await NOverlayImage.fromWidget(
      widget: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: SRColors.shadow,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: SRColors.shadow.withValues(alpha: 0.6), blurRadius: 8)],
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 16),
      ),
      size: const Size(28, 28),
      context: context,
    );
    _kmSplitIcon = await NOverlayImage.fromWidget(
      widget: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: SRColors.onSurface,
          shape: BoxShape.circle,
          border: Border.all(color: SRColors.background, width: 2),
        ),
      ),
      size: const Size(22, 22),
      context: context,
    );
  }

  Future<void> _loadRunMode() async {
    final mode = await DatabaseHelper.getSetting('run_mode');
    if (mode != null && mounted) {
      setState(() => _runMode = mode);
    }
  }

  Future<void> _startRun() async {
    try {
      // 화면 꺼짐 방지
      WakelockPlus.enable();

      final voice = await DatabaseHelper.getSetting('voice') ?? 'harry';
      final speedStr = await DatabaseHelper.getSetting('shadow_speed') ?? '1.0';
      final shadowSpeed = double.tryParse(speedStr) ?? 1.0;
      final stadiumSetting = await DatabaseHelper.getSetting('stadium_finale');
      _stadiumFinaleEnabled = stadiumSetting != 'false';
      await _horrorService.initialize(voice: voice);

      // 모드별 서비스 초기화
      if (widget.runMode == 'marathon') {
        _marathonService = MarathonService();
        await _marathonService!.initialize(voice: voice);
      } else if (widget.runMode == 'freerun') {
        _soloTtsService = SoloTtsService();
        await _soloTtsService!.initialize(voice: voice);
      }

      final ok = await _runService.startRun(
        shadowRunId: widget.shadowRunId,
        shadowSpeedMultiplier: shadowSpeed,
      );
      if (!ok && mounted) {
        WakelockPlus.disable();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.gpsRequired)),
        );
        context.pop();
        return;
      }

      // 모드별 시작 TTS
      if (widget.runMode == 'doppelganger') {
        await _horrorService.playStartTts();
      } else if (widget.runMode == 'marathon') {
        await _marathonService?.playStartTts();
      } else {
        await _soloTtsService?.playStartTts();
      }

      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_paused && mounted) {
          setState(() {});
          _checkVehicleSpeed();
          if (widget.runMode == 'doppelganger') {
            _updateHorror();
          } else if (widget.runMode == 'marathon') {
            _updateMarathon();
          }
          _updateMap();
        }
      });
    } catch (e) {
      debugPrint('러닝 시작 에러: $e');
      if (mounted) {
        WakelockPlus.disable();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.gpsRequired)),
        );
        context.pop();
      }
    }
  }

  void _onRunUpdate() {
    if (mounted) setState(() {});
  }

  bool _vehiclePaused = false; // 차량 감지로 일시정지된 상태

  void _checkVehicleSpeed() {
    if (_runService.speedWarning == S.tooFast) {
      _vehicleDetectCount++;
      if (_vehicleDetectCount >= 3 && !_paused) {
        _paused = true;
        _vehiclePaused = true;
        _runService.pauseRun();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.vehiclePaused),
            backgroundColor: SRColors.primaryContainer,
          ),
        );
      }
    } else {
      _vehicleDetectCount = 0;
      // 차량 감지로 일시정지된 상태에서 정상 속도로 돌아오면 자동 재개
      if (_vehiclePaused && _paused) {
        _paused = false;
        _vehiclePaused = false;
        _runService.resumeRun();
      }
    }
  }

  Future<void> _updateHorror() async {
    if (widget.shadowRunId == null) return;
    final dist = _runService.shadowDistanceM;
    if (!dist.isInfinite) {
      await _horrorService.updateThreat(dist);
      // 점프스케어 트리거 (시작 5초 후부터)
      if (_horrorService.currentLevel == ThreatLevel.critical &&
          !_jumpscareTriggered &&
          _runService.durationS > 5) {
        _triggerJumpscare();
      }
    }
  }

  bool _marathonTtsPlaying = false;

  Future<void> _updateMarathon() async {
    if (_marathonService == null || _marathonTtsPlaying) return;
    final currentKm = (_runService.totalDistanceM / 1000).floor();
    if (currentKm > _lastMarathonKm) {
      _lastMarathonKm = currentKm;
      _marathonTtsPlaying = true;
      // km 마일스톤 TTS
      await _marathonService!.playKmTts(currentKm);
      // 페이스 피드백 (2km부터, km TTS 후 4초 대기)
      if (currentKm >= 2) {
        await Future.delayed(const Duration(seconds: 4));
        final avgHistorical = await DatabaseHelper.getAveragePace();
        await _marathonService!.playPaceTts(
          _runService.avgPace,
          avgHistorical,
          null,
        );
      }
      _marathonTtsPlaying = false;
    }
  }

  void _triggerJumpscare() {
    _jumpscareTriggered = true;
    _jumpscareFlashAnim.repeat(reverse: true);
    _jumpscareShakeAnim.repeat();
    setState(() {});
    // 1.5초 후 결과 화면으로 자동 이동
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && !_stopping) _stopRun();
    });
  }

  void _updateMap() {
    final pos = _runService.currentPosition;
    if (pos == null || _mapController == null) return;
    final target = NLatLng(pos.latitude, pos.longitude);
    _updateMapOverlays(_mapController!, target);
  }

  final Set<String> _activeOverlayIds = {};

  void _safeDeleteOverlay(NaverMapController controller, NOverlayType type, String id) {
    if (_activeOverlayIds.remove('${type.name}:$id')) {
      try {
        controller.deleteOverlay(NOverlayInfo(type: type, id: id));
      } catch (_) {}
    }
  }

  void _safeAddOverlay<T extends NAddableOverlay>(NaverMapController controller, T overlay) {
    _activeOverlayIds.add('${overlay.info.type.name}:${overlay.info.id}');
    controller.addOverlay(overlay);
  }

  void _clearDynamicOverlays(NaverMapController controller) {
    _safeDeleteOverlay(controller, NOverlayType.marker, 'runner');
    _safeDeleteOverlay(controller, NOverlayType.marker, 'shadow');
    _safeDeleteOverlay(controller, NOverlayType.circleOverlay, 'runner_glow');
    _safeDeleteOverlay(controller, NOverlayType.circleOverlay, 'shadow_glow');
    _safeDeleteOverlay(controller, NOverlayType.pathOverlay, 'runner_path');
    _safeDeleteOverlay(controller, NOverlayType.pathOverlay, 'shadow_path');
  }

  void _updateMapOverlays(NaverMapController controller, NLatLng target) {
    controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: target),
    );

    // 기존 오버레이 삭제 후 재생성 (addOverlay는 기존 것을 업데이트하지 않음)
    _clearDynamicOverlays(controller);

    // Runner glow circle
    _safeAddOverlay(controller, NCircleOverlay(
      id: 'runner_glow',
      center: target,
      radius: 12,
      color: SRColors.runner.withValues(alpha: 0.15),
      outlineColor: SRColors.runner.withValues(alpha: 0.3),
      outlineWidth: 2,
    ));

    // Runner arrow marker (방향 표시)
    final runnerMarker = NMarker(
      id: 'runner',
      position: target,
      size: const Size(32, 32),
      angle: _runService.heading,
    );
    if (_runnerArrowIcon != null) {
      runnerMarker.setIcon(_runnerArrowIcon!);
    } else {
      runnerMarker.setIconTintColor(SRColors.runner);
    }
    _safeAddOverlay(controller, runnerMarker);

    // Runner path polyline
    final runnerCoords = _runService.points
        .map((p) => NLatLng(p.latitude, p.longitude))
        .toList();
    if (runnerCoords.length >= 2) {
      _safeAddOverlay(controller, NPathOverlay(
        id: 'runner_path',
        coords: runnerCoords,
        color: SRColors.runner.withValues(alpha: 0.8),
        outlineColor: SRColors.runner.withValues(alpha: 0.3),
        width: 8,
      ));
    }

    // km 스플릿 마커
    _addKmSplitMarkers(controller, _runService.points);

    // Shadow marker + glow (같은 장소일 때만 표시)
    final shadowPoint = _runService.currentShadowPoint;
    if (shadowPoint != null && _isSameLocation) {
      final shadowLatLng = NLatLng(shadowPoint.latitude, shadowPoint.longitude);

      _safeAddOverlay(controller, NCircleOverlay(
        id: 'shadow_glow',
        center: shadowLatLng,
        radius: 15,
        color: SRColors.shadow.withValues(alpha: 0.2),
        outlineColor: SRColors.shadow.withValues(alpha: 0.5),
        outlineWidth: 3,
      ));

      final shadowMarker = NMarker(
        id: 'shadow',
        position: shadowLatLng,
        size: const Size(28, 28),
      );
      if (_shadowArrowIcon != null) {
        shadowMarker.setIcon(_shadowArrowIcon!);
      } else {
        shadowMarker.setIconTintColor(SRColors.shadow);
      }
      _safeAddOverlay(controller, shadowMarker);
    }

    // Shadow path polyline (같은 장소일 때만)
    final shadowPoints = _runService.shadowPoints;
    final shadowIdx = _runService.currentShadowIndex;
    if (_isSameLocation && shadowPoints != null && shadowIdx >= 1) {
      final shadowCoords = shadowPoints
          .take(shadowIdx + 1)
          .map((p) => NLatLng(p.latitude, p.longitude))
          .toList();
      if (shadowCoords.length >= 2) {
        _safeAddOverlay(controller, NPathOverlay(
          id: 'shadow_path',
          coords: shadowCoords,
          color: SRColors.shadow.withValues(alpha: 0.5),
          outlineColor: SRColors.shadow.withValues(alpha: 0.2),
          width: 6,
        ));
      }
    }
  }

  void _addKmSplitMarkers(NaverMapController controller, List<RunPoint> points) {
    if (points.length < 2 || _kmSplitIcon == null) return;
    double dist = 0;
    int nextKm = 1;
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final dx = (p1.latitude - p0.latitude);
      final dy = (p1.longitude - p0.longitude);
      dist += sqrt(dx * dx + dy * dy) * 111320; // 대략적 미터 변환
      if (dist >= nextKm * 1000) {
        final marker = NMarker(
          id: 'km_$nextKm',
          position: NLatLng(p1.latitude, p1.longitude),
          size: const Size(22, 22),
        );
        marker.setIcon(_kmSplitIcon!);
        marker.setCaption(NOverlayCaption(
          text: '${nextKm}km',
          textSize: 10,
          color: SRColors.onSurface,
          haloColor: SRColors.background,
        ));
        controller.addOverlay(marker);
        nextKm++;
      }
    }
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
      if (_paused) {
        _runService.pauseRun();
      } else {
        _runService.resumeRun();
      }
    });
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

    // 웨이크락 해제
    WakelockPlus.disable();

    // 스타디움 피날레 (종료 직전 관중 함성)
    if (_stadiumFinaleEnabled && !_jumpscareTriggered) {
      try {
        await _stadiumPlayer.setAsset('assets/audio/stadium_finale.mp3');
        _stadiumPlayer.setVolume(0.8);
        _stadiumPlayer.play();
        await Future.delayed(const Duration(seconds: 3));
      } catch (_) {}
    }

    final result = await _runService.stopRun();

    // 모드별 종료 TTS
    if (widget.runMode == 'doppelganger' && result != null) {
      if (result.challengeResult == 'win') {
        await _horrorService.playSurvivedTts();
      } else if (result.challengeResult == 'lose') {
        await _horrorService.playDefeatedTts();
      }
    } else if (widget.runMode == 'marathon') {
      await _marathonService?.playEndTts();
    } else if (widget.runMode == 'freerun') {
      await _soloTtsService?.playEndTts();
    }

    _horrorService.dispose();
    _marathonService?.dispose();
    _soloTtsService?.dispose();

    if (mounted) {
      if (result != null && result.id != null) {
        context.go('/result', extra: {
          'runId': result.id!,
          'result': result.challengeResult,
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.runTooShort)),
        );
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _ticker?.cancel();
    _runService.removeListener(_onRunUpdate);
    _runService.dispose();
    _pageController.dispose();
    _vignetteAnim.dispose();
    _shadowPingAnim.dispose();
    _jumpscareFlashAnim.dispose();
    _jumpscareShakeAnim.dispose();
    _stadiumPlayer.dispose();
    super.dispose();
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    Widget content = Scaffold(
      backgroundColor: SRColors.background,
      body: _runMode == 'mapcenter'
          ? _buildModeA()
          : _runMode == 'datacenter'
              ? _buildModeB()
              : _buildModeC(),
    );

    // 점프스케어 화면 떨림
    if (_jumpscareTriggered) {
      final shakeContent = content;
      content = AnimatedBuilder(
        listenable: _jumpscareShakeAnim,
        builder: (context, _) {
          final dx = sin(_jumpscareShakeAnim.value * pi * 20) * 12;
          final dy = cos(_jumpscareShakeAnim.value * pi * 16) * 8;
          return Transform.translate(offset: Offset(dx, dy), child: shakeContent);
        },
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_jumpscareTriggered) _confirmStop();
      },
      child: Stack(
        children: [
          content,
          // 점프스케어 빨간 플래시
          if (_jumpscareTriggered)
            AnimatedBuilder(
              listenable: _jumpscareFlashAnim,
              builder: (context, _) => IgnorePointer(
                child: Container(
                  color: Color.fromRGBO(
                    255, 0, 0,
                    0.5 + _jumpscareFlashAnim.value * 0.3,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // === MODE C: Full Map + Overlay (default) ===
  Widget _buildModeC() {
    return Stack(
      children: [
        _buildNaverMap(onReady: (c) => _mapController = c),
        _buildVignetteOverlay(),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: _buildHudPill(),
        ),
        if (widget.shadowRunId != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: _buildDangerBadge(),
          ),
        // 음성 모드 배지 (다른 장소에서 도전 중)
        if (widget.shadowRunId != null && !_isSameLocation)
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 16,
            right: 16,
            child: _buildVoiceOnlyBadge(),
          ),
        if (_runService.speedWarning != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + (_isSameLocation ? 60 : 110),
            left: 40,
            right: 40,
            child: _buildSpeedWarningBanner(),
          ),
        Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomArea()),
      ],
    );
  }

  // === MODE A: Map Center (top 60% map, bottom 40% stats) ===
  Widget _buildModeA() {
    return Stack(
      children: [
        Column(
          children: [
            // Top 60% map
            Expanded(
              flex: 6,
              child: Stack(
                children: [
                  _buildNaverMap(onReady: (c) => _mapController = c),
                  _buildVignetteOverlay(),
                  if (_runService.speedWarning != null)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 12,
                      left: 40, right: 40,
                      child: _buildSpeedWarningBanner(),
                    ),
                ],
              ),
            ),
            // Bottom 40% stats
            Expanded(
              flex: 4,
              child: Container(
                color: SRColors.background,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _modeAStat(S.dist, _runService.totalDistanceM >= 1000
                            ? '${(_runService.totalDistanceM / 1000).toStringAsFixed(2)}km'
                            : '${_runService.totalDistanceM.toInt()}m'),
                        _modeAStat(S.pace, _runService.formattedPace),
                        _modeAStat(S.duration, _runService.formattedDuration),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.shadowRunId != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: SRColors.secondaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${S.shadow} ${_formatShadowDistance()}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18, fontWeight: FontWeight.w700, color: SRColors.primaryContainer,
                          ),
                        ),
                      ),
                    const Spacer(),
                    _buildControlButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // === MODE B: Data Center (big pace, mini map) ===
  Widget _buildModeB() {
    return Stack(
      children: [
        Container(
          color: SRColors.background,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Big pace
                  Text(
                    S.pace,
                    style: SRTheme.labelMedium.copyWith(color: SRColors.textMuted),
                  ),
                  Text(
                    _runService.formattedPace,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 72, fontWeight: FontWeight.w900, color: SRColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Shadow distance badge
                  if (widget.shadowRunId != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: SRColors.secondaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: SRColors.primaryContainer.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${S.shadow} ${_formatShadowDistance()}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16, fontWeight: FontWeight.w700, color: SRColors.primaryContainer,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Stats row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _modeAStat(S.dist, _runService.totalDistanceM >= 1000
                          ? '${(_runService.totalDistanceM / 1000).toStringAsFixed(2)}km'
                          : '${_runService.totalDistanceM.toInt()}m'),
                      _modeAStat(S.duration, _runService.formattedDuration),
                      _modeAStat(S.calories, '${_runService.calories}'),
                    ],
                  ),
                  const Spacer(),
                  // Mini map
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: SRColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildNaverMap(onReady: (c) => _mapController = c),
                  ),
                  const SizedBox(height: 16),
                  _buildControlButtons(),
                ],
              ),
            ),
          ),
        ),
        _buildVignetteOverlay(),
        if (_runService.speedWarning != null)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 40, right: 40,
            child: _buildSpeedWarningBanner(),
          ),
      ],
    );
  }

  Widget _modeAStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: GoogleFonts.spaceGrotesk(
          fontSize: 22, fontWeight: FontWeight.w700, color: SRColors.onSurface,
        )),
        const SizedBox(height: 4),
        Text(label, style: SRTheme.labelMedium.copyWith(color: SRColors.textMuted)),
      ],
    );
  }


  String _formatShadowDistance() {
    final dist = _runService.shadowDistanceM;
    if (dist.isInfinite) return '--';
    final prefix = dist >= 0 ? '+' : '';
    return '$prefix${dist.abs().toInt()}m';
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
        final pulse = 0.7 + _vignetteAnim.value * 0.3;
        return IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0044)
                      .withValues(alpha: 0.2 * intensity * pulse),
                  blurRadius: 180,
                  spreadRadius: -10,
                ),
                BoxShadow(
                  color: const Color(0xFFFF0044)
                      .withValues(alpha: 0.4 * intensity * pulse),
                  blurRadius: 240,
                  spreadRadius: 0,
                  offset: const Offset(0, 120),
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

  Widget _buildVoiceOnlyBadge() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: SRColors.surfaceContainerLow.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SRColors.primary.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.headphones, color: SRColors.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(S.voiceOnlyMode, style: GoogleFonts.spaceGrotesk(
                      fontSize: 13, fontWeight: FontWeight.w700, color: SRColors.primary,
                    )),
                    Text(S.voiceOnlyDesc, style: GoogleFonts.inter(
                      fontSize: 10, color: SRColors.textMuted,
                    )),
                  ],
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
      case ThreatLevel.aheadClose:
        progress = 0.10;
        levelLabel = '10%';
      case ThreatLevel.aheadMid:
        progress = 0.05;
        levelLabel = '5%';
      case ThreatLevel.aheadFar:
        progress = 0.0;
        levelLabel = '0%';
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
