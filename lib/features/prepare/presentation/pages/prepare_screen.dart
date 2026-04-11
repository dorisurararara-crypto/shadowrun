import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

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
  RunModel? _shadowRun;
  List<RunPoint>? _shadowPoints;
  bool _loading = true;
  bool _countdownActive = false;
  int _countdownValue = 3;
  late AnimationController _countdownAnim;
  late Animation<double> _countdownScale;
  late AnimationController _pulseAnim;
  String _selectedQuote = '';

  bool get _isChallenge => widget.shadowRunId != null;

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
    _checkGps();
    _gpsTimer = Timer.periodic(const Duration(seconds: 2), (_) => _checkGps());
  }

  Future<void> _checkGps() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _gpsReady = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _gpsReady = false);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );
      if (mounted) {
        setState(() => _gpsReady = pos.accuracy < 30);
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
        context.go('/running', extra: widget.shadowRunId);
      }
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _countdownAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                _buildMiniMap(),
                              ],
                              const SizedBox(height: 28),
                              _buildGpsIndicator(),
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

  Widget _buildModeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: SRColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SRColors.divider),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (_isChallenge ? SRColors.primaryContainer : SRColors.runner)
                  .withValues(alpha: 0.15),
            ),
            child: Icon(
              _isChallenge ? Icons.people_alt_rounded : Icons.directions_run_rounded,
              color: _isChallenge ? SRColors.primaryContainer : SRColors.runner,
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          // Title
          Text(
            _isChallenge ? S.shadowChallenge : S.newRun,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: SRColors.textPrimary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          // Subtitle
          Text(
            _selectedQuote,
            style: SRTheme.bodyMedium.copyWith(
              color: SRColors.textMuted,
            ),
            textAlign: TextAlign.center,
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

    return Container(
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
        ],
      ),
    );
  }

  Widget _buildGpsIndicator() {
    return AnimatedBuilder(
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
              colors: _gpsReady
                  ? [SRColors.primary, SRColors.primaryContainer]
                  : [
                      SRColors.primary.withValues(alpha: 0.3),
                      SRColors.primaryContainer.withValues(alpha: 0.3),
                    ],
            ),
            boxShadow: _gpsReady
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
            onPressed: _gpsReady ? _startCountdown : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              S.start,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _gpsReady ? Colors.white : Colors.white38,
                letterSpacing: 6,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountdownOverlay() {
    return AnimatedBuilder(
      listenable: _countdownScale,
      builder: (context, child) {
        final label = _countdownValue > 0 ? '$_countdownValue' : 'GO';
        final color =
            _countdownValue > 0 ? SRColors.textPrimary : SRColors.runner;
        return Container(
          color: SRColors.background.withValues(alpha: 0.95),
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
