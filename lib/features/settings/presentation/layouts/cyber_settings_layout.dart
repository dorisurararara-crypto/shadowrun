import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/bgm_preferences.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

/// T5 — Neo-Noir Cyber 설정 화면 레이아웃.
///
/// 컨셉: "SYSTEM · OPS PANEL · USER PREFS & DIAGNOSTICS"
/// 팔레트: _bg #04040A · _red #FF1744 · _cyan #4DD0E1.
/// 타이포: 헤드 Playfair Italic + chromatic aberration. 라벨/데이터 JetBrains Mono.
/// 배경에 스캔라인, 네온 RGB 분리, 시안 괘선.
///
/// [PureSettingsLayout] 과 동일 시그니처. 토글/슬라이더/세그먼트는 터미널 UI 모듈.
class CyberSettingsLayout extends StatelessWidget {
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
  final String langCode;
  final ValueChanged<String> onLangChange;
  final String runMode;
  final ValueChanged<String> onRunModeChange;
  final String unit;
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
  final int horrorLevel;
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

  const CyberSettingsLayout({
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

  // ─── Cyber 팔레트 ────────────────────────────────────────
  static const _bg = Color(0xFF04040A);
  static const _bgAlt = Color(0xFF0A0A14);
  static const _red = Color(0xFFFF1744);
  static const _cyan = Color(0xFF4DD0E1);
  static const _cyanDim = Color(0xFF2A8A96);
  static const _text = Color(0xFFE8E8F0);
  static const _textDim = Color(0xFF9898A8);
  static const _textFade = Color(0xFF5A5A68);
  static const _textMute = Color(0xFF3A3A48);
  static const _borderCyan = Color(0x264DD0E1);
  static const _borderCyanDim = Color(0x144DD0E1);
  static const _panel = Color(0x0A4DD0E1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.6, -1.1),
                  radius: 1.1,
                  colors: [
                    _red.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-1.0, 1.0),
                  radius: 1.0,
                  colors: [
                    _cyan.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.6],
                ),
              ),
            ),
          ),
          const Positioned.fill(child: _ScanLines()),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                left: 22,
                right: 22,
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(),
                  const SizedBox(height: 16),
                  _titleBlock(),
                  const SizedBox(height: 18),
                  _profileCard(),
                  const SizedBox(height: 8),

                  _section(
                    id: 'SYS.01',
                    label: 'APPEARANCE',
                    count: '04',
                    children: [
                      _navRow(
                        key_: 'THEME',
                        name: themeDisplayName,
                        value: 'ACTIVE',
                        activeBadge: true,
                        onTap: () {
                          SfxService().tapCard();
                          onThemeTap();
                        },
                      ),
                      _segmentRow(
                        key_: 'LANG',
                        name: S.isKo ? '언어 설정' : 'LANGUAGE',
                        options: const ['ko', 'en'],
                        labels: const ['KO', 'EN'],
                        selected: langCode,
                        onChanged: (v) {
                          SfxService().toggle();
                          onLangChange(v);
                        },
                      ),
                      _segmentRow(
                        key_: 'RUN.MODE',
                        name: S.runMode.toUpperCase(),
                        options: const ['fullmap', 'mapcenter', 'datacenter'],
                        labels: const ['MAP', 'FOCUS', 'DATA'],
                        locks: [false, !isPro, !isPro],
                        selected: runMode,
                        onChanged: (v) {
                          SfxService().toggle();
                          onRunModeChange(v);
                        },
                      ),
                      _segmentRow(
                        key_: 'UNITS',
                        name: 'KM · METRIC',
                        options: const ['km', 'mi'],
                        labels: const ['km', 'mi'],
                        selected: unit,
                        onChanged: (v) {
                          SfxService().toggle();
                          onUnitChange(v);
                        },
                      ),
                    ],
                  ),

                  _section(
                    id: 'SYS.02',
                    label: 'RUN',
                    count: '01',
                    children: [
                      _navRow(
                        key_: 'SHOES',
                        name: _shoesSummary(),
                        value: '›',
                        onTap: () {
                          SfxService().tapCard();
                          onShoesTap();
                        },
                      ),
                    ],
                  ),

                  _section(
                    id: 'SYS.03',
                    label: 'GOAL',
                    count: '01',
                    children: [
                      _navRow(
                        key_: 'TARGET',
                        name: _goalSummary(),
                        value: '›',
                        activeBadge: activeGoal != null,
                        onTap: () {
                          SfxService().tapCard();
                          onGoalEditTap();
                        },
                      ),
                    ],
                  ),

                  _section(
                    id: 'SYS.04',
                    label: 'AUDIO',
                    count: '06',
                    children: [
                      _navRow(
                        key_: 'VOICE',
                        name: voiceLabel.toUpperCase(),
                        value: '›',
                        onTap: () {
                          SfxService().tapCard();
                          onVoiceTap();
                        },
                      ),
                      _toggleRow(
                        key_: 'SFX',
                        name: S.isKo ? '효과음' : 'SOUND EFFECTS',
                        value: sfxEnabled,
                        onChanged: onSfxToggle,
                      ),
                      _toggleRow(
                        key_: 'HAPTIC',
                        name: S.isKo ? '진동 피드백' : 'HAPTIC FEEDBACK',
                        value: hapticEnabled,
                        onChanged: onHapticToggle,
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: BgmPreferences.I.enabled,
                        builder: (context, bgmOn, _) => _toggleRow(
                          key_: 'BGM',
                          name: S.isKo ? '배경음' : 'BACKGROUND MUSIC',
                          value: bgmOn,
                          onChanged: (v) => BgmPreferences.I.setEnabled(v),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: BgmPreferences.I.enabled,
                        builder: (context, bgmOn, _) =>
                            ValueListenableBuilder<double>(
                          valueListenable: BgmPreferences.I.volume,
                          builder: (context, vol, _) =>
                              _bgmVolumeRow(enabled: bgmOn, volume: vol),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: BgmPreferences.I.externalMusicMode,
                        builder: (context, ext, _) => _toggleRowDesc(
                          key_: 'EXT.MUSIC',
                          name: S.isKo ? '내 음악 틀기' : 'USE MY MUSIC',
                          desc: S.isKo
                              ? '스포티파이·유튜브뮤직 등 기기 음악 우선'
                              : 'Prefer Spotify/YouTube Music over in-app.',
                          value: ext,
                          onChanged: (v) =>
                              BgmPreferences.I.setExternalMusicMode(v),
                        ),
                      ),
                    ],
                  ),

                  _fearSection(),
                  _proSection(),
                  _section(
                    id: 'SYS.07',
                    label: 'SUPPORT',
                    count: '02',
                    children: [
                      _navRow(
                        key_: 'PRIVACY',
                        name: S.isKo ? '개인정보 처리방침' : 'PRIVACY POLICY',
                        value: '›',
                        onTap: () {
                          SfxService().tapCard();
                          onPrivacyTap();
                        },
                      ),
                      _navRow(
                        key_: 'TERMS',
                        name: S.isKo ? '이용 약관' : 'TERMS OF SERVICE',
                        value: '›',
                        onTap: () {
                          SfxService().tapCard();
                          onTermsTap();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  _footer(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildTabs(context),
    );
  }

  // ============ TOP / TITLE ============

  Widget _topBar() {
    return Row(
      children: [
        _pulseTag('SYSTEM · v1.0.0'),
        const Spacer(),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            SfxService().tapCard();
            onBack();
          },
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: _borderCyan, width: 1),
              color: _panel,
            ),
            child: Text(
              '←',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 14,
                color: _cyan,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _titleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chromaticTitle('SYSTEM'),
        const SizedBox(height: 6),
        Text(
          'USER · PREFS · DIAGNOSTICS',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: _cyan,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              '37.5658°N · 127.0450°E',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: _textFade,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '//',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: _textMute,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'OPS PANEL',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: _red,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chromaticTitle(String text) {
    final style = GoogleFonts.playfairDisplay(
      fontSize: 44,
      fontStyle: FontStyle.italic,
      fontWeight: FontWeight.w900,
      height: 0.92,
      letterSpacing: -1.6,
    );
    Widget layer(Color color, Offset offset, {double alpha = 1}) {
      return Transform.translate(
        offset: offset,
        child: Opacity(
          opacity: alpha,
          child: Text(text, style: style.copyWith(color: color)),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        layer(_red, const Offset(-1.5, 0), alpha: 0.85),
        layer(_cyan, const Offset(1.5, 0), alpha: 0.65),
        layer(_text, Offset.zero),
      ],
    );
  }

  Widget _pulseTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: _red, width: 1),
        color: const Color(0x0AFF1744),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _red.withValues(alpha: 0.8),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: _red,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============ PROFILE ============

  Widget _profileCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().tapCard();
        onProfilePhotoTap();
      },
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: _panel,
          border: Border.all(color: _borderCyan, width: 1),
        ),
        child: Row(
          children: [
            _avatar(),
            const SizedBox(width: 12),
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
                              ? 'K. DOPPEL'
                              : userName.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 15,
                            color: _text,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPro ? _red : _borderCyanDim,
                          border: Border.all(
                            color: isPro ? _red : _cyanDim,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isPro ? 'PRO' : 'FREE',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            color: isPro ? _text : _cyan,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'SERIAL #SR-${_serial()} · SINCE ${_joinDate()}',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: _textFade,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasProfilePhoto
                        ? (S.isKo
                            ? '// 사진 교체 · 맵 마커'
                            : '// tap to replace · map marker')
                        : (S.isKo
                            ? '// 셀카 등록 · 맵 마커'
                            : '// tap to capture · map marker'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: _cyan,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 16,
                color: _cyan,
                fontWeight: FontWeight.w500,
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          border: Border.all(color: _red, width: 2),
          image: DecorationImage(
            image: FileImage(profilePhotoFile!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _bgAlt,
        border: Border.all(color: _red, width: 2),
        boxShadow: [
          BoxShadow(
            color: _red.withValues(alpha: 0.4),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        _avatarChar(userName),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 20,
          color: _red,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============ SECTIONS ============

  Widget _section({
    required String id,
    required String label,
    required String count,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHead(id: id, label: label, count: count),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionHead({
    required String id,
    required String label,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCyan, width: 1)),
      ),
      child: Row(
        children: [
          Text(
            '> ',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: _red,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: _cyan,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '$count KEYS',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: _textFade,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            id,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: _textMute,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fearSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onHorrorHeaderTap,
            child: Container(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: _borderCyan, width: 1)),
              ),
              child: Row(
                children: [
                  Text(
                    '> ',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: _red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'FEAR',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: _red,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '02 KEYS',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: _textFade,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'SYS.05',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: _textMute,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _horrorLevelRow(),
          _toggleRow(
            key_: 'ENTITY',
            name: S.entityAudio.toUpperCase(),
            value: ttsEnabled,
            onChanged: onTtsToggle,
          ),
        ],
      ),
    );
  }

  Widget _proSection() {
    final children = <Widget>[];
    if (isPro) {
      children.add(_navRow(
        key_: 'STATUS',
        name: isTrial
            ? '${S.isKo ? "체험" : "TRIAL"} · $trialDaysLeft${S.isKo ? "일" : "D"}'
            : (S.isKo ? '활성' : 'ACTIVE'),
        value: 'ONLINE',
        activeBadge: true,
        onTap: () {},
      ));
      if (isTrial) {
        children.add(_navRow(
          key_: 'UPGRADE',
          name: S.upgradeToPro.toUpperCase(),
          value: '›',
          activeBadge: true,
          onTap: () {
            SfxService().tapCard();
            onProUpgradeTap();
          },
        ));
      }
    } else {
      children.add(_navRow(
        key_: 'UPGRADE',
        name: S.upgradeToPro.toUpperCase(),
        value: '›',
        activeBadge: true,
        onTap: () {
          SfxService().tapCard();
          onProUpgradeTap();
        },
      ));
      if (!trialAlreadyUsed) {
        children.add(_navRow(
          key_: 'TRIAL',
          name: S.startFreeTrial.toUpperCase(),
          value: '›',
          onTap: () {
            SfxService().tapCard();
            onStartTrialTap();
          },
        ));
      }
      children.add(_navRow(
        key_: 'RESTORE',
        name: S.restorePurchases.toUpperCase(),
        value: '›',
        onTap: () {
          SfxService().tapCard();
          onRestorePurchases();
        },
      ));
    }
    return _section(
      id: 'SYS.06',
      label: 'PRO',
      count: children.length.toString().padLeft(2, '0'),
      children: children,
    );
  }

  // ============ ROWS ============

  Widget _navRow({
    required String key_,
    required String name,
    required String value,
    bool activeBadge = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _borderCyanDim, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                key_,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: _cyan,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: _text,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (activeBadge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.15),
                  border: Border.all(color: _red, width: 1),
                ),
                child: Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: _red,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text(
                  value,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: _cyan,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow({
    required String key_,
    required String name,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        value ? SfxService().switchOff() : SfxService().switchOn();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _borderCyanDim, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                key_,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: _cyan,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  color: _text,
                  letterSpacing: 0.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            _neonToggle(value),
          ],
        ),
      ),
    );
  }

  Widget _toggleRowDesc({
    required String key_,
    required String name,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        value ? SfxService().switchOff() : SfxService().switchOn();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _borderCyanDim, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(
                key_,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: _cyan,
                  letterSpacing: 1.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: _text,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '// $desc',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: _textFade,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _neonToggle(value),
          ],
        ),
      ),
    );
  }

  Widget _neonToggle(bool value) {
    return Container(
      width: 46,
      height: 22,
      decoration: BoxDecoration(
        color: value ? _red.withValues(alpha: 0.15) : _bgAlt,
        border: Border.all(
          color: value ? _red : _textMute,
          width: 1,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: _red.withValues(alpha: 0.4),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            left: value ? 26 : 2,
            top: 2,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: value ? _red : _textFade,
                boxShadow: value
                    ? [
                        BoxShadow(
                          color: _red.withValues(alpha: 0.8),
                          blurRadius: 4,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bgmVolumeRow({required bool enabled, required double volume}) {
    final percent = (volume * 100).round();
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border:
              Border(bottom: BorderSide(color: _borderCyanDim, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    'VOL',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: _cyan,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    S.isKo ? '배경음 크기' : 'BGM VOLUME',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      color: _text,
                      letterSpacing: 0.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    color: _red,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _red,
                inactiveTrackColor: _textMute,
                thumbColor: _red,
                overlayColor: _red.withValues(alpha: 0.15),
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                trackShape: const RoundedRectSliderTrackShape(),
              ),
              child: Slider(
                value: volume.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: enabled
                    ? (v) => BgmPreferences.I.volume.value = v
                    : null,
                onChangeEnd:
                    enabled ? (v) => BgmPreferences.I.setVolume(v) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentRow({
    required String key_,
    required String name,
    required List<String> options,
    required List<String> labels,
    List<bool>? locks,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final lockList = locks ?? List<bool>.filled(options.length, false);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCyanDim, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              key_,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: _cyan,
                letterSpacing: 1.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SizedBox(
              height: 32,
              child: Row(
                children: List.generate(options.length, (i) {
                  final isSelected = options[i] == selected;
                  final locked = lockList[i];
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(options[i]),
                      child: Container(
                        margin: EdgeInsets.only(
                          left: i == 0 ? 0 : 3,
                          right: i == options.length - 1 ? 0 : 3,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? _red : _borderCyan,
                            width: 1,
                          ),
                          color: isSelected
                              ? _red.withValues(alpha: 0.12)
                              : _panel,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              labels[i],
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 10,
                                color: isSelected
                                    ? _red
                                    : locked
                                        ? _textMute
                                        : _cyan,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (locked) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.lock, size: 9, color: _textMute),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _horrorLevelRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _borderCyanDim, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                child: Text(
                  'FEAR.LV',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: _red,
                    letterSpacing: 1.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  S.anxietyLevel.toUpperCase(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: _text,
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.15),
                  border: Border.all(color: _red, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _red.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  'LV ${horrorLevel.toString().padLeft(2, '0')}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    color: _red,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _red,
              inactiveTrackColor: _textMute,
              thumbColor: _red,
              overlayColor: _red.withValues(alpha: 0.15),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
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
                      '0$level',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: isActive ? _red : _textFade,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                        letterSpacing: 0.8,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.lock, size: 8, color: _textMute),
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

  // ============ FOOTER / TABS ============

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: _panel,
        border: Border.all(color: _borderCyan, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'SHADOW RUN',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: _cyan,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.15),
                  border: Border.all(color: _red, width: 1),
                ),
                child: Text(
                  versionLabel.replaceAll('·', '/'),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9,
                    color: _red,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            S.isKo
                ? '// 버전 ×7 탭 · 디버그 해제'
                : '// tap version ×7 to unlock debug',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 9,
              color: _textFade,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _borderCyan, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _tab('●', 'HOME', onTap: () {
                SfxService().tapCard();
                context.go('/');
              }),
              _tab('◷', 'LOGS', onTap: () {
                SfxService().tapCard();
                context.go('/history');
              }),
              _tab('◎', 'STATS', onTap: () {
                SfxService().tapCard();
                context.go('/analysis');
              }),
              _tab('⚙', 'SYS', active: true, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(
    String icon,
    String label, {
    bool active = false,
    required VoidCallback onTap,
  }) {
    final color = active ? _red : _textDim;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              icon,
              style: TextStyle(
                fontSize: 16,
                color: color,
                shadows: active
                    ? [
                        Shadow(
                          color: _red.withValues(alpha: 0.8),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 9,
                color: color,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ HELPERS ============

  String _avatarChar(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'K';
    return trimmed.characters.first.toUpperCase();
  }

  String _serial() {
    final hash = userName.hashCode.abs() % 9999;
    return hash.toString().padLeft(4, '0');
  }

  String _joinDate() {
    final now = DateTime.now();
    return '${now.year}.${now.month.toString().padLeft(2, '0')}';
  }

  String _shoesSummary() {
    if (shoes.isEmpty) {
      return S.isKo ? '등록 없음' : 'NONE';
    }
    final active =
        shoes.where((s) => (s['is_active'] as int? ?? 1) == 1).toList();
    if (active.isEmpty) {
      return S.isKo ? '모두 은퇴' : 'ALL RETIRED';
    }
    final totalM = active.fold<double>(
      0.0,
      (acc, s) => acc + ((s['total_distance_m'] as num? ?? 0).toDouble()),
    );
    final km = totalM / 1000.0;
    return '${active.length}${S.isKo ? '켤레 · ' : ' PAIR · '}${km.toStringAsFixed(1)}KM';
  }

  String _goalSummary() {
    final goal = activeGoal;
    if (goal == null) return S.isKo ? '없음' : 'NONE';
    final type = goal['type'] as String? ?? 'distance';
    final period = goal['period'] as String? ?? 'weekly';
    final target = (goal['target_value'] as num? ?? 0).toDouble();
    final periodLabel =
        period == 'weekly' ? S.goalPeriodWeekly : S.goalPeriodMonthly;
    if (type == 'distance') {
      return '$periodLabel · ${target.toStringAsFixed(0)}KM';
    } else {
      return '$periodLabel · ${target.toInt()}${S.isKo ? '회' : ' RUNS'}';
    }
  }
}

class _ScanLines extends StatelessWidget {
  const _ScanLines();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _ScanLinePainter(), size: Size.infinite),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0A4DD0E1)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
