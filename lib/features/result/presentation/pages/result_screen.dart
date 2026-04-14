import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/ad_service.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

class ResultScreen extends StatefulWidget {
  final int runId;
  final String? result; // 'win', 'lose', null

  const ResultScreen({super.key, required this.runId, this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with TickerProviderStateMixin {
  RunModel? _run;
  List<RunPoint> _points = [];
  List<RunPoint> _shadowPoints = [];
  bool _loading = true;
  BannerAd? _bannerAd;
  bool _bannerReady = false;

  late AnimationController _resultAnim;
  late Animation<double> _resultScale;
  late Animation<double> _resultOpacity;
  late AnimationController _glowAnim;
  late AnimationController _pulseAnim;
  late AnimationController _statsAnim;

  bool get _isWin => widget.result == 'win';
  bool get _isLose => widget.result == 'lose';
  bool get _isChallenge => widget.result != null;

  @override
  void initState() {
    super.initState();
    _resultAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _resultScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _resultAnim, curve: Curves.elasticOut),
    );
    _resultOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _resultAnim,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );
    _glowAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _statsAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    SfxService().reportOpen();
    _loadData();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    if (PurchaseService().isPro) return; // PRO 유저는 광고 없음
    _bannerAd = AdService().createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _bannerReady = true);
      },
    );
    _bannerAd!.load();
  }

  Future<void> _loadData() async {
    try {
      _run = await DatabaseHelper.getRun(widget.runId);
      _points = await DatabaseHelper.getRunPoints(widget.runId);

      if (_run?.shadowRunId != null) {
        _shadowPoints = await DatabaseHelper.getRunPoints(_run!.shadowRunId!);
      }
    } catch (e) {
      debugPrint('결과 데이터 로드 에러: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
      _resultAnim.forward();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _statsAnim.forward();
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _resultAnim.dispose();
    _glowAnim.dispose();
    _pulseAnim.dispose();
    _statsAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: SRColors.background,
        body: Center(
          child: CircularProgressIndicator(color: SRColors.primaryContainer),
        ),
      );
    }

    final run = _run;
    if (run == null) {
      return Scaffold(
        backgroundColor: SRColors.background,
        body: Center(
          child: Text(
            S.isKo ? '기록을 찾을 수 없습니다' : 'Record not found',
            style: SRTheme.bodyMedium,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: SRColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildRunStatus(),
                    const SizedBox(height: 28),
                    _buildStatsGrid(run),
                    const SizedBox(height: 24),
                    _buildMapSection(),
                    const SizedBox(height: 24),
                    _buildIncidentReport(),
                    const SizedBox(height: 32),
                    _buildBannerAd(),
                    _buildActions(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
      child: Row(
        children: [
          Text(
            S.debrief,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: SRColors.primary,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _shareResult,
            icon: const Icon(Icons.share_outlined,
                color: SRColors.textPrimary, size: 22),
          ),
          IconButton(
            onPressed: () {
              SfxService().tapCard();
              context.go('/');
            },
            icon: const Icon(Icons.close_rounded,
                color: SRColors.textPrimary, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildRunStatus() {
    String statusText;
    Color statusColor;
    if (_isWin) {
      statusText = S.survived;
      statusColor = SRColors.safe;
    } else if (_isLose) {
      statusText = S.caught;
      statusColor = SRColors.primaryContainer;
    } else {
      statusText = S.complete;
      statusColor = SRColors.textPrimary;
    }

    return AnimatedBuilder(
      listenable:
          Listenable.merge([_resultAnim, _isWin ? _glowAnim : _pulseAnim]),
      builder: (context, _) {
        final glowOpacity = _isWin
            ? 0.3 + _glowAnim.value * 0.4
            : _isLose
                ? 0.5 + _pulseAnim.value * 0.5
                : 0.0;
        final scale = _isLose
            ? _resultScale.value * (0.95 + _pulseAnim.value * 0.05)
            : _resultScale.value;

        return Opacity(
          opacity: _resultOpacity.value,
          child: Transform.scale(
            scale: scale,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.runStatus,
                  style: SRTheme.labelMedium.copyWith(
                    color: SRColors.textMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  statusText,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: statusColor.withValues(alpha: glowOpacity),
                        blurRadius: 40,
                      ),
                      Shadow(
                        color: statusColor.withValues(alpha: glowOpacity * 0.5),
                        blurRadius: 80,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isWin
                      ? '도플갱어를 따돌렸다'
                      : _isLose
                          ? '도플갱어에게 잡혔다'
                          : '러닝 완료',
                  style: SRTheme.bodyMedium.copyWith(
                    color: SRColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(RunModel run) {
    return FadeTransition(
      opacity: _statsAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _statsAnim,
          curve: Curves.easeOut,
        )),
        child: Column(
          children: [
            Row(
              children: [
                _bentoCard(
                  label: S.distance,
                  value: run.formattedDistance,
                  borderColor: SRColors.safe,
                ),
                const SizedBox(width: 12),
                _bentoCard(
                  label: S.duration,
                  value: run.formattedDuration,
                  borderColor: SRColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _bentoCard(
                  label: S.avgPace,
                  value: run.formattedPace,
                  borderColor: SRColors.primaryContainer,
                ),
                const SizedBox(width: 12),
                _bentoCard(
                  label: S.calories,
                  value: '${run.calories}kcal',
                  borderColor: SRColors.outline,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bentoCard({
    required String label,
    required String value,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SRColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: borderColor, width: 3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: SRTheme.labelMedium.copyWith(
                color: SRColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: SRTheme.statNumber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    if (_points.isEmpty) return const SizedBox.shrink();

    final centerLat =
        _points.map((p) => p.latitude).reduce((a, b) => a + b) / _points.length;
    final centerLng =
        _points.map((p) => p.longitude).reduce((a, b) => a + b) /
            _points.length;

    return Container(
      decoration: BoxDecoration(
        color: SRColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  S.visualReconstruction,
                  style: SRTheme.labelMedium.copyWith(
                    color: SRColors.textMuted,
                  ),
                ),
                const Spacer(),
                if (_isChallenge)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: SRColors.primaryContainer,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  SRColors.primaryContainer.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        S.threatDetected,
                        style: SRTheme.labelMedium.copyWith(
                          color: SRColors.primaryContainer,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Map
          Container(
            height: 220,
            margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: NaverMap(
              options: NaverMapViewOptions(
                initialCameraPosition: NCameraPosition(
                  target: NLatLng(centerLat, centerLng),
                  zoom: 15,
                ),
                mapType: NMapType.navi,
                nightModeEnable: true,
                scrollGesturesEnable: false,
                zoomGesturesEnable: false,
                rotationGesturesEnable: false,
                tiltGesturesEnable: false,
              ),
              onMapReady: (controller) {
                // Runner route (green)
                final runnerCoords = _points
                    .map((p) => NLatLng(p.latitude, p.longitude))
                    .toList();
                if (runnerCoords.length >= 2) {
                  controller.addOverlay(NPathOverlay(
                    id: 'runner_route',
                    coords: runnerCoords,
                    color: SRColors.runner,
                    outlineColor: SRColors.runner.withValues(alpha: 0.3),
                    width: 5,
                  ));
                }

                // Shadow route (red)
                if (_shadowPoints.length >= 2) {
                  final shadowCoords = _shadowPoints
                      .map((p) => NLatLng(p.latitude, p.longitude))
                      .toList();
                  controller.addOverlay(NPathOverlay(
                    id: 'shadow_route',
                    coords: shadowCoords,
                    color: SRColors.shadow,
                    outlineColor: SRColors.shadow.withValues(alpha: 0.3),
                    width: 4,
                  ));
                }

                // Fit bounds
                final allCoords = [
                  ...runnerCoords,
                  ..._shadowPoints
                      .map((p) => NLatLng(p.latitude, p.longitude)),
                ];
                if (allCoords.length >= 2) {
                  final bounds = NLatLngBounds.from(allCoords);
                  controller.updateCamera(
                    NCameraUpdate.fitBounds(bounds,
                        padding: const EdgeInsets.all(40)),
                  );
                }

                // Start/end markers
                if (runnerCoords.isNotEmpty) {
                  controller.addOverlay(NMarker(
                    id: 'start',
                    position: runnerCoords.first,
                    iconTintColor: SRColors.runner,
                    size: const Size(20, 20),
                  ));
                  controller.addOverlay(NMarker(
                    id: 'end',
                    position: runnerCoords.last,
                    iconTintColor: SRColors.textPrimary,
                    size: const Size(20, 20),
                  ));
                }

                // km 스플릿 마커
                _addKmSplitsToMap(controller, _points);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _generateIncidentText() {
    final run = _run;
    if (run == null) return '';

    final durationMin = (run.durationS / 60).toStringAsFixed(1);

    if (!_isChallenge) {
      return S.isKo
          ? '새로운 영역이 기록되었습니다. ${durationMin}분간 ${run.formattedDistance}를 달렸습니다. 도플갱어가 당신의 데이터를 확보했습니다.'
          : 'New territory mapped. ${run.formattedDistance} covered in $durationMin minutes. The shadow now has your data.';
    }

    if (_isWin) {
      double closestDist = double.infinity;
      double closestKm = 0;
      double avgLead = 0;
      if (_shadowPoints.isNotEmpty && _points.isNotEmpty) {
        final shadowStartMs = _shadowPoints.first.timestampMs;
        final runnerStartMs = _points.first.timestampMs;
        double runnerDist = 0;
        double shadowDist = 0;
        int shadowIdx = 0;
        int count = 0;
        double leadSum = 0;

        for (int i = 1; i < _points.length; i++) {
          runnerDist += _distanceBetween(
            _points[i - 1].latitude, _points[i - 1].longitude,
            _points[i].latitude, _points[i].longitude,
          );
          final elapsedMs = _points[i].timestampMs - runnerStartMs;

          while (shadowIdx + 1 < _shadowPoints.length &&
              (_shadowPoints[shadowIdx + 1].timestampMs - shadowStartMs) <= elapsedMs) {
            shadowDist += _distanceBetween(
              _shadowPoints[shadowIdx].latitude, _shadowPoints[shadowIdx].longitude,
              _shadowPoints[shadowIdx + 1].latitude, _shadowPoints[shadowIdx + 1].longitude,
            );
            shadowIdx++;
          }

          final gap = (runnerDist - shadowDist).abs();
          if (gap < closestDist) {
            closestDist = gap;
            closestKm = runnerDist / 1000;
          }
          leadSum += runnerDist - shadowDist;
          count++;
        }
        avgLead = count > 0 ? leadSum / count : 0;
      }

      final closest = closestDist.isFinite ? closestDist.toInt() : 0;
      final km = closestKm.toStringAsFixed(1);
      final lead = avgLead.toInt();
      return S.isKo
          ? '도플갱어가 ${km}km 지점에서 ${closest}m까지 접근했습니다. 평균 ${lead}m 앞서 달렸습니다. 마지막 구간에서 강한 페이스를 유지했습니다.'
          : 'The shadow reached within $closest meters at marker $km km. You maintained an average lead of $lead meters.';
    } else {
      double overtakeKm = 0;
      double paceDropMin = 0;
      if (_shadowPoints.isNotEmpty && _points.isNotEmpty) {
        final shadowStartMs = _shadowPoints.first.timestampMs;
        final runnerStartMs = _points.first.timestampMs;
        double runnerDist = 0;
        double shadowDist = 0;
        int shadowIdx = 0;

        for (int i = 1; i < _points.length; i++) {
          runnerDist += _distanceBetween(
            _points[i - 1].latitude, _points[i - 1].longitude,
            _points[i].latitude, _points[i].longitude,
          );
          final elapsedMs = _points[i].timestampMs - runnerStartMs;

          while (shadowIdx + 1 < _shadowPoints.length &&
              (_shadowPoints[shadowIdx + 1].timestampMs - shadowStartMs) <= elapsedMs) {
            shadowDist += _distanceBetween(
              _shadowPoints[shadowIdx].latitude, _shadowPoints[shadowIdx].longitude,
              _shadowPoints[shadowIdx + 1].latitude, _shadowPoints[shadowIdx + 1].longitude,
            );
            shadowIdx++;
          }

          if (shadowDist > runnerDist && overtakeKm == 0) {
            overtakeKm = runnerDist / 1000;
            paceDropMin = elapsedMs / 60000;
          }
        }
      }

      final km = overtakeKm.toStringAsFixed(1);
      final min = paceDropMin.toStringAsFixed(1);
      return S.isKo
          ? '도플갱어가 ${km}km 지점에서 추월했습니다. ${min}분 시점에서 속도가 떨어졌습니다. 내일 더 강해져서 돌아오세요.'
          : 'The entity overtook you at the $km km mark. Your pace dropped at $min minutes. Train harder for tomorrow.';
    }
  }

  void _addKmSplitsToMap(NaverMapController controller, List<RunPoint> points) {
    if (points.length < 2) return;
    double dist = 0;
    int nextKm = 1;
    for (int i = 1; i < points.length; i++) {
      dist += _distanceBetween(
        points[i - 1].latitude, points[i - 1].longitude,
        points[i].latitude, points[i].longitude,
      );
      if (dist >= nextKm * 1000) {
        final marker = NMarker(
          id: 'km_$nextKm',
          position: NLatLng(points[i].latitude, points[i].longitude),
          iconTintColor: SRColors.onSurface,
          size: const Size(18, 18),
        );
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

  double _distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    const earthRadius = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  Widget _buildIncidentReport() {
    final subtitle = _generateIncidentText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SRColors.secondaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SRColors.secondaryContainer.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: SRColors.primaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.incidentReport,
                  style: SRTheme.labelLarge.copyWith(
                    color: SRColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: SRTheme.bodyMedium.copyWith(
                    color: SRColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerAd() {
    if (!_bannerReady || _bannerAd == null) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          alignment: Alignment.center,
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => context.push('/settings'),
          child: Text(
            S.proNoAds,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: SRColors.proBadge.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        // Share button (outlined)
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: _shareResult,
              icon: const Icon(Icons.share_outlined, size: 18),
              label: Text(
                S.share,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: SRColors.primary,
                side: const BorderSide(color: SRColors.primaryContainer),
                shape: const StadiumBorder(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Home button (gradient filled)
        Expanded(
          child: SizedBox(
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                gradient: const LinearGradient(
                  colors: [SRColors.primary, SRColors.primaryContainer],
                ),
                boxShadow: [
                  BoxShadow(
                    color: SRColors.primaryContainer.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MaterialButton(
                onPressed: () {
                  SfxService().tapCard();
                  context.go('/');
                },
                shape: const StadiumBorder(),
                child: Text(
                  S.home,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _shareResult() {
    if (_run == null) return;
    SfxService().share();
    final run = _run!;
    final resultText = _isWin
        ? S.survived
        : _isLose
            ? S.caught
            : S.complete;
    final text = '''
SHADOW RUN - $resultText

거리: ${run.formattedDistance}
시간: ${run.formattedDuration}
페이스: ${run.formattedPace}
칼로리: ${run.calories}kcal

#ShadowRun #도플갱어러닝''';
    Share.share(text);
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
