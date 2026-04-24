import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/tts_coordinator.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';

/// 테마/모드/카테고리/언어 조건에 맞는 음성 라인을 뽑아 재생.
/// 파일명 규칙: assets/audio/voice/{voice}_{mode}_{category}_{lang}_v{n}.mp3
/// category 가 언더스코어를 포함해도 prefix startsWith 매칭이라 문제없다.
class TtsLineBank {
  static final TtsLineBank I = TtsLineBank._();
  TtsLineBank._();

  final AudioPlayer _player = AudioPlayer();
  final Map<String, List<String>> _recent = {};
  final Random _rng = Random();

  bool enabled = true;
  double volume = 0.9;

  bool _playing = false;
  bool _disposed = false;

  List<String>? _manifest;

  Future<void> _loadManifest() async {
    if (_manifest != null) return;
    try {
      final am = await AssetManifest.loadFromAssetBundle(rootBundle);
      _manifest = am
          .listAssets()
          .where((k) => k.startsWith('assets/audio/voice/') && k.endsWith('.mp3'))
          .toList();
    } catch (e) {
      debugPrint('TtsLineBank manifest load failed: $e');
      _manifest = const [];
    }
  }

  String _voiceForTheme() {
    final id = ThemeManager.I.currentId;
    if (id == ThemeId.koreanMystic) return 'halmeoni';
    if (id == ThemeId.pureCinematic) return 'harry';
    return 'callum';
  }

  Future<bool> play({
    required String mode,
    required String category,
    String? voice,
    String? lang,
  }) async {
    if (!enabled || _disposed) return false;
    // 동시 호출 직렬화 — setAsset race 방지 (마일스톤+페이스 콜백 중첩 등)
    if (_playing) return false;
    _playing = true;
    try {
      await _loadManifest();
      final v = voice ?? _voiceForTheme();
      final l = lang ?? (S.isKo ? 'ko' : 'en');
      final prefix = 'assets/audio/voice/${v}_${mode}_${category}_${l}_v';
      final candidates = _manifest!.where((p) => p.startsWith(prefix)).toList();
      if (candidates.isEmpty) return false;

      final key = prefix;
      final recent = _recent[key] ?? [];
      var pool = candidates.where((c) => !recent.contains(c)).toList();
      if (pool.isEmpty) pool = candidates;
      final pick = pool[_rng.nextInt(pool.length)];
      (_recent[key] ??= []).add(pick);
      while (_recent[key]!.length > 3) {
        _recent[key]!.removeAt(0);
      }
      try {
        TtsCoordinator.I.begin(() => _player.stop());
        await _player.stop();
        await _player.setAsset(pick);
        await _player.setVolume(volume);
        _player.play();
        return true;
      } catch (e) {
        debugPrint('TtsLineBank play error ($pick): $e');
        return false;
      }
    } finally {
      _playing = false;
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
