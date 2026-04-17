import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/services/bgm_preferences.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';

/// 홈 화면 BGM 재생 전담 싱글톤.
///
/// - HomeScreen.initState → [startForCurrentTheme]
/// - HomeScreen.dispose   → [stop]
///
/// 볼륨/on-off/외부음악 모드는 [BgmPreferences]를 따르고,
/// 재생 에셋은 [ThemeManager.I.current.bgmHomePool] 을 따른다.
/// 테마/사용자 설정이 바뀌면 실시간 반영.
class HomeBgmService {
  HomeBgmService._();
  static final HomeBgmService I = HomeBgmService._();

  final AudioPlayer _player = AudioPlayer();
  final Random _rng = Random();
  bool _active = false;
  String? _currentAsset;

  Future<void> startForCurrentTheme() async {
    if (_active) return;
    _active = true;

    BgmPreferences.I.volume.addListener(_onVolumeChanged);
    BgmPreferences.I.enabled.addListener(_onEnabledChanged);
    BgmPreferences.I.externalMusicMode.addListener(_onEnabledChanged);
    ThemeManager.I.themeIdNotifier.addListener(_onThemeChanged);

    await _playRandomFromPool();
  }

  Future<void> stop() async {
    _active = false;
    BgmPreferences.I.volume.removeListener(_onVolumeChanged);
    BgmPreferences.I.enabled.removeListener(_onEnabledChanged);
    BgmPreferences.I.externalMusicMode.removeListener(_onEnabledChanged);
    ThemeManager.I.themeIdNotifier.removeListener(_onThemeChanged);
    try { await _player.stop(); } catch (_) {}
    _currentAsset = null;
  }

  Future<void> _playRandomFromPool() async {
    final prefs = BgmPreferences.I;
    debugPrint('[HomeBgm] 재생 시도 — enabled=${prefs.enabled.value} externalMusic=${prefs.externalMusicMode.value} volume=${prefs.volume.value}');
    if (!prefs.enabled.value || prefs.externalMusicMode.value) {
      debugPrint('[HomeBgm] → skip (사용자 설정)');
      try { await _player.stop(); } catch (_) {}
      return;
    }
    final theme = ThemeManager.I.current;
    final pool = theme.bgmHomePool;
    debugPrint('[HomeBgm] theme=${theme.id.key} pool.length=${pool.length}');
    if (pool.isEmpty) {
      debugPrint('[HomeBgm] → skip (pool empty)');
      try { await _player.stop(); } catch (_) {}
      return;
    }
    final asset = pool[_rng.nextInt(pool.length)];
    if (_currentAsset == asset) {
      debugPrint('[HomeBgm] → same asset, skip restart');
      return;
    }
    _currentAsset = asset;
    try {
      debugPrint('[HomeBgm] setAsset(assets/audio/$asset)');
      await _player.setAsset('assets/audio/$asset');
      await _player.setLoopMode(LoopMode.one);
      final vol = prefs.effectiveVolume(0.75);
      await _player.setVolume(vol);
      debugPrint('[HomeBgm] play — volume=$vol');
      _player.play().catchError((_) {});
    } catch (e) {
      debugPrint('[HomeBgm] 에러 ($asset): $e');
    }
  }

  void _onVolumeChanged() {
    _player.setVolume(BgmPreferences.I.effectiveVolume(0.75));
  }

  void _onEnabledChanged() {
    final on = BgmPreferences.I.enabled.value && !BgmPreferences.I.externalMusicMode.value;
    if (on) {
      // 켜질 때 트랙 없으면 새로 선택
      if (_currentAsset == null) {
        _playRandomFromPool();
      } else {
        _player.play().catchError((_) {});
      }
    } else {
      _player.pause().catchError((_) {});
    }
  }

  Future<void> _onThemeChanged() async {
    // 테마가 바뀌면 pool이 달라지므로 새 트랙 선택.
    _currentAsset = null;
    await _player.stop();
    await _playRandomFromPool();
  }
}
