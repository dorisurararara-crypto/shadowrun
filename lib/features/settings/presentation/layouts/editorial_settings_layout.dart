import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/bgm_preferences.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

/// T4 — Editorial Thriller 설정 화면 레이아웃.
///
/// 컨셉: "MASTHEAD · COLOPHON · VOL.01"
/// 팔레트: _ink #0A0A0A · _white #FFFFFF · _red #DC2626.
/// 타이포: 제목 Playfair Display Italic, eyebrow Inter All-caps, 데이터 IBM Plex Mono.
/// 굵은 2px white rule, 드롭캡, § 페이지 번호, 기사 레이아웃으로 설정 배치.
///
/// [PureSettingsLayout] 과 동일한 props 시그니처를 받아 매거진 판권면으로 재현.
class EditorialSettingsLayout extends StatelessWidget {
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

  const EditorialSettingsLayout({
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

  // ─── Editorial 팔레트 ────────────────────────────────────
  static const _ink = Color(0xFF0A0A0A);
  static const _white = Color(0xFFFFFFFF);
  static const _red = Color(0xFFDC2626);
  static const _redSoft = Color(0xFFF87171);
  static const _muted = Color(0xFF888888);
  static const _mutedLight = Color(0xFFAAAAAA);
  static const _mutedDim = Color(0xFF555555);
  static const _mutedDeep = Color(0xFF333333);
  static const _hair = Color(0x1FFFFFFF);
  static const _hairLow = Color(0x14FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          const Positioned.fill(child: _Grain()),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 18,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(),
                  const SizedBox(height: 6),
                  Container(height: 1, color: _hair),
                  const SizedBox(height: 14),
                  _titleBlock(),
                  const SizedBox(height: 14),
                  _profileCard(),
                  const SizedBox(height: 14),

                  _section(
                    num: '01',
                    label: S.isKo ? '외관' : 'APPEARANCE',
                    children: [
                      _navRow(
                        label: S.isKo ? '테마' : 'Theme',
                        value: themeDisplayName,
                        valueAccent: true,
                        onTap: () {
                          SfxService().tapCard();
                          onThemeTap();
                        },
                      ),
                      _segmentRow(
                        label: S.isKo ? '언어' : 'Language',
                        options: const ['ko', 'en'],
                        labels: const ['한국어', 'English'],
                        selected: langCode,
                        onChanged: (v) {
                          SfxService().toggle();
                          onLangChange(v);
                        },
                      ),
                      _segmentRow(
                        label: S.runMode,
                        options: const ['fullmap', 'mapcenter', 'datacenter'],
                        labels: [S.fullMap, S.mapFocus, S.dataFocus],
                        locks: [false, !isPro, !isPro],
                        selected: runMode,
                        onChanged: (v) {
                          SfxService().toggle();
                          onRunModeChange(v);
                        },
                      ),
                      _segmentRow(
                        label: S.distanceUnits,
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
                    num: '02',
                    label: S.isKo ? '러닝' : 'RUN',
                    children: [
                      _navRow(
                        label: S.isKo ? '러닝화' : 'Shoes',
                        value: _shoesSummary(),
                        onTap: () {
                          SfxService().tapCard();
                          onShoesTap();
                        },
                      ),
                    ],
                  ),

                  _section(
                    num: '03',
                    label: S.isKo ? '목표' : 'GOAL',
                    children: [
                      _navRow(
                        label: S.isKo ? '활성 목표' : 'Active goal',
                        value: _goalSummary(),
                        valueAccent: activeGoal != null,
                        onTap: () {
                          SfxService().tapCard();
                          onGoalEditTap();
                        },
                      ),
                    ],
                  ),

                  _section(
                    num: '04',
                    label: S.isKo ? '오디오' : 'AUDIO',
                    children: [
                      _navRow(
                        label: S.isKo ? '나레이터 목소리' : 'Voice of Shadow',
                        value: voiceLabel,
                        onTap: () {
                          SfxService().tapCard();
                          onVoiceTap();
                        },
                      ),
                      _switchRow(
                        label: S.isKo ? '효과음' : 'Sound Effects',
                        value: sfxEnabled,
                        onChanged: onSfxToggle,
                      ),
                      _switchRow(
                        label: S.hapticDread,
                        value: hapticEnabled,
                        onChanged: onHapticToggle,
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: BgmPreferences.I.enabled,
                        builder: (context, bgmOn, _) => _switchRow(
                          label:
                              S.isKo ? '배경음' : 'Background Music',
                          value: bgmOn,
                          onChanged: (v) =>
                              BgmPreferences.I.setEnabled(v),
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
                        builder: (context, ext, _) => _switchRowDesc(
                          label: S.isKo ? '내 음악 틀기' : 'Use My Music',
                          desc: S.isKo
                              ? '스포티파이·유튜브뮤직 등 기기 음악 우선 재생'
                              : 'Lets Spotify/YouTube Music play over the app.',
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
                    num: '07',
                    label: S.isKo ? '지원' : 'SUPPORT',
                    children: [
                      _navRow(
                        label: S.isKo ? '개인정보 처리방침' : 'Privacy',
                        value: '→',
                        onTap: () {
                          SfxService().tapCard();
                          onPrivacyTap();
                        },
                      ),
                      _navRow(
                        label: S.isKo ? '이용 약관' : 'Terms',
                        value: '→',
                        onTap: () {
                          SfxService().tapCard();
                          onTermsTap();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  _footer(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ============ TOP / MASTHEAD ============

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            SfxService().tapCard();
            onBack();
          },
          child: Text(
            '‹ COVER',
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              color: _muted,
              letterSpacing: 3.5,
            ),
          ),
        ),
        const Spacer(),
        Text(
          'MASTHEAD',
          style: GoogleFonts.playfairDisplay(
            fontSize: 10,
            fontStyle: FontStyle.italic,
            color: _redSoft,
            letterSpacing: 1.5,
          ),
        ),
        const Spacer(),
        Text(
          'SHADOWRUN/SET',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w300,
            color: _muted,
            letterSpacing: 3.5,
          ),
        ),
      ],
    );
  }

  Widget _titleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vol. 01',
          style: GoogleFonts.playfairDisplay(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: _red,
            letterSpacing: 2.2,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          (S.isKo ? '판권지 · 편집진 & 설정' : 'The Masthead · Staff & Settings')
              .toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w200,
            color: _muted,
            letterSpacing: 3.2,
          ),
        ),
        const SizedBox(height: 10),
        Container(height: 2, color: _white),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: GoogleFonts.playfairDisplay(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              color: _white,
              height: 0.9,
              letterSpacing: -2.2,
            ),
            children: const [
              TextSpan(text: 'Masthead'),
              TextSpan(text: '.', style: TextStyle(color: _red)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          S.isKo
              ? '"누가 이 매거진을 만들었는가" — 판권지이자 설정집.'
              : '"Who runs this magazine" — colophon & preferences.',
          style: GoogleFonts.playfairDisplay(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            color: _mutedLight,
            height: 1.35,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ============ PROFILE CARD ============

  Widget _profileCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        SfxService().tapCard();
        onProfilePhotoTap();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: _hairLow,
          border: Border.all(color: _hair, width: 1),
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
                      Text(
                        'EDITOR · ',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                          color: _muted,
                          letterSpacing: 2.5,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          userName.isEmpty
                              ? (S.isKo ? '익명 편집자' : 'Anonymous')
                              : userName,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w900,
                            color: _white,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isPro ? _red : Colors.transparent,
                          border: Border.all(color: _red, width: 1),
                        ),
                        child: Text(
                          isPro
                              ? (isTrial ? 'PRO · TRIAL' : 'PRO · FOUNDING')
                              : 'STAFF · READER',
                          style: GoogleFonts.inter(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: isPro ? _white : _red,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasProfilePhoto
                        ? (S.isKo
                            ? '사진 교체 · 지도 마커 반영'
                            : 'tap to change photo · map marker')
                        : (S.isKo
                            ? '셀카 촬영 · 지도 마커 등록'
                            : 'take a selfie for map marker'),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 9,
                      color: _mutedLight,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '→',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: _red,
                fontWeight: FontWeight.w300,
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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _red, width: 2),
          image: DecorationImage(
            image: FileImage(profilePhotoFile!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 52,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _red,
      ),
      child: Text(
        _avatarChar(userName),
        style: GoogleFonts.playfairDisplay(
          fontSize: 26,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w900,
          color: _white,
        ),
      ),
    );
  }

  // ============ SECTIONS ============

  Widget _section({
    required String num,
    required String label,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHead(num: num, label: label),
          Container(height: 1, color: _hair),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionHead({required String num, required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Text(
            '◆',
            style: TextStyle(color: _red, fontSize: 9),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _red,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: _hairLow)),
          const SizedBox(width: 10),
          Text(
            '§ $num',
            style: GoogleFonts.playfairDisplay(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: _mutedLight,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fearSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onHorrorHeaderTap,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Text(
                    '◆',
                    style: TextStyle(color: _red, fontSize: 9),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    S.isKo ? '공포' : 'FEAR',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _red,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 1, color: _hairLow)),
                  const SizedBox(width: 10),
                  Text(
                    '§ 05',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: _mutedLight,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 1, color: _hair),
          _horrorLevelRow(),
          _switchRow(
            label: S.entityAudio,
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
        label: S.isKo ? 'PRO 상태' : 'PRO status',
        value: isTrial
            ? '${S.isKo ? "체험" : "trial"} · $trialDaysLeft${S.isKo ? "일" : "d"}'
            : (S.isKo ? '활성' : 'active'),
        valueAccent: true,
        onTap: () {},
      ));
      if (isTrial) {
        children.add(_navRow(
          label: S.upgradeToPro,
          value: '→',
          valueAccent: true,
          onTap: () {
            SfxService().tapCard();
            onProUpgradeTap();
          },
        ));
      }
    } else {
      children.add(_navRow(
        label: S.upgradeToPro,
        value: '→',
        valueAccent: true,
        onTap: () {
          SfxService().tapCard();
          onProUpgradeTap();
        },
      ));
      if (!trialAlreadyUsed) {
        children.add(_navRow(
          label: S.startFreeTrial,
          value: '→',
          onTap: () {
            SfxService().tapCard();
            onStartTrialTap();
          },
        ));
      }
      children.add(_navRow(
        label: S.restorePurchases,
        value: '→',
        onTap: () {
          SfxService().tapCard();
          onRestorePurchases();
        },
      ));
    }
    return _section(
      num: '06',
      label: S.isKo ? '구독' : 'PRO',
      children: children,
    );
  }

  // ============ ROWS ============

  Widget _navRow({
    required String label,
    required String value,
    bool valueAccent = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _hair, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: _white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    color: valueAccent ? _red : _mutedLight,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hair, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.playfairDisplay(
                fontSize: 15,
                fontStyle: FontStyle.italic,
                color: _white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value
                ? (S.isKo ? 'ON' : 'ON')
                : (S.isKo ? 'OFF' : 'OFF'),
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: value ? _red : _mutedDim,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: (v) {
                v ? SfxService().switchOn() : SfxService().switchOff();
                onChanged(v);
              },
              activeThumbColor: _white,
              activeTrackColor: _red,
              inactiveThumbColor: _muted,
              inactiveTrackColor: _mutedDeep,
            ),
          ),
        ],
      ),
    );
  }

  Widget _switchRowDesc({
    required String label,
    required String desc,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hair, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: _white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: _mutedLight,
                    letterSpacing: 0.3,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: (v) {
                v ? SfxService().switchOn() : SfxService().switchOff();
                onChanged(v);
              },
              activeThumbColor: _white,
              activeTrackColor: _red,
              inactiveThumbColor: _muted,
              inactiveTrackColor: _mutedDeep,
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
          border: Border(bottom: BorderSide(color: _hair, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    S.isKo ? '배경음 크기' : 'BGM Volume',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: _white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '$percent%',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: _red,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _red,
                inactiveTrackColor: _mutedDeep,
                thumbColor: _white,
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
    required String label,
    required List<String> options,
    required List<String> labels,
    List<bool>? locks,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final lockList = locks ?? List<bool>.filled(options.length, false);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _hair, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: GoogleFonts.playfairDisplay(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: _white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
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
                        left: i == 0 ? 0 : 4,
                        right: i == options.length - 1 ? 0 : 4,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? _red : _hair,
                          width: isSelected ? 1.5 : 1,
                        ),
                        color:
                            isSelected ? _red.withValues(alpha: 0.1) : _hairLow,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            labels[i],
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? _red
                                  : locked
                                      ? _mutedDim
                                      : _mutedLight,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (locked) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.lock, size: 9, color: _mutedDim),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),
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
        border: Border(bottom: BorderSide(color: _hair, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.anxietyLevel,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: _white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                horrorLevel.toString().padLeft(2, '0'),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 34,
                  fontStyle: FontStyle.italic,
                  color: _red,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _red,
              inactiveTrackColor: _mutedDeep,
              thumbColor: _white,
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
                      '$level',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        color: isActive ? _red : _muted,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.lock, size: 8, color: _mutedDim),
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

  // ============ FOOTER / NAV ============

  Widget _footer() {
    return Column(
      children: [
        Container(height: 2, color: _white),
        const SizedBox(height: 14),
        Text(
          'SHADOW RUN MAGAZINE',
          style: GoogleFonts.playfairDisplay(
            fontSize: 14,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
            color: _white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          S.isKo
              ? 'Founded 2026 · 매월 어둠에서 발간'
              : 'Founded 2026 · Published monthly from the dark',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w300,
            color: _mutedLight,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          versionLabel,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            color: _muted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          S.isKo ? '// 버전 ×7 탭 · 디버그 해제' : '// tap version ×7 to unlock',
          style: GoogleFonts.ibmPlexMono(
            fontSize: 9,
            color: _mutedDim,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(top: BorderSide(color: _white, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem('COVER', 'home', onTap: () {
                SfxService().tapCard();
                context.go('/');
              }),
              _navItem('BACK', 'archive', onTap: () {
                SfxService().tapCard();
                context.go('/history');
              }),
              _navItem('REPORT', 'stats', onTap: () {
                SfxService().tapCard();
                context.go('/analysis');
              }),
              _navItem('MAST', 'settings', active: true, onTap: () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(
    String top,
    String bottom, {
    bool active = false,
    required VoidCallback onTap,
  }) {
    final color = active ? _red : _muted;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              top,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              bottom,
              style: GoogleFonts.playfairDisplay(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: color,
                fontWeight: FontWeight.w400,
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
    if (trimmed.isEmpty) return 'D';
    return trimmed.characters.first.toUpperCase();
  }

  String _shoesSummary() {
    if (shoes.isEmpty) {
      return S.isKo ? '등록 없음' : 'none';
    }
    final active =
        shoes.where((s) => (s['is_active'] as int? ?? 1) == 1).toList();
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
    final periodLabel =
        period == 'weekly' ? S.goalPeriodWeekly : S.goalPeriodMonthly;
    if (type == 'distance') {
      return '$periodLabel · ${target.toStringAsFixed(0)}km';
    } else {
      return '$periodLabel · ${target.toInt()}${S.isKo ? '회' : ' runs'}';
    }
  }
}

class _Grain extends StatelessWidget {
  const _Grain();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _GrainPainter(), size: Size.infinite),
    );
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x03FFFFFF)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
