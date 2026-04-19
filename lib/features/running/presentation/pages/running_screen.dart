import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/services/running_service.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/services/home_bgm_service.dart';
import 'package:shadowrun/core/services/horror_service.dart';
import 'package:shadowrun/core/services/marathon_service.dart';
import 'package:shadowrun/core/services/solo_tts_service.dart';
import 'package:shadowrun/core/services/tts_line_bank.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/shared/models/run_model.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/shared/widgets/stick_figure_marker.dart';
import 'package:shadowrun/core/services/watch_connector_service.dart';
import 'package:shadowrun/core/services/health_service.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/features/running/presentation/layouts/mystic_running_layout.dart';
import 'package:shadowrun/features/running/presentation/layouts/pure_running_layout.dart';
import 'package:shadowrun/features/running/data/legend_runners.dart';

class RunningScreen extends StatefulWidget {
  final int? shadowRunId;
  final String runMode; // 'doppelganger', 'marathon', 'freerun'
  final bool sameLocation; // 도플갱어: 같은 장소 vs 다른 장소
  final int? shoeId;
  final String? legendId; // marathon 모드일 때 선택한 전설 러너 id
  final int? pacemakerPaceSec; // freerun + pacer 활성 시 목표 페이스(초/km)

  const RunningScreen({super.key, this.shadowRunId, this.runMode = 'freerun', this.sameLocation = true, this.shoeId, this.legendId, this.pacemakerPaceSec});

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
  final _watchConnector = WatchConnectorService();
  final _healthService = HealthService();
  int _lastMarathonKm = 0;
  bool _stadiumFinaleEnabled = false;
  late bool _isSameLocation;
  NaverMapController? _mapController;
  NLatLng? _initialPosition; // GPS 기반 초기 카메라 위치

  Timer? _ticker;
  Timer? _jumpscareDelayTimer;
  bool _paused = false;
  bool _stopping = false;
  bool _startupCancelled = false;
  bool _runStarted = false; // _runService.startRun() 성공 후 true. startup 중 워치 명령 방어용.
  bool _ttsOn = true;
  bool _sfxOn = true;
  String _runMode = 'fullmap';
  late AnimationController _vignetteAnim;
  late AnimationController _shadowPingAnim;

  // Jumpscare
  late AnimationController _jumpscareFlashAnim;
  late AnimationController _jumpscareShakeAnim;
  bool _jumpscareTriggered = false;

  // 차량 감지 자동 일시정지
  int _vehicleDetectCount = 0;
  int _lastAddedKmMarker = 0; // 이미 추가된 km 마커 추적
  bool _isUpdatingHorror = false; // GPS 콜백 TTS 중첩 방지
  // 마라톤 TTS 공용 lock — km 마일스톤(GPS 콜백)과 시간 기반(1s Timer)이 서로 drop하지 않도록
  // 하나로 통일. 한 쪽이 실행 중이면 다른 쪽은 다음 tick에 재시도.
  bool _isUpdatingMarathon = false;
  int _lastPathPointCount = 0; // 경로 재생성 최적화

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
    _wireTtsLineBank();
    _loadRunMode();
    // 러닝 화면 진입 — 홈/메뉴 BGM 정지 (러닝 BGM은 MarathonService/HorrorService가 담당)
    HomeBgmService.I.stop();

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

    _healthService.reset();
    _watchConnector.onWatchCommand = _handleWatchCommand;
    // ignore: unawaited_futures
    _watchConnector.startListening();
    () async {
      final granted = await _healthService.requestAuthorization();
      // mounted 는 super.dispose() 전까지 true이므로 _startupCancelled 로 dispose 중 판별.
      if (!mounted || _stopping || _startupCancelled) return;
      if (granted) {
        await _healthService.startHeartRateStream();
      }
    }();
    _startRun();
    _createMarkerIcons();
  }

  Future<void> _createMarkerIcons() async {
    // Load profile face image if exists
    File? faceFile;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_face.png');
      if (await file.exists()) {
        faceFile = file;
      }
    } catch (_) {}

    if (!mounted) return;
    _runnerArrowIcon = await NOverlayImage.fromWidget(
      widget: StickFigureMarker(faceImage: faceFile, size: 64),
      size: const Size(64, 64),
      context: context,
    );
    if (!mounted) return;
    _shadowArrowIcon = await NOverlayImage.fromWidget(
      widget: StickFigureMarker(faceImage: faceFile, isDoppelganger: true, size: 56),
      size: const Size(56, 56),
      context: context,
    );
    if (!mounted) return;

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
    if (!mounted) return;
  }

  Future<void> _loadRunMode() async {
    final mode = await DatabaseHelper.getSetting('run_mode');
    if (mode != null && mounted) {
      setState(() => _runMode = mode);
    }
  }

  bool _aborted() => _startupCancelled || _stopping || !mounted;

  Future<void> _fetchInitialPosition() async {
    // 백그라운드로 초기 카메라 위치 획득. 실패해도 run 시작을 막지 않음.
    // live GPS 첫 샘플이 _onRunUpdate에서 backfill 하므로 여기 실패는 치명적이지 않음.
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 10));
      if (_aborted() || _initialPosition != null) return;
      setState(() {
        _initialPosition = NLatLng(pos.latitude, pos.longitude);
      });
    } catch (_) {}
  }

  Future<void> _startRun() async {
    try {
      // 화면 꺼짐 방지
      WakelockPlus.enable();

      // 초기 위치는 백그라운드로 획득 (기록 시작을 블로킹하지 않음).
      // ignore: unawaited_futures
      _fetchInitialPosition();

      final voice = await DatabaseHelper.getSetting('voice') ?? 'harry';
      if (_aborted()) return;
      final speedStr = await DatabaseHelper.getSetting('shadow_speed') ?? '1.0';
      if (_aborted()) return;
      final shadowSpeed = double.tryParse(speedStr) ?? 1.0;
      final stadiumSetting = await DatabaseHelper.getSetting('stadium_finale');
      if (_aborted()) return;
      _stadiumFinaleEnabled = stadiumSetting != 'false';
      final horrorStr = await DatabaseHelper.getSetting('horror_level') ?? '2';
      if (_aborted()) return;
      final horrorLevel = int.tryParse(horrorStr) ?? 2;
      final ttsEnabled = (await DatabaseHelper.getSetting('tts_enabled')) != 'false';
      if (_aborted()) return;
      final vibEnabled = (await DatabaseHelper.getSetting('vibration_enabled')) != 'false';
      if (_aborted()) return;
      await _horrorService.initialize(
        voice: voice,
        horrorLevel: horrorLevel,
        ttsEnabled: ttsEnabled,
        vibrationEnabled: vibEnabled,
      );
      if (_aborted()) return;

      // 오디오 토글 초기값 (설정에서 읽어옴)
      setState(() {
        _ttsOn = ttsEnabled;
        _sfxOn = true;
      });

      // 모드별 서비스 초기화
      if (widget.runMode == 'marathon') {
        _marathonService = MarathonService();
        final legend = widget.legendId != null
            ? LegendRunners.byId(widget.legendId!)
            : null;
        await _marathonService!.initialize(
          voice: voice,
          legend: legend,
          vibrationEnabled: vibEnabled,
        );
        if (_aborted()) return;
      } else if (widget.runMode == 'freerun') {
        _soloTtsService = SoloTtsService();
        await _soloTtsService!.initialize(voice: voice);
        if (_aborted()) return;
        // 페이스메이커 유령(선택) — MarathonService의 legend 트래커 재활용.
        // legend만 주입하면 페이스 차이 TTS/햅틱이 자동 동작.
        if (widget.pacemakerPaceSec != null) {
          final paceSec = widget.pacemakerPaceSec!;
          final pacer = LegendRunner(
            id: 'pacemaker',
            nameKo: '페이스메이커',
            nameEn: 'Pacemaker',
            flag: '👻',
            marathonTime: Duration(seconds: (42.195 * paceSec).round()),
            paceSecPerKm: paceSec.toDouble(),
            bioKo: '당신의 목표 페이스',
            bioEn: 'Your target pace',
          );
          _marathonService = MarathonService();
          await _marathonService!.initialize(
            voice: voice,
            legend: pacer,
            vibrationEnabled: vibEnabled,
          );
          if (_aborted()) return;
        }
      }

      // 마라토너 모드에서는 flutter_tts km 스플릿 비활성화 (MarathonService가 처리)
      if (widget.runMode == 'marathon') {
        _runService.kmSplitTtsEnabled = false;
      }

      final ok = await _runService.startRun(
        shadowRunId: widget.shadowRunId,
        shadowSpeedMultiplier: shadowSpeed,
      );
      // startup 중 dispose된 경우 GPS 스트림을 즉시 cancel (누수 방지).
      // ChangeNotifier dispose() 자체는 widget dispose()에서 한 번만.
      if (_aborted()) {
        // ignore: unawaited_futures
        _runService.abortStartup();
        return;
      }
      if (!ok) {
        WakelockPlus.disable();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.gpsRequired)),
        );
        context.pop();
        return;
      }
      _runStarted = true;
      // startup 완료 — 현재 UI 상태를 실제 서비스에 반영.
      SfxService().enabled = _sfxOn;
      _syncAudioState();

      // 모드별 시작 TTS
      if (_ttsOn) {
        if (widget.runMode == 'doppelganger') {
          await _horrorService.playStartTts();
        } else if (widget.runMode == 'marathon') {
          await _marathonService?.playStartTts();
        } else {
          await _soloTtsService?.playStartTts();
        }
        if (_aborted()) return;
      }

      // GPS 콜백: 백그라운드에서도 동작 (Timer 대신)
      _runService.onPositionUpdate = () {
        if (_aborted()) return;
        _runService.updateShadowPosition();
        // live GPS 첫 샘플에서 초기 카메라 위치 backfill (one-shot 위치 획득 실패 대비)
        if (_initialPosition == null) {
          final pos = _runService.currentPosition;
          if (pos != null) {
            setState(() {
              _initialPosition = NLatLng(pos.latitude, pos.longitude);
            });
          }
        }
        _checkVehicleSpeed();
        if (!_paused) {
          if (widget.runMode == 'doppelganger') {
            _updateHorror();
          } else if (widget.runMode == 'marathon') {
            _updateMarathon();
          }
        }
      };

      // Timer: UI 갱신 + 지도 + 시간 기반 마라톤 TTS (GPS 멈춰도 동작).
      // km 마일스톤은 GPS 콜백에서만 처리 (거리 정확도 필요).
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_aborted()) return;
        if (!_paused) {
          _runService.updateShadowPosition();
          setState(() {});
          _updateMap();
          _sendDataToWatch();
          if (widget.runMode == 'marathon' && _ttsOn) {
            _updateMarathonTime();
            // Legend(전설) 트래커 — legendId가 있을 때만 내부에서 동작.
            // ignore: unawaited_futures
            _marathonService?.updateProgress(
              elapsedSeconds: _runService.durationS,
              userDistanceKm: _runService.totalDistanceM / 1000.0,
            );
          } else if (widget.runMode == 'freerun' &&
              widget.pacemakerPaceSec != null &&
              _ttsOn) {
            // 페이스메이커 유령 — legend 트래커가 페이스 차이 TTS/햅틱 담당.
            // ignore: unawaited_futures
            _marathonService?.updateProgress(
              elapsedSeconds: _runService.durationS,
              userDistanceKm: _runService.totalDistanceM / 1000.0,
            );
          }
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

  /// TtsLineBank 훅 — marathon/freerun 에서만 사용.
  /// doppelganger 는 horror_service 가 TTS 전담 (중복 방지).
  void _wireTtsLineBank() {
    if (widget.runMode == 'doppelganger') return;
    final mode = widget.runMode; // 'marathon' or 'freerun'
    _runService.onMilestoneKm = (km) {
      if (!_ttsOn) return;
      String? cat;
      if (km == 1) {
        cat = 'milestone_1k';
      } else if (km == 5) {
        cat = 'milestone_5k';
      }
      if (cat == null) return;
      TtsLineBank.I.play(mode: mode, category: cat);
    };
    _runService.onPaceCategory = (cat) {
      if (!_ttsOn) return;
      TtsLineBank.I.play(mode: mode, category: cat);
    };
  }

  void _handleWatchCommand(String command, Map<String, dynamic> data) {
    if (!mounted || _stopping) return;
    // startup 완료 전에는 상태 변경 명령을 무시 (stop/heartRate는 허용).
    // 이후 _runService.startRun()이 UI 상태를 리셋하며 덮어쓰는 경합 방지.
    if (!_runStarted && command != 'stop' && command != 'heartRate') return;
    try {
      switch (command) {
        case 'toggleTts':
          setState(() => _ttsOn = !_ttsOn);
          _horrorService.ttsEnabled = _ttsOn;
          break;
        case 'toggleSfx':
          setState(() => _sfxOn = !_sfxOn);
          SfxService().enabled = _sfxOn;
          _syncAudioState();
          break;
        case 'pause':
          if (!_paused) {
            _vehiclePaused = false;
            _setPaused(true);
          }
          break;
        case 'resume':
          if (_paused) {
            _vehiclePaused = false;
            _setPaused(false);
          }
          break;
        case 'stop':
          _confirmStop();
          break;
        case 'heartRate':
          final raw = data['heartRate'];
          // 0도 전달 — dropout 의미. HealthService 내부에서 유효 범위 검증.
          final hr = raw is num ? raw.toInt() : int.tryParse('$raw');
          if (hr != null) _healthService.updateHeartRate(hr);
          break;
      }
    } catch (e) {
      debugPrint('watch command error: $e');
    }
  }

  /// BGM 상태를 현재 _sfxOn/_paused/_stopping 에 맞춰 동기화.
  /// paused 중이거나 sfx off면 mute, 그 외엔 unmute.
  void _syncAudioState() {
    final shouldBgmPlay = _sfxOn && !_paused && !_stopping;
    if (shouldBgmPlay) {
      _horrorService.unmuteBgm();
      _marathonService?.unmuteBgm();
      _soloTtsService?.unmuteBgm();
    } else {
      _horrorService.muteBgm();
      _marathonService?.muteBgm();
      _soloTtsService?.muteBgm();
    }
  }

  void _sendDataToWatch() {
    final pos = _runService.currentPosition;
    final shadowPoint = _runService.currentShadowPoint;
    _watchConnector.sendRunData(
      runState: _paused ? 'paused' : 'running',
      distanceM: _runService.totalDistanceM,
      durationS: _runService.durationS,
      avgPace: _runService.totalDistanceM > 0
          ? (_runService.durationS / 60) / (_runService.totalDistanceM / 1000)
          : 0,
      calories: _runService.calories,
      // HR 0도 전달 — 워치가 "현재 측정값 없음"을 표시하도록.
      heartRate: _healthService.currentHeartRate,
      threatLevel: _horrorService.currentLevel.name,
      shadowDistanceM: _runService.shadowDistanceM,
      threatPercent: _getThreatPercent(),
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      shadowLatitude: shadowPoint?.latitude,
      shadowLongitude: shadowPoint?.longitude,
      runMode: widget.runMode,
      ttsOn: _ttsOn,
      sfxOn: _sfxOn,
    );
  }

  double _getThreatPercent() {
    switch (_horrorService.currentLevel) {
      case ThreatLevel.aheadFar: return 0.0;
      case ThreatLevel.aheadMid: return 0.05;
      case ThreatLevel.aheadClose: return 0.10;
      case ThreatLevel.safe: return 0.25;
      case ThreatLevel.warningFar: return 0.45;
      case ThreatLevel.warningClose: return 0.60;
      case ThreatLevel.dangerFar: return 0.75;
      case ThreatLevel.dangerClose: return 0.90;
      case ThreatLevel.critical: return 1.0;
    }
  }

  bool _vehiclePaused = false; // 차량 감지로 일시정지된 상태

  void _checkVehicleSpeed() {
    if (_runService.speedWarning == S.tooFast) {
      _vehicleDetectCount++;
      if (_vehicleDetectCount >= 3 && !_paused) {
        _vehiclePaused = true;
        SfxService().vehicleWarn();
        _setPaused(true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.vehiclePaused),
              backgroundColor: SRColors.primaryContainer,
            ),
          );
        }
      }
    } else {
      _vehicleDetectCount = 0;
      // 차량 감지로 일시정지된 상태에서만 자동 재개. 수동 pause는 건드리지 않음.
      if (_vehiclePaused && _paused) {
        _vehiclePaused = false;
        _setPaused(false);
      }
    }
  }

  Future<void> _updateHorror() async {
    if (widget.shadowRunId == null || _isUpdatingHorror) return;
    _isUpdatingHorror = true;
    try {
      final dist = _runService.shadowDistanceM;
      if (!dist.isInfinite) {
        await _horrorService.updateThreat(dist);
        // dispose/stop 사이 race 방지: 애니메이션/서비스 접근 전 재확인
        if (!mounted || _stopping) return;
        if (_horrorService.currentLevel == ThreatLevel.critical &&
            !_jumpscareTriggered &&
            _runService.durationS > 5) {
          _triggerJumpscare();
        }
      }
    } finally {
      _isUpdatingHorror = false;
    }
  }

  double? _previousKmPace; // 이전 km 페이스 추적
  final Set<int> _kmSfxPlayed = {}; // km별 SFX(kmDing/whistle) 중복 방지

  /// km 마일스톤 전용 업데이트 (GPS 콜백에서만 호출). 거리 정확도가 필요.
  /// TTS가 drop되면 _lastMarathonKm가 올라가지 않아 다음 tick에서 재시도됨.
  Future<void> _updateMarathon() async {
    if (_marathonService == null || _isUpdatingMarathon) return;
    final currentKm = (_runService.totalDistanceM / 1000).floor();
    if (currentKm <= _lastMarathonKm) return;
    _isUpdatingMarathon = true;
    try {
      // SFX 중복 방지 (TTS drop 재시도 시 한 번만 울리도록)
      if (_kmSfxPlayed.add(currentKm)) {
        SfxService().kmDing();
        SfxService().whistle();
      }
      bool kmOk = true;
      if (_ttsOn) {
        kmOk = await _marathonService!.playKmTts(currentKm);
        if (!mounted || _stopping) return;
        if (!kmOk) {
          // TTS drop — 다음 tick 재시도 (SFX는 이미 울렸으니 한 번만).
          // _lastMarathonKm 증가를 막고 즉시 return.
          return;
        }
      }
      // 페이스 피드백 (2km부터)
      if (_ttsOn && currentKm >= 2 && !_paused) {
        final avgHistorical = await DatabaseHelper.getAveragePace();
        if (!mounted || _stopping || _paused || !_ttsOn) return;
        await _marathonService!.playPaceTts(
          _runService.avgPace,
          avgHistorical,
          _previousKmPace,
        );
        if (!mounted || _stopping) return;
      }
      _previousKmPace = _runService.avgPace;
      _lastMarathonKm = currentKm; // km TTS 성공 확인 후에만 기록
    } finally {
      _isUpdatingMarathon = false;
    }
  }

  /// 시간 기반 마라톤 TTS (1초 Timer에서만 호출). GPS 안 잡혀도 동작해야 함.
  /// km TTS와 같은 lock을 공유 — 한 쪽 실행 중이면 skip, 다음 tick에 재시도.
  Future<void> _updateMarathonTime() async {
    if (_marathonService == null || _isUpdatingMarathon) return;
    _isUpdatingMarathon = true;
    try {
      final elapsed = _runService.durationS;
      await _marathonService!.playTimeTts(elapsed);
      if (!mounted || _stopping || _paused || !_ttsOn) return;
      await _marathonService!.playEncourageTts(elapsed);
      if (!mounted || _stopping || _paused || !_ttsOn) return;
      await _marathonService!.playRandomTts(elapsed);
    } finally {
      _isUpdatingMarathon = false;
    }
  }

  void _triggerJumpscare() {
    if (!mounted || _stopping) return;
    _jumpscareTriggered = true;
    _jumpscareFlashAnim.repeat(reverse: true);
    _jumpscareShakeAnim.repeat();
    setState(() {});
    // 1.5초 후 결과 화면으로 자동 이동 (dispose 시 취소)
    _jumpscareDelayTimer?.cancel();
    _jumpscareDelayTimer = Timer(const Duration(milliseconds: 1500), () {
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

  void _updateMapOverlays(NaverMapController controller, NLatLng target) {
    controller.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: target),
    );

    final currentPointCount = _runService.points.length;
    final pathChanged = currentPointCount != _lastPathPointCount;

    // 마커/글로우는 매번 업데이트 (위치 변경), 경로는 새 포인트가 추가됐을 때만
    _safeDeleteOverlay(controller, NOverlayType.marker, 'runner');
    _safeDeleteOverlay(controller, NOverlayType.marker, 'shadow');
    _safeDeleteOverlay(controller, NOverlayType.circleOverlay, 'runner_glow');
    _safeDeleteOverlay(controller, NOverlayType.circleOverlay, 'shadow_glow');
    if (pathChanged) {
      _safeDeleteOverlay(controller, NOverlayType.pathOverlay, 'runner_path');
      _safeDeleteOverlay(controller, NOverlayType.pathOverlay, 'shadow_path');
      _lastPathPointCount = currentPointCount;
    }

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
      size: const Size(64, 64),
      angle: _runService.heading,
    );
    if (_runnerArrowIcon != null) {
      runnerMarker.setIcon(_runnerArrowIcon!);
    } else {
      runnerMarker.setIconTintColor(SRColors.runner);
    }
    _safeAddOverlay(controller, runnerMarker);

    // Runner path polyline (새 포인트 추가 시에만 재생성)
    if (pathChanged) {
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
        size: const Size(56, 56),
      );
      if (_shadowArrowIcon != null) {
        shadowMarker.setIcon(_shadowArrowIcon!);
      } else {
        shadowMarker.setIconTintColor(SRColors.shadow);
      }
      _safeAddOverlay(controller, shadowMarker);
    }

    // Shadow path polyline (같은 장소일 때, 새 포인트 추가 시에만)
    if (pathChanged) {
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
  }

  void _addKmSplitMarkers(NaverMapController controller, List<RunPoint> points) {
    if (points.length < 2 || _kmSplitIcon == null) return;
    // 이미 추가된 마커는 건너뛰기
    if (_lastAddedKmMarker >= (_runService.totalDistanceM / 1000).floor()) return;
    double dist = 0;
    int nextKm = 1;
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      dist += Geolocator.distanceBetween(
        p0.latitude, p0.longitude, p1.latitude, p1.longitude,
      );
      if (dist >= nextKm * 1000) {
        if (nextKm > _lastAddedKmMarker) {
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
          _safeAddOverlay(controller, marker);
          _lastAddedKmMarker = nextKm;
        }
        nextKm++;
      }
    }
  }

  void _togglePause() {
    // 수동 토글: 차량 자동 재개 플래그 해제 (이후 vehicle loop이 내 상태를 덮지 않도록).
    _vehiclePaused = false;
    _setPaused(!_paused);
  }

  /// pause/resume 공용 경로. 수동 버튼, 워치 명령, 차량 자동 감지 모두 여기로 모인다.
  void _setPaused(bool pause) {
    if (pause == _paused || _stopping) return;
    setState(() {
      _paused = pause;
      if (_paused) {
        SfxService().pause();
        _runService.pauseRun();
      } else {
        SfxService().resume();
        _runService.resumeRun();
      }
    });
    _syncAudioState();
    // 워치에 일시정지/재개 상태 즉시 전송
    _sendDataToWatch();
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

    // Watch 명령 즉시 차단 — stop 처리 중 toggleTts/pause 등 들어와 dispose된 서비스 접근 방지
    _watchConnector.onWatchCommand = null;

    // GPS 콜백 즉시 해제 (dispose된 서비스 접근 방지)
    _runService.onPositionUpdate = null;

    // 종료 흐름에서 BGM 뮤트 (end TTS/stadium finale와 겹치지 않도록).
    _syncAudioState();

    // 웨이크락 해제
    WakelockPlus.disable();

    RunModel? result;
    bool hadError = false;
    try {
      // 먼저 결과 저장 (앱 킬링 대비)
      result = await _runService.stopRun();

      // 선택된 러닝화에 거리 기록
      if (widget.shoeId != null && result != null && result.distanceM > 0) {
        await DatabaseHelper.addShoeDistance(widget.shoeId!, result.distanceM);
      }

      // 종료 SFX
      SfxService().doorClose();

      // 스타디움 피날레 (종료 직전 관중 함성) — 2초만 재생 후 TTS로 넘어감
      if (_stadiumFinaleEnabled && !_jumpscareTriggered && _sfxOn) {
        try {
          await _stadiumPlayer.setAsset('assets/audio/stadium_finale.mp3');
          _stadiumPlayer.setVolume(0.8);
          // ignore: unawaited_futures
          _stadiumPlayer.play().catchError((_) {});
          await Future.delayed(const Duration(seconds: 2));
        } catch (_) {}
      }

      // 모드별 종료 SFX + TTS (스타디움 완료 후)
      if (widget.runMode == 'doppelganger' && result != null) {
        if (result.challengeResult == 'win') {
          SfxService().victory();
          await _horrorService.playSurvivedTts();
        } else if (result.challengeResult == 'lose') {
          SfxService().defeat();
          await _horrorService.playDefeatedTts();
        }
      } else if (widget.runMode == 'marathon' && _ttsOn) {
        await _marathonService?.playEndTts();
      } else if (widget.runMode == 'freerun' && _ttsOn) {
        await _soloTtsService?.playEndTts();
      }
    } catch (e) {
      debugPrint('stopRun 에러: $e');
      hadError = true;
    } finally {
      _horrorService.dispose();
      _marathonService?.dispose();
      _soloTtsService?.dispose();
    }

    // 워치에 종료 상태 전송 — 결과 있으면 result, 없으면 idle.
    // (결과 없이 나가면 워치가 이전 running/paused 화면에 멈춰 있음)
    if (result != null) {
      _watchConnector.sendResult(
        distanceM: result.distanceM,
        durationS: result.durationS,
        avgPace: result.avgPace,
        calories: result.calories,
        challengeResult: result.challengeResult,
      );
    } else {
      _watchConnector.sendIdle();
    }
    _healthService.reset();

    if (mounted) {
      if (result != null && result.id != null) {
        context.go('/result', extra: {
          'runId': result.id!,
          'result': result.challengeResult,
        });
      } else {
        if (!hadError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.runTooShort)),
          );
        }
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    // 진행 중이던 _startRun 체인 중단 신호
    _startupCancelled = true;
    // 워치 연동 해제 + 콜백 끊기 (지연된 워치 이벤트가 dead State에 도달하지 못하도록)
    _watchConnector.onWatchCommand = null;
    _watchConnector.stopListening();
    _healthService.stopHeartRateStream();
    _healthService.reset();
    // SFX 토글 상태 리셋 (글로벌 싱글톤이라 복원 필요)
    SfxService().enabled = true;
    WakelockPlus.disable();
    _ticker?.cancel();
    _jumpscareDelayTimer?.cancel();
    _runService.onPositionUpdate = null;
    _runService.onMilestoneKm = null;
    _runService.onPaceCategory = null;
    _runService.removeListener(_onRunUpdate);
    _runService.dispose();
    _horrorService.dispose();
    _marathonService?.dispose();
    _soloTtsService?.dispose();
    _vignetteAnim.dispose();
    _shadowPingAnim.dispose();
    _jumpscareFlashAnim.dispose();
    _jumpscareShakeAnim.dispose();
    _stadiumPlayer.dispose();
    // 러닝 화면 종료 — 홈/메뉴 BGM 재개
    HomeBgmService.I.startForCurrentTheme();
    super.dispose();
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    // codex P2: _runMode(fullmap/mapcenter/datacenter)는 사용자 UX 선호.
    // 사용자가 map-center 또는 data-center를 저장했다면 테마와 관계없이 그 레이아웃을 우선.
    // 테마 레이아웃(Mystic/Pure)은 fullmap 모드일 때만 적용.
    if (_runMode != 'fullmap') {
      return _buildDefaultLayout();
    }
    return ValueListenableBuilder<ThemeId>(
      valueListenable: ThemeManager.I.themeIdNotifier,
      builder: (context, themeId, _) {
        if (themeId == ThemeId.koreanMystic) {
          return _buildMysticLayout();
        }
        if (themeId == ThemeId.pureCinematic) {
          return _buildPureLayout();
        }
        return _buildDefaultLayout();
      },
    );
  }

  /// T3 Korean Mystic 레이아웃. 내부 데이터/콜백만 주입하고 실시간 로직은 기존 그대로.
  Widget _buildMysticLayout() {
    // 미니맵 — 기존 네이버맵 빌더 재사용.
    final map = _buildNaverMap(onReady: (c) {
      _mapController = c;
      _lastAddedKmMarker = 0;
      _activeOverlayIds.clear();
    });
    final content = MysticRunningLayout(
      elapsedSeconds: _runService.durationS,
      distanceM: _runService.totalDistanceM,
      paceText: _runService.formattedPace,
      shadowGapM: _runService.shadowDistanceM,
      isPaused: _paused,
      onPauseTap: _togglePause,
      onStopTap: _confirmStop,
      isChallenge: widget.shadowRunId != null,
      mapChild: map,
      ttsOn: _ttsOn,
      sfxOn: _sfxOn,
      onToggleTts: () {
        setState(() => _ttsOn = !_ttsOn);
        _horrorService.ttsEnabled = _ttsOn;
      },
      onToggleSfx: () {
        setState(() => _sfxOn = !_sfxOn);
        SfxService().enabled = _sfxOn;
        _syncAudioState();
      },
    );
    return _applyJumpscareOverlays(content);
  }

  /// T1 Pure Cinematic 레이아웃. 내부 데이터/콜백만 주입.
  Widget _buildPureLayout() {
    final map = _buildNaverMap(onReady: (c) {
      _mapController = c;
      _lastAddedKmMarker = 0;
      _activeOverlayIds.clear();
    });
    final content = PureRunningLayout(
      elapsedSeconds: _runService.durationS,
      distanceM: _runService.totalDistanceM,
      paceText: _runService.formattedPace,
      shadowGapM: _runService.shadowDistanceM,
      isPaused: _paused,
      onPauseTap: _togglePause,
      onStopTap: _confirmStop,
      isChallenge: widget.shadowRunId != null,
      mapChild: map,
      ttsOn: _ttsOn,
      sfxOn: _sfxOn,
      onToggleTts: () {
        setState(() => _ttsOn = !_ttsOn);
        _horrorService.ttsEnabled = _ttsOn;
      },
      onToggleSfx: () {
        setState(() => _sfxOn = !_sfxOn);
        SfxService().enabled = _sfxOn;
        _syncAudioState();
      },
    );
    return _applyJumpscareOverlays(content);
  }

  /// 기본(T1 외 기존) 레이아웃.
  Widget _buildDefaultLayout() {
    Widget content = Scaffold(
      backgroundColor: SRColors.background,
      body: _runMode == 'mapcenter'
          ? _buildModeA()
          : _runMode == 'datacenter'
              ? _buildModeB()
              : _buildModeC(),
    );
    return _applyJumpscareOverlays(content);
  }

  /// 점프스케어 떨림/플래시 오버레이 + PopScope — 테마 공통.
  Widget _applyJumpscareOverlays(Widget content) {

    // 점프스케어 화면 떨림
    if (_jumpscareTriggered) {
      final shakeContent = content;
      content = _ShadowAnimatedBuilder(
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
            _ShadowAnimatedBuilder(
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
        _buildNaverMap(onReady: (c) {
                  _mapController = c;
                  _lastAddedKmMarker = 0;
                  _activeOverlayIds.clear();
                }),
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
        // 오디오 토글 버튼 (왼쪽 하단, 컨트롤 버튼 위)
        Positioned(
          left: 16,
          bottom: MediaQuery.of(context).padding.bottom + 110,
          child: _buildAudioControls(),
        ),
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
                  _buildNaverMap(onReady: (c) {
                  _mapController = c;
                  _lastAddedKmMarker = 0;
                  _activeOverlayIds.clear();
                }),
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
                    Row(
                      children: [
                        _buildAudioControls(),
                        const Spacer(),
                        _buildControlButtons(),
                        const Spacer(),
                        const SizedBox(width: 36 + 8),
                      ],
                    ),
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
                    child: _buildNaverMap(onReady: (c) {
                  _mapController = c;
                  _lastAddedKmMarker = 0;
                  _activeOverlayIds.clear();
                }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildAudioControls(),
                      const Spacer(),
                      _buildControlButtons(),
                      const Spacer(),
                      const SizedBox(width: 36 + 8),
                    ],
                  ),
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
    // GPS 잡히기 전엔 지도를 그리지 않음 (서울 기본 좌표 노출 방지).
    // NaverMap의 initialCameraPosition은 최초 생성 시점에만 적용되므로,
    // _initialPosition 을 얻은 후에야 지도를 build 해야 사용자 위치에서 시작한다.
    if (_initialPosition == null) {
      return Container(
        color: SRColors.background,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return NaverMap(
      options: NaverMapViewOptions(
        mapType: NMapType.navi,
        nightModeEnable: true,
        initialCameraPosition: NCameraPosition(
          target: _initialPosition!,
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
    return _ShadowAnimatedBuilder(
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
              _ShadowAnimatedBuilder(
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
      case ThreatLevel.warningFar:
        progress = 0.35;
        levelLabel = '35%';
      case ThreatLevel.warningClose:
        progress = 0.55;
        levelLabel = '55%';
      case ThreatLevel.dangerFar:
        progress = 0.75;
        levelLabel = '75%';
      case ThreatLevel.dangerClose:
        progress = 0.90;
        levelLabel = '90%';
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

  Widget _buildAudioControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TTS 토글
        GestureDetector(
          onTap: () {
            setState(() => _ttsOn = !_ttsOn);
            _horrorService.ttsEnabled = _ttsOn;
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _ttsOn
                  ? SRColors.surfaceContainerHighest
                  : SRColors.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: SRColors.divider),
            ),
            child: Icon(
              _ttsOn ? Icons.mic : Icons.mic_off,
              color: _ttsOn ? SRColors.textPrimary : SRColors.textMuted,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // SFX/BGM 토글
        GestureDetector(
          onTap: () {
            setState(() => _sfxOn = !_sfxOn);
            SfxService().enabled = _sfxOn;
            _syncAudioState();
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _sfxOn
                  ? SRColors.surfaceContainerHighest
                  : SRColors.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: SRColors.divider),
            ),
            child: Icon(
              _sfxOn ? Icons.volume_up : Icons.volume_off,
              color: _sfxOn ? SRColors.textPrimary : SRColors.textMuted,
              size: 16,
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

class _ShadowAnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;

  const _ShadowAnimatedBuilder({
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) => builder(context, null);
}
