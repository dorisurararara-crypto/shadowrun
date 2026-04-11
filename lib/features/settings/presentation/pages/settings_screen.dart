import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _loading = true;
  final int _selectedNavIndex = 2; // settings active
  int _adminTapCount = 0;
  DateTime? _adminFirstTap;

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
    ]);

    setState(() {
      _runMode = results[0] ?? 'fullmap';
      _unit = results[1] ?? 'km';
      _horrorLevel = int.tryParse(results[2] ?? '2') ?? 2;
      _ttsEnabled = results[3] != 'false';
      _vibrationEnabled = results[4] != 'false';
      _isPro = results[5] == 'true';
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
                _buildProUpgrade(),
                if (!_isPro) _buildRestorePurchases(),
                const SizedBox(height: 16),
              ],
            ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- Section header ---
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
              // Run Mode label
              Text(
                S.runMode,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SRColors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 10),
              // Segmented control
              _buildSegmentedControl(
                options: const ['fullmap', 'mapcenter', 'datacenter'],
                labels: [S.fullMap, S.mapFocus, S.dataFocus],
                selected: _runMode,
                onChanged: (value) {
                  setState(() => _runMode = value);
                  _save('run_mode', value);
                },
              ),
              const SizedBox(height: 24),
              // Distance Units label
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
              // Anxiety Level row
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
              // Slider
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
                      _showProLockDialog();
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
                        ],
                        if (locked)
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
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              // Entity Audio (TTS) toggle
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
            ],
          ),
        ),
      ],
    );
  }

  // --- PRO Upgrade ---
  Widget _buildProUpgrade() {
    if (_isPro) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: SRColors.safe.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Text(
            S.proActivated,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: SRColors.safe,
              letterSpacing: 3,
            ),
          ),
        ),
      );
    }

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
      child: SizedBox(
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
            icon: Icons.shield_outlined,
            isActive: _selectedNavIndex == 3,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    S.isKo ? '곧 출시됩니다!' : 'Coming soon!',
                    style: GoogleFonts.inter(),
                  ),
                  backgroundColor: SRColors.surface,
                  duration: const Duration(seconds: 1),
                ),
              );
            },
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
                await DatabaseHelper.setSetting('is_pro', 'true');
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

  void _showProLockDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: SRColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.lock, color: SRColors.proBadge, size: 20),
            const SizedBox(width: 8),
            Text(
              'PRO LOCKED',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: SRColors.onSurface,
              ),
            ),
          ],
        ),
        content: Text(
          'Anxiety levels 3-5 require PRO.\nUpgrade to experience ultimate terror.',
          style: GoogleFonts.inter(
            color: SRColors.onSurface.withValues(alpha: 0.6),
            height: 1.5,
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
            onPressed: () {
              Navigator.pop(ctx);
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
              'UPGRADE',
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
