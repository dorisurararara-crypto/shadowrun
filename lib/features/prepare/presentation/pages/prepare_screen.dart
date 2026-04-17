import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:shadowrun/features/running/data/legend_runners.dart';
import 'package:shadowrun/features/prepare/presentation/layouts/mystic_prepare_layout.dart';
import 'package:shadowrun/features/prepare/presentation/layouts/pure_prepare_layout.dart';

class PrepareScreen extends StatefulWidget {
  final int? shadowRunId;

  const PrepareScreen({super.key, this.shadowRunId});

  @override
  State<PrepareScreen> createState() => _PrepareScreenState();
}

class _PrepareScreenState extends State<PrepareScreen>
    with TickerProviderStateMixin {
  static const _challengeQuotesKo = [
    '과거의 나를 이겨라. 잡히면 끝이다.',
    '그림자는 절대 잊지 않는다.',
    '오늘의 나는 어제보다 빠를까?',
    '뒤를 돌아보지 마라. 이미 쫓고 있다.',
    '공포를 연료로 바꿔라.',
    '한 발짝만 느려져도... 끝이다.',
    '어둠 속에서 들리는 발소리. 네 것이 아니다.',
    '기록은 거짓말을 하지 않는다.',
    '지난 나를 넘어서야 살아남는다.',
    '심장이 터질 것 같아도 멈추지 마라.',
    '그림자가 웃고 있다. 오늘은 잡을 수 있다고.',
    '두려움을 즐겨라. 그것이 너의 무기다.',
    '0.1초가 생사를 가른다.',
    '도망치는 것이 아니다. 이기는 것이다.',
    '이 길의 끝에서 기다리는 건... 더 강한 나.',
  ];
  static const _challengeQuotesEn = [
    'Beat your past self. Get caught and it\'s over.',
    'The shadow never forgets.',
    'Am I faster than yesterday?',
    'Don\'t look back. It\'s already chasing you.',
    'Turn fear into fuel.',
    'One step slower... and it\'s over.',
    'Footsteps in the dark. They\'re not yours.',
    'Records don\'t lie.',
    'Surpass your past self to survive.',
    'Even if your heart explodes, don\'t stop.',
    'The shadow is smiling. It thinks it can catch you today.',
    'Enjoy the fear. It\'s your weapon.',
    '0.1 seconds decides life or death.',
    'You\'re not running away. You\'re winning.',
    'What awaits at the end... is a stronger you.',
  ];
  static const _newRunQuotesKo = [
    '새로운 기록을 남겨라. 그림자가 지켜본다.',
    '오늘의 나를 기록하라.',
    '그림자에게 데이터를 제공하라.',
    '더 빠르게. 더 멀리. 그림자가 기다린다.',
    '새로운 도전이 시작된다.',
  ];
  static const _newRunQuotesEn = [
    'Leave a new record. The shadow watches.',
    'Record today\'s you.',
    'Feed data to the shadow.',
    'Faster. Farther. The shadow awaits.',
    'A new challenge begins.',
  ];

  bool _gpsReady = false;
  Timer? _gpsTimer;
  StreamSubscription<Position>? _gpsSub;
  RunModel? _shadowRun;
  List<RunPoint>? _shadowPoints;
  bool _loading = true;
  bool _countdownActive = false;
  int _countdownValue = 3;
  late AnimationController _countdownAnim;
  late Animation<double> _countdownScale;
  late AnimationController _pulseAnim;
  String _selectedQuote = '';
  String _selectedMode = 'marathon'; // 'marathon' or 'freerun'
  bool _tooFarFromStart = false;
  String _shadowLocationType = 'same'; // 'same' or 'different'
  List<Map<String, dynamic>> _shoes = [];
  int? _selectedShoeId;
  String? _selectedLegendId; // null이면 자유 러닝, id면 해당 전설과 대결
  // 자유 러닝(freerun) 페이스메이커 유령 — 선택적으로 목표 페이스 동반.
  bool _pacemakerEnabled = false;
  int _pacemakerSecPerKm = 360; // 6:00/km 기본

  bool get _isPro => PurchaseService().isPro;
  bool get _isChallenge => widget.shadowRunId != null;
  bool get _legendRequiredButMissing =>
      !_isChallenge && _selectedMode == 'marathon' && _selectedLegendId == null;
  bool get _canStart =>
      _gpsReady &&
      !(_tooFarFromStart && _shadowLocationType == 'same') &&
      !_legendRequiredButMissing;

  @override
  void initState() {
    super.initState();
    _countdownAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _countdownScale = Tween<double>(begin: 2.0, end: 0.8).animate(
      CurvedAnimation(parent: _countdownAnim, curve: Curves.easeOutBack),
    );
    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _init();
  }

  Future<void> _init() async {
    _startGpsCheck();
    if (_isChallenge) {
      _shadowRun = await DatabaseHelper.getRun(widget.shadowRunId!);
      _shadowPoints = await DatabaseHelper.getRunPoints(widget.shadowRunId!);
    }
    _shoes = await DatabaseHelper.getActiveShoes();
    // 첫 진입 시 첫 번째 전설(킵초게)을 기본 선택. PRO-only면 무료 전설 중 첫 번째.
    if (_selectedLegendId == null) {
      final first = LegendRunners.all.firstWhere(
        (r) => !r.isProOnly || _isPro,
        orElse: () => LegendRunners.all.first,
      );
      _selectedLegendId = first.id;
    }
    await _pickRandomQuote();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickRandomQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final quotesKo = _isChallenge ? _challengeQuotesKo : _newRunQuotesKo;
    final quotesEn = _isChallenge ? _challengeQuotesEn : _newRunQuotesEn;
    final prefKey = _isChallenge ? 'last_challenge_quote' : 'last_newrun_quote';
    final lastIndex = prefs.getInt(prefKey) ?? -1;
    final rng = Random();
    int index;
    if (quotesKo.length <= 1) {
      index = 0;
    } else {
      do {
        index = rng.nextInt(quotesKo.length);
      } while (index == lastIndex);
    }
    await prefs.setInt(prefKey, index);
    _selectedQuote = S.isKo ? quotesKo[index] : quotesEn[index];
  }

  void _startGpsCheck() {
    _checkGpsOnce();
    // 스트림으로 GPS 상태 모니터링 (폴링 대신)
    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        final gpsOk = pos.accuracy < 50;
        // 같은 위치 모드: 실시간 출발점 거리 체크
        bool tooFar = false;
        if (_isChallenge && _shadowLocationType == 'same' && _shadowPoints != null && _shadowPoints!.isNotEmpty) {
          final startPoint = _shadowPoints!.first;
          final distToStart = Geolocator.distanceBetween(
            pos.latitude, pos.longitude,
            startPoint.latitude, startPoint.longitude,
          );
          tooFar = distToStart > 200;
        }
        final wasReady = _gpsReady;
        setState(() {
          _gpsReady = gpsOk;
          _tooFarFromStart = tooFar;
        });
        if (!wasReady && gpsOk) {
          SfxService().gpsReady();
          SfxService().powerup();
        }
      },
      onError: (_) {
        if (mounted) setState(() => _gpsReady = false);
      },
    );
  }

  Future<void> _checkGpsOnce() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _gpsReady = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.isKo
                  ? 'GPS를 켜주세요. 설정 > 위치에서 활성화할 수 있습니다.'
                  : 'Please enable GPS. Go to Settings > Location.'),
              backgroundColor: SRColors.primaryContainer,
              action: SnackBarAction(
                label: S.isKo ? '설정' : 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openLocationSettings(),
              ),
            ),
          );
        }
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _gpsReady = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.isKo
                  ? 'GPS 권한이 필요합니다. 설정에서 위치 접근을 허용해주세요.'
                  : 'GPS permission is required. Please allow location access in Settings.'),
              backgroundColor: SRColors.primaryContainer,
              action: SnackBarAction(
                label: S.isKo ? '설정' : 'Settings',
                textColor: Colors.white,
                onPressed: () => Geolocator.openAppSettings(),
              ),
            ),
          );
        }
        return;
      }
    } catch (_) {
      if (mounted) setState(() => _gpsReady = false);
    }
  }

  void _startCountdown() {
    setState(() {
      _countdownActive = true;
      _countdownValue = 3;
    });
    SfxService().countdown();
    _countdownAnim.forward(from: 0);
    _runCountdownTick();
  }

  void _runCountdownTick() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted || !_countdownActive) return;
      if (_countdownValue > 1) {
        setState(() => _countdownValue--);
        _countdownAnim.forward(from: 0);
        _runCountdownTick();
      } else {
        SfxService().go();
        if (!mounted) return;
        if (_isChallenge) {
          context.go('/running', extra: {
            'shadowRunId': widget.shadowRunId,
            'mode': 'doppelganger',
            'sameLocation': _shadowLocationType == 'same',
            'shoeId': _selectedShoeId,
          });
        } else {
          context.go('/running', extra: {
            'mode': _selectedMode,
            'shoeId': _selectedShoeId,
            'legendId': _selectedMode == 'marathon' ? _selectedLegendId : null,
            'pacemakerPaceSec':
                _selectedMode == 'freerun' && _pacemakerEnabled
                    ? _pacemakerSecPerKm
                    : null,
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _gpsSub?.cancel();
    _countdownAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  void _showLegendLockedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.isKo
            ? '이 전설은 PRO 전용입니다. 업그레이드해서 함께 뛰세요.'
            : 'This legend is PRO only. Upgrade to run with them.'),
        backgroundColor: SRColors.primaryContainer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeId>(
      valueListenable: ThemeManager.I.themeIdNotifier,
      builder: (context, themeId, _) {
        if (themeId == ThemeId.koreanMystic) {
          if (_loading) {
            return const Scaffold(
              backgroundColor: Color(0xFF050302),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFC42029)),
              ),
            );
          }
          return MysticPrepareLayout(
            isChallenge: _isChallenge,
            gpsReady: _gpsReady,
            tooFarFromStart: _tooFarFromStart,
            canStart: _canStart,
            selectedQuote: _selectedQuote,
            selectedMode: _selectedMode,
            onModeChanged: (m) {
              SfxService().toggle();
              setState(() => _selectedMode = m);
            },
            shadowRun: _shadowRun,
            shadowLocationType: _shadowLocationType,
            onShadowLocationChanged: (t) {
              SfxService().toggle();
              setState(() => _shadowLocationType = t);
            },
            shoes: _shoes,
            selectedShoeId: _selectedShoeId,
            onShoeChanged: (id) => setState(() => _selectedShoeId = id),
            selectedLegendId: _selectedLegendId,
            onLegendChanged: (id) => setState(() => _selectedLegendId = id),
            isPro: _isPro,
            onLegendLocked: _showLegendLockedMessage,
            pacemakerEnabled: _pacemakerEnabled,
            onPacemakerToggled: (v) {
              SfxService().toggle();
              setState(() => _pacemakerEnabled = v);
            },
            pacemakerSecPerKm: _pacemakerSecPerKm,
            onPacemakerPaceChanged: (v) =>
                setState(() => _pacemakerSecPerKm = v),
            onStart: _startCountdown,
            onBack: () => context.pop(),
            countdownActive: _countdownActive,
            countdownValue: _countdownValue,
          );
        }
        if (themeId == ThemeId.pureCinematic) {
          if (_loading) {
            return const Scaffold(
              backgroundColor: Color(0xFF000000),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF8B0000)),
              ),
            );
          }
          return PurePrepareLayout(
            isChallenge: _isChallenge,
            gpsReady: _gpsReady,
            tooFarFromStart: _tooFarFromStart,
            canStart: _canStart,
            selectedQuote: _selectedQuote,
            selectedMode: _selectedMode,
            onModeChanged: (m) {
              SfxService().toggle();
              setState(() => _selectedMode = m);
            },
            shadowRun: _shadowRun,
            shadowLocationType: _shadowLocationType,
            onShadowLocationChanged: (t) {
              SfxService().toggle();
              setState(() => _shadowLocationType = t);
            },
            shoes: _shoes,
            selectedShoeId: _selectedShoeId,
            onShoeChanged: (id) => setState(() => _selectedShoeId = id),
            selectedLegendId: _selectedLegendId,
            onLegendChanged: (id) => setState(() => _selectedLegendId = id),
            isPro: _isPro,
            onLegendLocked: _showLegendLockedMessage,
            pacemakerEnabled: _pacemakerEnabled,
            onPacemakerToggled: (v) {
              SfxService().toggle();
              setState(() => _pacemakerEnabled = v);
            },
            pacemakerSecPerKm: _pacemakerSecPerKm,
            onPacemakerPaceChanged: (v) =>
                setState(() => _pacemakerSecPerKm = v),
            onStart: _startCountdown,
            onBack: () => context.pop(),
            countdownActive: _countdownActive,
            countdownValue: _countdownValue,
          );
        }
        return _buildDefaultLayout(context);
      },
    );
  }

  Widget _buildDefaultLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: SRColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: SRColors.primaryContainer))
                : Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 40),
                              _buildModeCard(),
                              if (_isChallenge && _shadowRun != null) ...[
                                const SizedBox(height: 16),
                                _buildShadowStats(),
                                const SizedBox(height: 16),
                                _buildLocationSelector(),
                                if (_shadowLocationType == 'same') ...[
                                  const SizedBox(height: 16),
                                  _buildMiniMap(),
                                ],
                              ],
                              if (!_isChallenge) ...[
                                const SizedBox(height: 16),
                                _buildRunModeSelector(),
                                if (_selectedMode == 'marathon') ...[
                                  const SizedBox(height: 20),
                                  _buildLegendSelector(),
                                ],
                                if (_selectedMode == 'freerun') ...[
                                  const SizedBox(height: 20),
                                  _buildPacemakerSection(),
                                ],
                              ],
                              _buildShoeSelector(),
                              const SizedBox(height: 28),
                              _buildGpsIndicator(),
                              if (_tooFarFromStart && _shadowLocationType == 'same') ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: SRColors.primaryContainer.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: SRColors.primaryContainer.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_off, color: SRColors.primaryContainer, size: 18),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(S.tooFarFromStart, style: GoogleFonts.inter(
                                          fontSize: 12, color: SRColors.primaryContainer,
                                        )),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                      _buildStartButton(),
                    ],
                  ),
          ),
          if (_countdownActive) _buildCountdownOverlay(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: SRColors.primary, size: 22),
          ),
        ],
      ),
    );
  }

  // Stitch: p-8 (32), bg-[#1c1b1b], rounded-xl (12), title text-3xl (32px)
  Widget _buildModeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1B1B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          // Icon (Stitch: w-16 h-16 rounded-full)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isChallenge ? SRColors.primaryContainer : const Color(0xFF2AA192))
                  .withValues(alpha: 0.2),
            ),
            child: Icon(
              _isChallenge ? Icons.people_alt_rounded : Icons.directions_run_rounded,
              color: _isChallenge ? SRColors.primaryContainer : SRColors.safe,
              size: 32,
            ),
          ),
          const SizedBox(height: 24),
          // Title (Stitch: text-3xl font-bold = 32px)
          Text(
            _isChallenge ? S.shadowChallenge : S.newRun,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: SRColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Subtitle (Stitch: text-sm, max-w-[200px], leading-relaxed)
          SizedBox(
            width: 200,
            child: Text(
              _selectedQuote,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: SRColors.onSurfaceVariant.withValues(alpha: 0.6),
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowStats() {
    final run = _shadowRun!;
    final date = DateTime.tryParse(run.date);
    final dateStr = date != null
        ? '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}'
        : run.date;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SRColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SRColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: SRColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                S.shadowRunStats,
                style: SRTheme.labelMedium.copyWith(
                  color: SRColors.primaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statItem(S.distance, run.formattedDistance),
              _statDivider(),
              _statItem(S.pace, run.formattedPace),
              _statDivider(),
              _statItem(S.date, dateStr),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: SRTheme.statNumber.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: SRTheme.labelMedium.copyWith(
              color: SRColors.textMuted,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() {
    return Container(
      width: 1,
      height: 32,
      color: SRColors.divider,
    );
  }

  Widget _buildMiniMap() {
    if (_shadowPoints == null || _shadowPoints!.isEmpty) {
      return const SizedBox.shrink();
    }

    final points = _shadowPoints!;
    final centerLat =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final centerLng =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    return GestureDetector(
      onTap: () => _showFullscreenMap(),
      child: Container(
        height: 200,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SRColors.divider),
        ),
        child: Stack(
          children: [
            NaverMap(
            options: NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: NLatLng(centerLat, centerLng),
                zoom: 15,
              ),
              mapType: NMapType.basic,
              nightModeEnable: false,
              scrollGesturesEnable: false,
              zoomGesturesEnable: false,
              rotationGesturesEnable: false,
              tiltGesturesEnable: false,
              liteModeEnable: true,
            ),
            onMapReady: (controller) {
              final coords =
                  points.map((p) => NLatLng(p.latitude, p.longitude)).toList();
              if (coords.length >= 2) {
                controller.addOverlay(NPathOverlay(
                  id: 'shadow_route',
                  coords: coords,
                  color: const Color(0xFFFF5262),
                  outlineColor: const Color(0x66FF5262),
                  width: 4,
                ));
                final bounds = NLatLngBounds.from(coords);
                controller.updateCamera(
                  NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(40)),
                );
              }
            },
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: SRColors.background.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: SRColors.background.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fullscreen, color: SRColors.onSurface, size: 18),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showFullscreenMap() {
    if (_shadowPoints == null || _shadowPoints!.isEmpty) return;
    final points = _shadowPoints!;
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (ctx) => Scaffold(
        backgroundColor: SRColors.background,
        appBar: AppBar(
          backgroundColor: SRColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: SRColors.onSurface),
            onPressed: () => Navigator.pop(ctx),
          ),
          title: Text(
            S.shadowRoute,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SRColors.onSurface,
            ),
          ),
        ),
        body: NaverMap(
          options: const NaverMapViewOptions(
            mapType: NMapType.navi,
            nightModeEnable: true,
            scrollGesturesEnable: true,
            zoomGesturesEnable: true,
            rotationGesturesEnable: true,
            tiltGesturesEnable: false,
          ),
          onMapReady: (controller) {
            final coords = points
                .map((p) => NLatLng(p.latitude, p.longitude))
                .toList();
            if (coords.length >= 2) {
              controller.addOverlay(NPathOverlay(
                id: 'shadow_route',
                coords: coords,
                color: const Color(0xFFFF5262),
                outlineColor: const Color(0x66FF5262),
                width: 5,
              ));
              final bounds = NLatLngBounds.from(coords);
              controller.updateCamera(
                NCameraUpdate.fitBounds(bounds, padding: const EdgeInsets.all(50)),
              );
              controller.addOverlay(NMarker(
                id: 'start',
                position: coords.first,
                iconTintColor: const Color(0xFFFF5262),
                size: const Size(20, 20),
              ));
              controller.addOverlay(NMarker(
                id: 'end',
                position: coords.last,
                iconTintColor: SRColors.onSurface,
                size: const Size(20, 20),
              ));
            }
          },
        ),
      ),
    );
  }

  Widget _buildGpsIndicator() {
    return _ShadowAnimatedBuilder(
      listenable: _pulseAnim,
      builder: (context, child) {
        final opacity = _gpsReady ? 1.0 : 0.4 + _pulseAnim.value * 0.6;
        final color = _gpsReady ? SRColors.runner : SRColors.warning;
        return Opacity(
          opacity: opacity,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  _gpsReady ? S.gpsSignalGood : S.searching,
                  style: SRTheme.labelLarge.copyWith(
                    color: color,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            gradient: LinearGradient(
              colors: _canStart
                  ? [SRColors.primary, SRColors.primaryContainer]
                  : [
                      SRColors.primary.withValues(alpha: 0.3),
                      SRColors.primaryContainer.withValues(alpha: 0.3),
                    ],
            ),
            boxShadow: _canStart
                ? [
                    BoxShadow(
                      color: SRColors.primaryContainer.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: MaterialButton(
            onPressed: _canStart ? _startCountdown : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              S.start,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _canStart ? Colors.white : Colors.white38,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.runLocation,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SRColors.neutral500,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        _locationOption(
          'same',
          S.sameLocation,
          S.sameLocationDesc,
          Icons.place_rounded,
        ),
        const SizedBox(height: 8),
        _locationOption(
          'different',
          S.differentLocation,
          S.differentLocationDesc,
          Icons.headphones_rounded,
        ),
      ],
    );
  }

  Widget _locationOption(String type, String title, String desc, IconData icon) {
    final selected = _shadowLocationType == type;
    return GestureDetector(
      onTap: () {
        SfxService().toggle();
        setState(() => _shadowLocationType = type);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? SRColors.primaryContainer.withValues(alpha: 0.1)
              : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? SRColors.primaryContainer.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? SRColors.primaryContainer.withValues(alpha: 0.2)
                    : SRColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? SRColors.primaryContainer : SRColors.neutral500,
                  size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? SRColors.onSurface : SRColors.onSurface.withValues(alpha: 0.6),
                  )),
                  const SizedBox(height: 2),
                  Text(desc, style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SRColors.neutral500,
                  )),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: SRColors.primaryContainer, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildRunModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.selectRunMode,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SRColors.neutral500,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        _modeOption(
          'marathon',
          S.modeMarathoner,
          S.modeMarathonerDesc,
          Icons.emoji_events_rounded,
        ),
        const SizedBox(height: 8),
        _modeOption(
          'freerun',
          S.modeFreeRun,
          S.modeFreeRunDesc,
          Icons.directions_run_rounded,
        ),
      ],
    );
  }

  Widget _modeOption(String mode, String title, String desc, IconData icon) {
    final selected = _selectedMode == mode;
    return GestureDetector(
      onTap: () {
        SfxService().toggle();
        setState(() => _selectedMode = mode);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? SRColors.primaryContainer.withValues(alpha: 0.1)
              : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? SRColors.primaryContainer.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.05),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? SRColors.primaryContainer.withValues(alpha: 0.2)
                    : SRColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  color: selected ? SRColors.primaryContainer : SRColors.neutral500,
                  size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: selected ? SRColors.onSurface : SRColors.onSurface.withValues(alpha: 0.6),
                  )),
                  const SizedBox(height: 2),
                  Text(desc, style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SRColors.neutral500,
                  )),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: SRColors.primaryContainer, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.isKo ? '전설과 함께 뛰기' : 'CHASE A LEGEND',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: SRColors.neutral500,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: LegendRunners.all.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final legend = LegendRunners.all[index];
              return _legendCard(legend);
            },
          ),
        ),
      ],
    );
  }

  Widget _legendCard(LegendRunner legend) {
    final selected = _selectedLegendId == legend.id;
    final locked = legend.isProOnly && !_isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          SfxService().toggle();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.isKo
                  ? '${legend.displayName}는 PRO 전용입니다.'
                  : '${legend.displayName} is PRO only.'),
              backgroundColor: SRColors.primaryContainer,
            ),
          );
          return;
        }
        SfxService().toggle();
        setState(() => _selectedLegendId = legend.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? SRColors.primaryContainer.withValues(alpha: 0.12)
              : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? SRColors.primaryContainer.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.05),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: SRColors.primaryContainer.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(legend.flag, style: const TextStyle(fontSize: 34)),
                const Spacer(),
                if (locked)
                  const Icon(Icons.lock_rounded, size: 16, color: Colors.amber)
                else if (selected)
                  Icon(Icons.check_circle,
                      size: 18, color: SRColors.primaryContainer),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              legend.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: selected
                    ? SRColors.onSurface
                    : SRColors.onSurface.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${legend.recordLabel} · ${legend.paceLabel}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? SRColors.primaryContainer
                    : SRColors.neutral500,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                legend.bio,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  height: 1.35,
                  color: SRColors.neutral500.withValues(alpha: 0.85),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPaceSec(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"/km";
  }

  Widget _buildPacemakerSection() {
    final title = S.isKo ? '페이스 메이커' : 'Pacemaker';
    final desc = S.isKo
        ? '유령이 이 페이스로 뛰어요. 앞서/뒤처지면 알려줘요.'
        : 'A ghost paces with you and tells you when you drift.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SRColors.neutral500,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            Switch(
              value: _pacemakerEnabled,
              activeThumbColor: SRColors.primaryContainer,
              onChanged: (v) {
                SfxService().toggle();
                setState(() => _pacemakerEnabled = v);
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: SRColors.neutral500,
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: _pacemakerEnabled ? 1.0 : 0.4,
          child: IgnorePointer(
            ignoring: !_pacemakerEnabled,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _pacemakerEnabled
                      ? SRColors.primaryContainer.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('👻', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        _formatPaceSec(_pacemakerSecPerKm),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: SRColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Slider(
                    min: 270, // 4:30
                    max: 480, // 8:00
                    divisions: 14, // 30초 스텝
                    value: _pacemakerSecPerKm.toDouble(),
                    activeColor: SRColors.primaryContainer,
                    onChanged: (v) {
                      setState(() => _pacemakerSecPerKm = v.round());
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("4'30\"",
                          style: GoogleFonts.inter(
                              fontSize: 11, color: SRColors.neutral500)),
                      Text("8'00\"",
                          style: GoogleFonts.inter(
                              fontSize: 11, color: SRColors.neutral500)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShoeSelector() {
    if (_shoes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              S.selectShoe,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: SRColors.neutral500,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              S.noSelection,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: SRColors.neutral500.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _shoes.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final shoe = _shoes[index];
              final shoeId = shoe['id'] as int;
              final name = shoe['name'] as String? ?? '러닝화';
              final totalM = (shoe['total_distance_m'] as num?)?.toDouble() ?? 0;
              final maxM = (shoe['max_distance_m'] as num?)?.toDouble() ?? 0;
              final totalKm = totalM / 1000;
              final isSelected = _selectedShoeId == shoeId;
              final isNearMax = maxM > 0 && (totalM / maxM) > 0.9;

              final accentColor = isNearMax ? SRColors.warning : SRColors.primaryContainer;

              return GestureDetector(
                onTap: () {
                  SfxService().toggle();
                  setState(() {
                    _selectedShoeId = isSelected ? null : shoeId;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.15)
                        : const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? accentColor.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isNearMax)
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Icon(Icons.warning_amber_rounded,
                              size: 13, color: SRColors.warning),
                        ),
                      Text(
                        '$name · ${totalKm.toStringAsFixed(0)}km',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected
                              ? accentColor
                              : SRColors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownOverlay() {
    return _ShadowAnimatedBuilder(
      listenable: _countdownScale,
      builder: (context, child) {
        final label = _countdownValue > 0 ? '$_countdownValue' : 'GO';
        final color =
            _countdownValue > 0 ? SRColors.textPrimary : SRColors.runner;
        return Container(
          color: SRColors.background,
          child: Center(
            child: Transform.scale(
              scale: _countdownScale.value,
              child: Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 120,
                  fontWeight: FontWeight.w700,
                  color: color,
                  shadows: [
                    Shadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 60,
                    ),
                    Shadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 120,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ShadowAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const _ShadowAnimatedBuilder({
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}
