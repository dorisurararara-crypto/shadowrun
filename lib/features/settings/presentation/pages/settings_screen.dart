import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _runMode = 'fullmap';
  String _unit = 'km';
  int _horrorLevel = 2;
  bool _ttsEnabled = true;
  bool _vibrationEnabled = true;
  bool _isPro = false;
  String _selectedVoice = 'harry';
  bool _loading = true;
  final int _selectedNavIndex = 2;
  int _adminTapCount = 0;
  DateTime? _adminFirstTap;
  final AudioPlayer _previewPlayer = AudioPlayer();
  String? _playingPreview;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      DatabaseHelper.getSetting('run_mode'),
      DatabaseHelper.getSetting('unit'),
      DatabaseHelper.getSetting('horror_level'),
      DatabaseHelper.getSetting('tts_enabled'),
      DatabaseHelper.getSetting('vibration_enabled'),
      DatabaseHelper.getSetting('is_pro'),
      DatabaseHelper.getSetting('voice'),
    ]);

    setState(() {
      _runMode = results[0] ?? 'fullmap';
      _unit = results[1] ?? 'km';
      _horrorLevel = int.tryParse(results[2] ?? '2') ?? 2;
      _ttsEnabled = results[3] != 'false';
      _vibrationEnabled = results[4] != 'false';
      _isPro = results[5] == 'true';
      _selectedVoice = results[6] ?? 'harry';
      _loading = false;
    });
  }

  Future<void> _save(String key, String value) async {
    await DatabaseHelper.setSetting(key, value);
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
          onPressed: () => context.pop(),
        ),
        title: Text(
          S.settings,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: SRColors.primary,
            letterSpacing: 1,
          ),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: SRColors.primaryContainer,
                strokeWidth: 2,
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              children: [
                _buildRunningSettings(),
                const SizedBox(height: 24),
                _buildHorrorSettings(),
                const SizedBox(height: 24),
                if (_isPro) _buildProSection(),
                if (_isPro) const SizedBox(height: 24),
                _buildProUpgrade(),
                if (!_isPro) _buildRestorePurchases(),
                const SizedBox(height: 16),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: SRColors.primary.withValues(alpha: 0.6),
          letterSpacing: 3,
        ),
      ),
    );
  }

  // --- Running Settings ---
  Widget _buildRunningSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(S.runningSettings),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.runMode,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SRColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 10),
              _buildRunModeSelector(),
              const SizedBox(height: 24),
              Text(
                S.distanceUnits,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SRColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 10),
              _buildSegmentedControl(
                options: const ['km', 'mi'],
                labels: const ['km', 'mi'],
                selected: _unit,
                onChanged: (value) {
                  setState(() => _unit = value);
                  _save('unit', value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRunModeSelector() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SRColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _runModeOption('fullmap', S.fullMap, false),
          _runModeOption('mapcenter', S.mapFocus, true),
          _runModeOption('datacenter', S.dataFocus, true),
        ],
      ),
    );
  }

  Widget _runModeOption(String value, String label, bool requiresPro) {
    final isSelected = _runMode == value;
    final isLocked = requiresPro && !_isPro;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (isLocked) {
            _showProLockDialog(
              title: S.proModeLockedTitle,
              message: S.proModeLockedMsg,
            );
            return;
          }
          setState(() => _runMode = value);
          _save('run_mode', value);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF0044) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : isLocked
                            ? SRColors.onSurface.withValues(alpha: 0.25)
                            : SRColors.onSurface.withValues(alpha: 0.4),
                    letterSpacing: 0.5,
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.lock, size: 10, color: SRColors.onSurface.withValues(alpha: 0.2)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentedControl({
    required List<String> options,
    required List<String> labels,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: SRColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = options[i] == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(options[i]),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF0044) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : SRColors.onSurface.withValues(alpha: 0.4),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Horror Settings ---
  Widget _buildHorrorSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _onHorrorHeaderTap,
          child: _sectionHeader(S.horrorSettings),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Anxiety Level
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.anxietyLevel,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: SRColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  Text(
                    _horrorLevel.toString().padLeft(2, '0'),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFF0044),
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFFFF0044),
                  inactiveTrackColor: SRColors.background,
                  thumbColor: const Color(0xFFFF0044),
                  overlayColor: const Color(0xFFFF0044).withValues(alpha: 0.15),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _horrorLevel.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) {
                    final level = value.round();
                    if (!_isPro && level > 2) {
                      setState(() => _horrorLevel = 2);
                      _save('horror_level', '2');
                      _showProLockDialog(
                        title: 'PRO LOCKED',
                        message: S.isKo
                            ? '공포 레벨 3~5는 PRO 전용입니다.\n업그레이드하여 궁극의 공포를 경험하세요.'
                            : 'Anxiety levels 3-5 require PRO.\nUpgrade to experience ultimate terror.',
                      );
                      return;
                    }
                    setState(() => _horrorLevel = level);
                    _save('horror_level', '$level');
                  },
                ),
              ),
              // Level labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(5, (i) {
                    final level = i + 1;
                    final locked = !_isPro && level > 2;
                    final isActive = level == _horrorLevel;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$level',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive
                                ? const Color(0xFFFF0044)
                                : SRColors.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                        if (locked) ...[
                          const SizedBox(width: 2),
                          Icon(Icons.lock, size: 10, color: SRColors.onSurface.withValues(alpha: 0.2)),
                          Padding(
                            padding: const EdgeInsets.only(left: 2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: SRColors.proBadge.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                'PRO',
                                style: GoogleFonts.inter(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: SRColors.proBadge,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              // Entity Audio toggle
              _SettingsToggle(
                label: S.entityAudio,
                subtitle: S.entityAudioDesc,
                value: _ttsEnabled,
                onChanged: (v) {
                  setState(() => _ttsEnabled = v);
                  _save('tts_enabled', '$v');
                },
              ),
              const SizedBox(height: 8),
              // Haptic Dread toggle
              _SettingsToggle(
                label: S.hapticDread,
                subtitle: S.hapticDreadDesc,
                value: _vibrationEnabled,
                onChanged: (v) {
                  setState(() => _vibrationEnabled = v);
                  _save('vibration_enabled', '$v');
                },
              ),
              // Voice selection (PRO only)
              if (_isPro) ...[
                const SizedBox(height: 20),
                Container(height: 0.5, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 16),
                Text(
                  S.voiceSelection,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SRColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                _buildVoiceOption('harry', S.voiceHarry, true),
                _buildVoiceOption('callum', S.voiceCallum, true),
                _buildVoiceOption('drill', S.voiceDrill, true),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _playPreview(String voiceId) async {
    try {
      if (_playingPreview == voiceId) {
        await _previewPlayer.stop();
        setState(() => _playingPreview = null);
        return;
      }
      setState(() => _playingPreview = voiceId);
      await _previewPlayer.setAsset('assets/audio/preview/preview_danger_$voiceId.mp3');
      _previewPlayer.play();
      _previewPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _playingPreview = null);
        }
      });
    } catch (e) {
      setState(() => _playingPreview = null);
    }
  }

  Widget _buildVoiceOption(String id, String label, bool available) {
    final isSelected = _selectedVoice == id;
    final isPlaying = _playingPreview == id;
    return GestureDetector(
      onTap: available
          ? () {
              setState(() => _selectedVoice = id);
              _save('voice', id);
            }
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFF0044).withValues(alpha: 0.1)
              : SRColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFF0044).withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF0044) : SRColors.onSurface.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF0044),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: available
                      ? SRColors.onSurface
                      : SRColors.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ),
            // 미리듣기 버튼
            GestureDetector(
              onTap: () => _playPreview(id),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isPlaying
                      ? const Color(0xFFFF0044).withValues(alpha: 0.2)
                      : SRColors.onSurface.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 18,
                  color: isPlaying
                      ? const Color(0xFFFF0044)
                      : SRColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PRO Section (when activated) ---
  Widget _buildProSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('PRO'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: SRColors.safe.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SRColors.safe.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: SRColors.safe, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    S.proActivated,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: SRColors.safe,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _proBenefitRow(Icons.block, S.proBenefitNoAds),
              _proBenefitRow(Icons.psychology, S.proBenefitHorror),
              _proBenefitRow(Icons.map, S.proBenefitModes),
              _proBenefitRow(Icons.record_voice_over, S.proBenefitVoice),
            ],
          ),
        ),
      ],
    );
  }

  Widget _proBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: SRColors.safe.withValues(alpha: 0.6)),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: SRColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  // --- PRO Upgrade ---
  Widget _buildProUpgrade() {
    if (_isPro) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF0044).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                final success = await PurchaseService().buyPro();
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('스토어에 연결할 수 없습니다. 앱 출시 후 이용 가능합니다.'),
                      backgroundColor: SRColors.surface,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0044),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    S.upgradeToPro,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    S.unlockUltimateTerror,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.6),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // PRO benefits preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: SRColors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                _proBenefitPreviewRow(Icons.block, S.proBenefitNoAds),
                _proBenefitPreviewRow(Icons.psychology, S.proBenefitHorror),
                _proBenefitPreviewRow(Icons.map, S.proBenefitModes),
                _proBenefitPreviewRow(Icons.record_voice_over, S.proBenefitVoice),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _proBenefitPreviewRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: SRColors.proBadge.withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: SRColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestorePurchases() {
    return Center(
      child: TextButton(
        onPressed: () async {
          await PurchaseService().restorePurchases();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('구매 복원을 시도합니다...'),
                backgroundColor: SRColors.surface,
              ),
            );
          }
        },
        child: Text(
          S.restorePurchases,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: SRColors.onSurface.withValues(alpha: 0.3),
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  // --- Bottom Nav ---
  Widget _buildBottomNav() {
    return Container(
      color: SRColors.surface,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
        top: 8,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavIcon(
            icon: Icons.directions_run,
            isActive: _selectedNavIndex == 0,
            onTap: () => context.go('/'),
          ),
          _NavIcon(
            icon: Icons.monitor_heart_outlined,
            isActive: _selectedNavIndex == 1,
            onTap: () => context.go('/history'),
          ),
          _NavIcon(
            icon: Icons.settings_outlined,
            isActive: _selectedNavIndex == 2,
            onTap: () {},
          ),
          _NavIcon(
            icon: Icons.analytics_outlined,
            isActive: _selectedNavIndex == 3,
            onTap: () => context.go('/analysis'),
          ),
        ],
      ),
    );
  }

  void _onHorrorHeaderTap() {
    final now = DateTime.now();
    if (_adminFirstTap == null || now.difference(_adminFirstTap!).inSeconds > 10) {
      _adminTapCount = 1;
      _adminFirstTap = now;
    } else {
      _adminTapCount++;
    }
    if (_adminTapCount >= 5) {
      _adminTapCount = 0;
      _adminFirstTap = null;
      _showAdminKeyDialog();
    }
  }

  void _showAdminKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SRColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '관리자 키를 입력하세요',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: SRColors.onSurface,
          ),
        ),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: GoogleFonts.inter(color: SRColors.onSurface),
          decoration: InputDecoration(
            hintText: 'Admin Key',
            hintStyle: GoogleFonts.inter(color: SRColors.onSurface.withValues(alpha: 0.3)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: SRColors.onSurface.withValues(alpha: 0.2)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: SRColors.primaryContainer),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SRColors.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              if (controller.text == 'ganzinam95') {
                await PurchaseService().activatePro();
                setState(() => _isPro = true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PRO 활성화 완료!'),
                      backgroundColor: SRColors.surface,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('잘못된 키입니다'),
                      backgroundColor: SRColors.surface,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0044),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              'OK',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      _adminTapCount = 0;
      _adminFirstTap = null;
    });
  }

  void _showProLockDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SRColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.lock, color: SRColors.proBadge, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SRColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: GoogleFonts.inter(
                color: SRColors.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _proBenefitPreviewRow(Icons.block, S.proBenefitNoAds),
            _proBenefitPreviewRow(Icons.psychology, S.proBenefitHorror),
            _proBenefitPreviewRow(Icons.map, S.proBenefitModes),
            _proBenefitPreviewRow(Icons.record_voice_over, S.proBenefitVoice),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              S.cancel.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SRColors.onSurface.withValues(alpha: 0.4),
                letterSpacing: 1,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              PurchaseService().buyPro();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0044),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              S.upgrade,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsToggle({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SRColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SRColors.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF0044),
            activeTrackColor: const Color(0xFFFF0044).withValues(alpha: 0.3),
            inactiveThumbColor: SRColors.onSurface.withValues(alpha: 0.3),
            inactiveTrackColor: SRColors.background,
          ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIcon({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive
              ? SRColors.primaryContainer.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isActive
              ? SRColors.primaryContainer
              : SRColors.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
