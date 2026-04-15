import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/shared/models/run_model.dart';

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
  bool _stadiumFinale = true;
  bool _isPro = false;
  String _selectedVoice = 'harry';
  double _shadowSpeed = 1.0;
  bool _loading = true;
  final int _selectedNavIndex = 2;
  int _adminTapCount = 0;
  DateTime? _adminFirstTap;
  final AudioPlayer _previewPlayer = AudioPlayer();
  StreamSubscription? _previewSub;
  String? _playingPreview;

  // Shoe & Goal state
  List<Map<String, dynamic>> _shoes = [];
  Map<String, dynamic>? _activeGoal;

  // Profile face
  bool _hasProfileFace = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadShoes();
    _loadGoal();
    _loadProfileFace();
    PurchaseService().proNotifier.addListener(_onProChanged);
  }

  void _onProChanged() {
    if (mounted) setState(() => _isPro = PurchaseService().isPro);
  }

  @override
  void dispose() {
    PurchaseService().proNotifier.removeListener(_onProChanged);
    _previewSub?.cancel();
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final results = await Future.wait([
      DatabaseHelper.getSetting('run_mode'),
      DatabaseHelper.getSetting('unit'),
      DatabaseHelper.getSetting('horror_level'),
      DatabaseHelper.getSetting('tts_enabled'),
      DatabaseHelper.getSetting('is_pro'),
      DatabaseHelper.getSetting('voice'),
      DatabaseHelper.getSetting('shadow_speed'),
      DatabaseHelper.getSetting('stadium_finale'),
    ]);

    setState(() {
      _runMode = results[0] ?? 'fullmap';
      _unit = results[1] ?? 'km';
      _horrorLevel = int.tryParse(results[2] ?? '2') ?? 2;
      _ttsEnabled = results[3] != 'false';
      _isPro = results[4] == 'true';
      _selectedVoice = results[5] ?? 'harry';
      _shadowSpeed = double.tryParse(results[6] ?? '1.0') ?? 1.0;
      _stadiumFinale = results[7] != 'false';
      _loading = false;
    });
  }

  Future<void> _save(String key, String value) async {
    await DatabaseHelper.setSetting(key, value);
  }

  Future<void> _loadProfileFace() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/profile_face.png');
      final exists = await file.exists();
      if (mounted) setState(() => _hasProfileFace = exists);
    } catch (_) {}
  }

  Future<void> _captureProfileFace() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 300,
      maxHeight: 300,
      imageQuality: 85,
    );
    if (photo == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final savedFile = File('${dir.path}/profile_face.png');
    await File(photo.path).copy(savedFile.path);
    await DatabaseHelper.setSetting('has_profile_face', 'true');

    if (mounted) {
      setState(() => _hasProfileFace = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.profileSavedMsg)),
      );
    }
  }

  Future<void> _loadShoes() async {
    final shoes = await DatabaseHelper.getAllShoes();
    if (mounted) setState(() => _shoes = shoes);
  }

  Future<void> _loadGoal() async {
    final goal = await DatabaseHelper.getActiveGoal();
    if (mounted) setState(() => _activeGoal = goal);
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
          onPressed: () { SfxService().tapCard(); context.pop(); },
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
              children: [
                _buildLanguageSettings(),
                const SizedBox(height: 24),
                _buildProfileSettings(),
                const SizedBox(height: 24),
                _buildRunningSettings(),
                const SizedBox(height: 24),
                _buildShoeSettings(),
                const SizedBox(height: 24),
                _buildGoalSettings(),
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

  // --- Language ---
  Widget _buildLanguageSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(S.isKo ? '언어' : 'LANGUAGE'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
          ),
          child: _buildSegmentedControl(
            options: const ['ko', 'en'],
            labels: const ['한국어', 'English'],
            selected: S.isKo ? 'ko' : 'en',
            onChanged: (value) async {
              SfxService().toggle();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('language', value);
              await S.init(value);
            },
          ),
        ),
      ],
    );
  }

  // --- Profile Settings ---
  Widget _buildProfileSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(S.isKo ? '프로필' : 'PROFILE'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              if (_hasProfileFace)
                FutureBuilder<Directory>(
                  future: getApplicationDocumentsDirectory(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SRColors.background,
                        ),
                      );
                    }
                    final file = File('${snapshot.data!.path}/profile_face.png');
                    return Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: SRColors.primaryContainer.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        image: DecorationImage(
                          image: FileImage(file),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SRColors.background,
                    border: Border.all(
                      color: SRColors.onSurface.withValues(alpha: 0.1),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 22,
                    color: SRColors.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.isKo ? '프로필 사진 설정' : 'Set Profile Photo',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: SRColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.isKo
                          ? _hasProfileFace
                              ? '지도 마커에 내 얼굴 졸라맨이 표시됩니다'
                              : '셀카를 찍으면 지도 마커가 졸라맨으로 바뀝니다'
                          : _hasProfileFace
                              ? 'Your face stick figure appears on the map'
                              : 'Take a selfie to customize your map marker',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: SRColors.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _captureProfileFace,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: SRColors.primaryContainer.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: SRColors.primaryContainer.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _hasProfileFace ? Icons.camera_alt : Icons.camera_alt_outlined,
                        size: 14,
                        color: SRColors.primaryContainer,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _hasProfileFace
                            ? (S.isKo ? '변경' : 'Change')
                            : (S.isKo ? '촬영' : 'Shoot'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: SRColors.primaryContainer,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                  SfxService().toggle();
                  setState(() => _unit = value);
                  _save('unit', value);
                  RunModel.setUnit(value);
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
          SfxService().toggle();
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

  // --- Shoe Settings ---
  Widget _buildShoeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(S.shoeManagement),
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
              if (_shoes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    S.noShoesRegistered,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: SRColors.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                )
              else
                ...(_shoes.map((shoe) => _buildShoeItem(shoe))),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showAddShoeDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(
                    S.addNewShoe,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SRColors.primaryContainer,
                    side: BorderSide(
                      color: SRColors.primaryContainer.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShoeItem(Map<String, dynamic> shoe) {
    final isActive = (shoe['is_active'] as int? ?? 1) == 1;
    final totalM = (shoe['total_distance_m'] as num? ?? 0).toDouble();
    final maxM = (shoe['max_distance_m'] as num? ?? 800000).toDouble();
    final totalKm = totalM / 1000.0;
    final maxKm = maxM / 1000.0;
    final ratio = maxM > 0 ? (totalM / maxM).clamp(0.0, 1.0) : 0.0;

    Color progressColor;
    if (ratio < 0.7) {
      progressColor = const Color(0xFF4CAF50);
    } else if (ratio < 0.9) {
      progressColor = const Color(0xFFFFB300);
    } else {
      progressColor = const Color(0xFFFF0044);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shoe['name'] as String? ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? SRColors.onSurface
                            : SRColors.onSurface.withValues(alpha: 0.35),
                        decoration: isActive ? null : TextDecoration.lineThrough,
                        decorationColor: SRColors.onSurface.withValues(alpha: 0.35),
                      ),
                    ),
                    if ((shoe['brand'] as String?)?.isNotEmpty == true)
                      Text(
                        shoe['brand'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: SRColors.onSurface.withValues(alpha: isActive ? 0.4 : 0.2),
                        ),
                      ),
                  ],
                ),
              ),
              if (isActive)
                GestureDetector(
                  onTap: () async {
                    final id = shoe['id'] as int;
                    await DatabaseHelper.retireShoe(id);
                    _loadShoes();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: SRColors.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      S.shoeRetire,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: SRColors.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: SRColors.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    S.shoeRetired,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: SRColors.onSurface.withValues(alpha: 0.2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: SRColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(
                isActive ? progressColor : progressColor.withValues(alpha: 0.3),
              ),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${totalKm.toStringAsFixed(1)}km / ${maxKm.toStringAsFixed(0)}km',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: SRColors.onSurface.withValues(alpha: isActive ? 0.45 : 0.25),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddShoeDialog() {
    final nameController = TextEditingController();
    final brandController = TextEditingController();
    double maxKm = 800;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: SRColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            S.addNewShoe,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SRColors.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                style: GoogleFonts.inter(color: SRColors.onSurface),
                decoration: InputDecoration(
                  labelText: S.shoeName,
                  labelStyle: GoogleFonts.inter(
                    color: SRColors.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: SRColors.onSurface.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: SRColors.primaryContainer),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: brandController,
                style: GoogleFonts.inter(color: SRColors.onSurface),
                decoration: InputDecoration(
                  labelText: S.shoeBrand,
                  labelStyle: GoogleFonts.inter(
                    color: SRColors.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: SRColors.onSurface.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: SRColors.primaryContainer),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                S.shoeMaxDistance,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: SRColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                initialValue: maxKm,
                dropdownColor: SRColors.surface,
                style: GoogleFonts.inter(color: SRColors.onSurface, fontSize: 13),
                decoration: InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: SRColors.onSurface.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: SRColors.primaryContainer),
                  ),
                  suffixText: 'km',
                  suffixStyle: GoogleFonts.inter(
                    color: SRColors.onSurface.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                ),
                items: [500, 600, 700, 800, 900, 1000].map((v) {
                  return DropdownMenuItem<double>(
                    value: v.toDouble(),
                    child: Text('$v'),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => maxKm = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                S.cancel,
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
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final brand = brandController.text.trim();
                await DatabaseHelper.insertShoe(
                  name,
                  brand.isEmpty ? null : brand,
                  maxKm * 1000,
                );
                if (ctx.mounted) Navigator.pop(ctx);
                _loadShoes();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SRColors.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                S.add,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      nameController.dispose();
      brandController.dispose();
    });
  }

  // --- Goal Settings ---
  Widget _buildGoalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(S.goalSettings),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: SRColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: _activeGoal != null
              ? _buildActiveGoalView()
              : _buildNoGoalView(),
        ),
      ],
    );
  }

  Widget _buildActiveGoalView() {
    final goal = _activeGoal!;
    final type = goal['type'] as String? ?? 'distance';
    final period = goal['period'] as String? ?? 'weekly';
    final target = (goal['target_value'] as num? ?? 0).toDouble();
    final typeLabel = type == 'distance' ? S.goalTypeDistance : S.goalTypeCount;
    final periodLabel = period == 'weekly' ? S.goalPeriodWeekly : S.goalPeriodMonthly;
    final unit = type == 'distance' ? 'km' : (S.isKo ? '회' : 'runs');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              type == 'distance' ? Icons.straighten : Icons.repeat,
              size: 18,
              color: SRColors.primaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$periodLabel $typeLabel 목표',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SRColors.onSurface,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _showGoalDialog(existing: _activeGoal),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: SRColors.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: SRColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final id = goal['id'] as int;
                await DatabaseHelper.deleteGoal(id);
                _loadGoal();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF0044).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: Color(0xFFFF0044),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: SRColors.primaryContainer.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: SRColors.primaryContainer.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Text(
                type == 'distance'
                    ? target.toStringAsFixed(0)
                    : target.toInt().toString(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: SRColors.primaryContainer,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: SRColors.primaryContainer.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoGoalView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.goalNone,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: SRColors.onSurface.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showGoalDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              S.goalAdd,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: SRColors.primaryContainer,
              side: BorderSide(
                color: SRColors.primaryContainer.withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showGoalDialog({Map<String, dynamic>? existing}) {
    String selectedType = existing?['type'] as String? ?? 'distance';
    String selectedPeriod = existing?['period'] as String? ?? 'weekly';
    final targetController = TextEditingController(
      text: existing != null
          ? (existing['target_value'] as num).toStringAsFixed(
              selectedType == 'distance' ? 0 : 0)
          : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: SRColors.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            existing != null ? S.goalEdit : S.goalSet,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: SRColors.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.goalType,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: SRColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _dialogRadioOption(
                    label: S.goalTypeDistance,
                    value: 'distance',
                    groupValue: selectedType,
                    onChanged: (v) {
                      setDialogState(() => selectedType = v!);
                      targetController.clear();
                    },
                  ),
                  const SizedBox(width: 20),
                  _dialogRadioOption(
                    label: S.goalTypeCount,
                    value: 'count',
                    groupValue: selectedType,
                    onChanged: (v) {
                      setDialogState(() => selectedType = v!);
                      targetController.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                S.goalPeriod,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: SRColors.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _dialogRadioOption(
                    label: S.goalPeriodWeekly,
                    value: 'weekly',
                    groupValue: selectedPeriod,
                    onChanged: (v) => setDialogState(() => selectedPeriod = v!),
                  ),
                  const SizedBox(width: 20),
                  _dialogRadioOption(
                    label: S.goalPeriodMonthly,
                    value: 'monthly',
                    groupValue: selectedPeriod,
                    onChanged: (v) => setDialogState(() => selectedPeriod = v!),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: GoogleFonts.inter(color: SRColors.onSurface),
                decoration: InputDecoration(
                  labelText: S.goalValue,
                  labelStyle: GoogleFonts.inter(
                    color: SRColors.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                  suffixText: selectedType == 'distance' ? 'km' : (S.isKo ? '회' : 'runs'),
                  suffixStyle: GoogleFonts.inter(
                    color: SRColors.onSurface.withValues(alpha: 0.4),
                    fontSize: 13,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: SRColors.onSurface.withValues(alpha: 0.2)),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: SRColors.primaryContainer),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                S.cancel,
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
                final raw = targetController.text.trim();
                final value = double.tryParse(raw);
                if (value == null || value <= 0) return;
                if (existing != null) {
                  await DatabaseHelper.updateGoal(
                    existing['id'] as int,
                    value,
                    type: selectedType,
                    period: selectedPeriod,
                  );
                } else {
                  await DatabaseHelper.insertGoal(selectedType, selectedPeriod, value);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadGoal();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: SRColors.primaryContainer,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                S.save,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    ).then((_) {
      targetController.dispose();
    });
  }

  Widget _dialogRadioOption<T>({
    required String label,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    final isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? SRColors.primaryContainer
                    : SRColors.onSurface.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: SRColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? SRColors.onSurface
                  : SRColors.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
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
                    if (level != _horrorLevel) SfxService().toggle();
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
              // Stadium Finale toggle
              _SettingsToggle(
                label: S.stadiumFinale,
                subtitle: S.stadiumFinaleDesc,
                value: _stadiumFinale,
                onChanged: (v) {
                  setState(() => _stadiumFinale = v);
                  _save('stadium_finale', '$v');
                },
              ),
              const SizedBox(height: 8),
              // Haptic Dread (추후 구현)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(S.hapticDread, style: GoogleFonts.inter(
                            fontSize: 14, fontWeight: FontWeight.w600,
                            color: SRColors.onSurface.withValues(alpha: 0.3),
                          )),
                          const SizedBox(height: 2),
                          Text(S.hapticDreadDesc, style: GoogleFonts.inter(
                            fontSize: 12, color: SRColors.onSurface.withValues(alpha: 0.2),
                          )),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: SRColors.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(S.comingSoon, style: GoogleFonts.inter(
                        fontSize: 9, fontWeight: FontWeight.w700,
                        color: SRColors.onSurface.withValues(alpha: 0.3), letterSpacing: 0.5,
                      )),
                    ),
                  ],
                ),
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
                const SizedBox(height: 20),
                Container(height: 0.5, color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 16),
                _buildShadowSpeedSlider(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShadowSpeedSlider() {
    final speedLabel = _shadowSpeed <= 0.75
        ? S.slow
        : _shadowSpeed >= 1.15
            ? S.fast
            : S.normal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.shadowSpeed,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SRColors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.shadowSpeedDesc,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: SRColors.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            Text(
              '${(_shadowSpeed * 100).round()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFF0044),
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
          ),
          child: Slider(
            value: _shadowSpeed,
            min: 0.7,
            max: 1.3,
            divisions: 6,
            onChanged: (value) {
              setState(() => _shadowSpeed = double.parse(value.toStringAsFixed(1)));
              _save('shadow_speed', _shadowSpeed.toStringAsFixed(1));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(S.slow, style: GoogleFonts.inter(
                fontSize: 10, color: SRColors.onSurface.withValues(alpha: 0.3),
              )),
              Text(speedLabel, style: GoogleFonts.inter(
                fontSize: 10, fontWeight: FontWeight.w700,
                color: const Color(0xFFFF0044).withValues(alpha: 0.6),
              )),
              Text(S.fast, style: GoogleFonts.inter(
                fontSize: 10, color: SRColors.onSurface.withValues(alpha: 0.3),
              )),
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
      _previewSub?.cancel();
      setState(() => _playingPreview = voiceId);
      await _previewPlayer.setAsset('assets/audio/preview/preview_danger_$voiceId.mp3');
      _previewPlayer.play();
      _previewSub = _previewPlayer.playerStateStream.listen((state) {
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
    final purchase = PurchaseService();
    final isTrial = purchase.isTrial;
    final daysLeft = purchase.trialDaysLeft;

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
                    isTrial ? S.freeTrialBanner : S.proActivated,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: SRColors.safe,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              if (isTrial) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: SRColors.safe.withValues(alpha: 0.6), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${S.trialDaysLeft}: $daysLeft${S.isKo ? '일' : ' days'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: SRColors.safe.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              _proBenefitRow(Icons.block, S.proBenefitNoAds),
              _proBenefitRow(Icons.psychology, S.proBenefitHorror),
              _proBenefitRow(Icons.map, S.proBenefitModes),
              _proBenefitRow(Icons.record_voice_over, S.proBenefitVoice),
              _proBenefitRow(Icons.speed, S.proBenefitSpeed),
            ],
          ),
        ),
        if (isTrial) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () async {
                final success = await PurchaseService().buyPro();
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(S.storeUnavailable), backgroundColor: SRColors.surface),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0044),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: Text(
                S.upgradeToPro,
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
            ),
          ),
        ],
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
            height: 72,
            child: ElevatedButton(
              onPressed: () async {
                final success = await PurchaseService().buyPro();
                if (success && mounted) {
                  SfxService().levelup();
                } else if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.storeUnavailable),
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
          const SizedBox(height: 10),
          // 무료체험 버튼
          _buildFreeTrialButton(),
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
                _proBenefitPreviewRow(Icons.speed, S.proBenefitSpeed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeTrialButton() {
    return FutureBuilder<String?>(
      future: DatabaseHelper.getSetting('trial_start_date'),
      builder: (context, snapshot) {
        final alreadyUsed = snapshot.data != null;
        if (alreadyUsed) return const SizedBox.shrink();
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: () async {
              final started = await PurchaseService().startTrial();
              if (!started || !context.mounted) return;
              SfxService().levelup();
              setState(() => _isPro = true);
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.freeTrialBanner),
                    backgroundColor: SRColors.safe,
                  ),
                );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF0044), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              S.startFreeTrial,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFF0044),
                letterSpacing: 2,
              ),
            ),
          ),
        );
      },
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
              SnackBar(
                content: Text(S.restoreTrying),
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
            onTap: () { SfxService().tapCard(); context.go('/'); },
          ),
          _NavIcon(
            icon: Icons.monitor_heart_outlined,
            isActive: _selectedNavIndex == 1,
            onTap: () { SfxService().tapCard(); context.go('/history'); },
          ),
          _NavIcon(
            icon: Icons.settings_outlined,
            isActive: _selectedNavIndex == 2,
            onTap: () {},
          ),
          _NavIcon(
            icon: Icons.analytics_outlined,
            isActive: _selectedNavIndex == 3,
            onTap: () { SfxService().tapCard(); context.go('/analysis'); },
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
          S.enterAdminKey,
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
                    SnackBar(
                      content: Text(S.proActivatedMsg),
                      backgroundColor: SRColors.surface,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.wrongKey),
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
            onChanged: (v) {
              if (v) {
                SfxService().switchOn();
              } else {
                SfxService().switchOff();
              }
              onChanged(v);
            },
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
