import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

/// T1 Pure Cinematic 테마 전용 설정 화면 레이아웃.
///
/// 모든 설정 기능이 props로 주입되어 실제 동작한다.
/// 무드: 순검정(#000) 위에 오프화이트(#F5F5F5)와 말린 피(#8B0000/#C83030).
/// 한글은 Noto Serif KR, 영문은 Playfair Display Italic.
class PureSettingsLayout extends StatelessWidget {
  // Profile
  final String userName;
  final bool hasProfilePhoto;
  final File? profilePhotoFile;
  final VoidCallback onProfilePhotoTap;

  // Pro
  final bool isPro;
  final bool isTrial;
  final int trialDaysLeft;
  final bool trialAlreadyUsed;

  // Appearance
  final String themeDisplayName;
  final VoidCallback onThemeTap;
  final String langCode; // 'ko' | 'en'
  final ValueChanged<String> onLangChange;
  final String runMode; // 'fullmap' | 'mapcenter' | 'datacenter'
  final ValueChanged<String> onRunModeChange;
  final String unit; // 'km' | 'mi'
  final ValueChanged<String> onUnitChange;

  // Run / Goal
  final List<Map<String, dynamic>> shoes;
  final VoidCallback onShoesTap;
  final Map<String, dynamic>? activeGoal;
  final VoidCallback onGoalEditTap;

  // Audio / Fear
  final bool ttsEnabled;
  final ValueChanged<bool> onTtsToggle;
  final bool sfxEnabled;
  final ValueChanged<bool> onSfxToggle;
  final bool hapticEnabled;
  final ValueChanged<bool> onHapticToggle;
  final String voiceId;
  final String voiceLabel;
  final VoidCallback onVoiceTap;
  final int horrorLevel; // 1..5
  final ValueChanged<int> onHorrorLevelChange;
  final VoidCallback onHorrorHeaderTap;

  // PRO
  final VoidCallback onProUpgradeTap;
  final VoidCallback onStartTrialTap;
  final VoidCallback onRestorePurchases;

  // Support
  final VoidCallback onPrivacyTap;
  final VoidCallback onTermsTap;

  // Footer / Nav
  final String versionLabel;
  final VoidCallback onBack;

  const PureSettingsLayout({
    super.key,
    required this.userName,
    required this.hasProfilePhoto,
    this.profilePhotoFile,
    required this.onProfilePhotoTap,
    required this.isPro,
    required this.isTrial,
    required this.trialDaysLeft,
    required this.trialAlreadyUsed,
    required this.themeDisplayName,
    required this.onThemeTap,
    required this.langCode,
    required this.onLangChange,
    required this.runMode,
    required this.onRunModeChange,
    required this.unit,
    required this.onUnitChange,
    required this.shoes,
    required this.onShoesTap,
    required this.activeGoal,
    required this.onGoalEditTap,
    required this.ttsEnabled,
    required this.onTtsToggle,
    required this.sfxEnabled,
    required this.onSfxToggle,
    required this.hapticEnabled,
    required this.onHapticToggle,
    required this.voiceId,
    required this.voiceLabel,
    required this.onVoiceTap,
    required this.horrorLevel,
    required this.onHorrorLevelChange,
    required this.onHorrorHeaderTap,
    required this.onProUpgradeTap,
    required this.onStartTrialTap,
    required this.onRestorePurchases,
    required this.onPrivacyTap,
    required this.onTermsTap,
    required this.versionLabel,
    required this.onBack,
  });

  // Pure Cinematic 팔레트
  static const _bg = Color(0xFF000000);
  static const _ink = Color(0xFFF5F5F5);
  static const _inkDim = Color(0xFF9A9A9A);
  static const _inkFade = Color(0xFF5A5A5E);
  static const _inkGhost = Color(0xFF3A3A3E);
  static const _red = Color(0xFF8B0000);
  static const _redSub = Color(0xFFC83030);
  static const _redEmber = Color(0xFF5A0000);
  static const _hair = Color(0x14F5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          bottom: 40,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBar(),
            const SizedBox(height: 10),
            _titleBlock(),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _profileCard(),
            ),

            // APPEARANCE
            _section(
              title: 'Appearance',
              children: [
                _row(
                  label: S.isKo ? '테마' : 'Theme',
                  sub: 'theme',
                  value: themeDisplayName,
                  accent: true,
                  onTap: () { SfxService().tapCard(); onThemeTap(); },
                ),
                _rowSegment(
                  label: S.isKo ? '언어' : 'Language',
                  sub: 'language',
                  options: const ['ko', 'en'],
                  labels: const ['한국어', 'English'],
                  selected: langCode,
                  onChanged: (v) { SfxService().toggle(); onLangChange(v); },
                ),
                _rowSegmentWithLock(
                  label: S.runMode,
                  sub: 'run mode',
                  options: const ['fullmap', 'mapcenter', 'datacenter'],
                  labels: [S.fullMap, S.mapFocus, S.dataFocus],
                  locks: [false, !isPro, !isPro],
                  selected: runMode,
                  onChanged: (v) { SfxService().toggle(); onRunModeChange(v); },
                ),
                _rowSegment(
                  label: S.distanceUnits,
                  sub: 'units',
                  options: const ['km', 'mi'],
                  labels: const ['km', 'mi'],
                  selected: unit,
                  onChanged: (v) { SfxService().toggle(); onUnitChange(v); },
                ),
              ],
            ),

            // RUN
            _section(
              title: 'Run',
              children: [
                _row(
                  label: S.isKo ? '러닝화' : 'Shoes',
                  sub: 'footprints',
                  value: _shoesSummary(),
                  onTap: () { SfxService().tapCard(); onShoesTap(); },
                ),
              ],
            ),

            // GOAL
            _section(
              title: 'Goal',
              children: [
                _row(
                  label: S.isKo ? '활성 목표' : 'Active goal',
                  sub: 'goal',
                  value: _goalSummary(),
                  accent: activeGoal != null,
                  onTap: () { SfxService().tapCard(); onGoalEditTap(); },
                ),
              ],
            ),

            // AUDIO
            _section(
              title: 'Audio',
              children: [
                _row(
                  label: S.isKo ? '나레이터 목소리' : 'Voice of Shadow',
                  sub: 'voice',
                  value: voiceLabel,
                  onTap: () { SfxService().tapCard(); onVoiceTap(); },
                ),
                _rowSwitch(
                  label: S.isKo ? '효과음' : 'Sound Effects',
                  sub: 'sfx',
                  value: sfxEnabled,
                  onChanged: onSfxToggle,
                ),
                _rowSwitch(
                  label: S.hapticDread,
                  sub: 'haptic',
                  value: hapticEnabled,
                  onChanged: onHapticToggle,
                ),
              ],
            ),

            // FEAR — 헤더 탭 시 admin key dialog 트리거
            _fearSection(context),

            // PRO
            _proSection(),

            // SUPPORT
            _section(
              title: 'Support',
              children: [
                _row(
                  label: S.isKo ? '개인정보 처리방침' : 'Privacy Policy',
                  sub: 'privacy',
                  onTap: () { SfxService().tapCard(); onPrivacyTap(); },
                ),
                _row(
                  label: S.isKo ? '이용 약관' : 'Terms of Service',
                  sub: 'terms',
                  onTap: () { SfxService().tapCard(); onTermsTap(); },
                ),
              ],
            ),

            const SizedBox(height: 32),
            _footer(),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  // ========= TOP / TITLE =========

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () { SfxService().tapCard(); onBack(); },
            child: SizedBox(
              height: 36,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Text(
                    S.isKo ? '‹  홈' : '‹  back',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12,
                      color: _inkFade,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _titleBlock() {
    return Column(
      children: [
        Text(
          'Settings',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 40,
            color: _ink,
            height: 1.0,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          S.isKo ? '설  정' : 'S E T T I N G S',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 10.5,
            color: _redSub,
            letterSpacing: 4.2,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Container(width: 28, height: 1, color: _redEmber),
      ],
    );
  }

  // ========= PROFILE =========

  Widget _profileCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () { SfxService().tapCard(); onProfilePhotoTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: _hair, width: 1),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x14570000), Colors.transparent],
            stops: [0.0, 0.8],
          ),
        ),
        child: Row(
          children: [
            _avatar(),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          userName.isEmpty
                              ? (S.isKo ? '이름 없는 그림자' : 'Nameless shadow')
                              : userName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.notoSerifKr(
                            fontSize: 14,
                            color: _ink,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.14,
                          ),
                        ),
                      ),
                      if (isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: _red, width: 1),
                          ),
                          child: Text(
                            'Pro',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 9,
                              color: _redSub,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.7,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasProfilePhoto
                        ? (S.isKo ? '사진 변경 · 지도 마커에 반영' : 'tap to change photo')
                        : (S.isKo ? '셀카 촬영 · 지도 마커 표시' : 'take a selfie for map marker'),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 10.5,
                      color: _inkFade,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.42,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                color: _inkFade,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    if (hasProfilePhoto && profilePhotoFile != null) {
      return Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _red, width: 1),
          image: DecorationImage(
            image: FileImage(profilePhotoFile!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: _red, width: 1),
      ),
      child: Text(
        _avatarChar(userName),
        style: GoogleFonts.playfairDisplay(
          fontSize: 22,
          color: _ink,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // ========= SECTIONS =========

  Widget _section({required String title, required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(title),
          ..._renderChildren(children),
        ],
      ),
    );
  }

  Widget _fearSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onHorrorHeaderTap,
            child: SizedBox(
              width: double.infinity,
              child: _sectionHeader('Fear'),
            ),
          ),
          ..._renderChildren([
            _horrorLevelRow(),
            _rowSwitch(
              label: S.entityAudio,
              sub: 'whispers',
              value: ttsEnabled,
              onChanged: onTtsToggle,
            ),
          ]),
        ],
      ),
    );
  }

  Widget _proSection() {
    final children = <Widget>[];
    if (isPro) {
      children.add(_row(
        label: S.isKo ? 'PRO 상태' : 'PRO status',
        sub: 'status',
        value: isTrial
            ? '${S.isKo ? "체험" : "trial"} · $trialDaysLeft${S.isKo ? "일" : "d"}'
            : (S.isKo ? '활성' : 'active'),
        accent: true,
        onTap: () {},
      ));
      if (isTrial) {
        children.add(_row(
          label: S.upgradeToPro,
          sub: 'unlock',
          value: '',
          accent: true,
          onTap: () { SfxService().tapCard(); onProUpgradeTap(); },
        ));
      }
    } else {
      children.add(_row(
        label: S.upgradeToPro,
        sub: S.unlockUltimateTerror.toLowerCase(),
        value: '',
        accent: true,
        onTap: () { SfxService().tapCard(); onProUpgradeTap(); },
      ));
      if (!trialAlreadyUsed) {
        children.add(_row(
          label: S.startFreeTrial,
          sub: 'trial',
          value: '',
          onTap: () { SfxService().tapCard(); onStartTrialTap(); },
        ));
      }
      children.add(_row(
        label: S.restorePurchases,
        sub: 'restore',
        value: '',
        onTap: () { SfxService().tapCard(); onRestorePurchases(); },
      ));
    }
    return _section(title: 'Pro', children: children);
  }

  Widget _sectionHeader(String label) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _hair, width: 1),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.playfairDisplay(
          fontSize: 10,
          color: _redSub,
          letterSpacing: 4.0,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  List<Widget> _renderChildren(List<Widget> widgets) {
    final result = <Widget>[];
    for (int i = 0; i < widgets.length; i++) {
      result.add(
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: i == widgets.length - 1 ? Colors.transparent : _hair,
                width: 1,
              ),
            ),
          ),
          child: widgets[i],
        ),
      );
    }
    return result;
  }

  // ========= ROW BUILDERS =========

  Widget _row({
    required String label,
    required String sub,
    String value = '',
    bool accent = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: _labelSub(label, sub),
            ),
            if (value.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, left: 8),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 12,
                      color: accent ? _redSub : _inkDim,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.24,
                    ),
                  ),
                ),
              ),
            Text(
              '›',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                color: _inkFade,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowSwitch({
    required String label,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: _labelSub(label, sub)),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: (v) {
                v ? SfxService().switchOn() : SfxService().switchOff();
                onChanged(v);
              },
              activeThumbColor: _redSub,
              activeTrackColor: _red.withValues(alpha: 0.4),
              inactiveThumbColor: _inkFade,
              inactiveTrackColor: _inkGhost,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowSegment({
    required String label,
    required String sub,
    required List<String> options,
    required List<String> labels,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelSub(label, sub),
          const SizedBox(height: 10),
          _segment(
            options: options,
            labels: labels,
            locks: List.filled(options.length, false),
            selected: selected,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _rowSegmentWithLock({
    required String label,
    required String sub,
    required List<String> options,
    required List<String> labels,
    required List<bool> locks,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelSub(label, sub),
          const SizedBox(height: 10),
          _segment(
            options: options,
            labels: labels,
            locks: locks,
            selected: selected,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required List<String> options,
    required List<String> labels,
    required List<bool> locks,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 34,
      child: Row(
        children: List.generate(options.length, (i) {
          final isSelected = options[i] == selected;
          final locked = locks[i];
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(options[i]),
              child: Container(
                margin: EdgeInsets.only(
                  left: i == 0 ? 0 : 4,
                  right: i == options.length - 1 ? 0 : 4,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? _red : _hair,
                    width: 1,
                  ),
                  color: isSelected ? const Color(0x14C83030) : Colors.transparent,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      labels[i],
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 11,
                        color: isSelected
                            ? _redSub
                            : locked
                                ? _inkGhost
                                : _inkDim,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.lock, size: 9, color: _inkGhost),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _horrorLevelRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _labelSub(S.anxietyLevel, 'intensity')),
              Text(
                horrorLevel.toString().padLeft(2, '0'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  color: _redSub,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _red,
              inactiveTrackColor: _inkGhost,
              thumbColor: _redSub,
              overlayColor: _red.withValues(alpha: 0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackShape: const RoundedRectSliderTrackShape(),
            ),
            child: Slider(
              value: horrorLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) => onHorrorLevelChange(v.round()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(5, (i) {
                final level = i + 1;
                final locked = !isPro && level > 2;
                final isActive = level == horrorLevel;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$level',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 10,
                        color: isActive ? _redSub : _inkFade,
                        fontStyle: FontStyle.italic,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.lock, size: 8, color: _inkGhost),
                    ],
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelSub(String label, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSerifKr(
            fontSize: 13,
            color: _ink,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.13,
          ),
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.playfairDisplay(
              fontSize: 9.5,
              color: _inkGhost,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.6,
            ),
          ),
        ],
      ],
    );
  }

  // ========= FOOTER =========

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          Text(
            versionLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 10.5,
              color: _inkGhost,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.5,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.isKo ? '× 7회 탭하여 잠금해제' : 'tap × 7 to unlock',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 10.5,
              color: _inkGhost,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  // ========= HELPERS =========

  String _avatarChar(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '影';
    return trimmed.characters.first.toUpperCase();
  }

  String _shoesSummary() {
    if (shoes.isEmpty) {
      return S.isKo ? '등록 없음' : 'none';
    }
    final active = shoes.where((s) => (s['is_active'] as int? ?? 1) == 1).toList();
    if (active.isEmpty) {
      return S.isKo ? '모두 은퇴' : 'all retired';
    }
    final totalM = active.fold<double>(
      0.0,
      (acc, s) => acc + ((s['total_distance_m'] as num? ?? 0).toDouble()),
    );
    final km = totalM / 1000.0;
    return '${active.length}${S.isKo ? '켤레 · ' : ' pair · '}${km.toStringAsFixed(1)}km';
  }

  String _goalSummary() {
    final goal = activeGoal;
    if (goal == null) return S.isKo ? '없음' : 'none';
    final type = goal['type'] as String? ?? 'distance';
    final period = goal['period'] as String? ?? 'weekly';
    final target = (goal['target_value'] as num? ?? 0).toDouble();
    final periodLabel = period == 'weekly' ? S.goalPeriodWeekly : S.goalPeriodMonthly;
    if (type == 'distance') {
      return '$periodLabel · ${target.toStringAsFixed(0)}km';
    } else {
      return '$periodLabel · ${target.toInt()}${S.isKo ? '회' : ' runs'}';
    }
  }
}
