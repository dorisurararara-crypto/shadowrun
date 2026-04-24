import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/bgm_preferences.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

/// T2 — Film Noir 설정 화면 레이아웃.
///
/// 컨셉: "AGENT PROFILE · CASE FILE / PERSONNEL FILE"
/// 팔레트: _ink #0D0907 · _paper #E8DCC4 · _brass #B89660 · _wine #8B2635
/// 타이포: 헤드 Cormorant Garamond Italic, 라벨 Oswald caps.
/// 섹션은 §01~§06 번호를 가진 파일 폴더 느낌.
///
/// [PureSettingsLayout] 과 생성자 시그니처가 동일하며 동일 props 를 받아
/// 동작만 누아르 톤으로 재해석한다.
class NoirSettingsLayout extends StatelessWidget {
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

  const NoirSettingsLayout({
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

  // ─── Film Noir 팔레트 ────────────────────────────────────
  static const _ink = Color(0xFF0D0907);
  static const _ink2 = Color(0xFF160E08);
  static const _ink3 = Color(0xFF0A0604);
  static const _paper = Color(0xFFE8DCC4);
  static const _paperDim = Color(0xFFA89A80);
  static const _paperFade = Color(0xFF6A5D48);
  static const _brass = Color(0xFFB89660);
  static const _brassDim = Color(0xFF8A6F48);
  static const _wine = Color(0xFF8B2635);
  static const _line = Color(0xFF2A1D10);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 28,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(),
                  const SizedBox(height: 18),
                  _titleBlock(),
                  const SizedBox(height: 18),
                  _profileCard(),
                  const SizedBox(height: 4),

                  _section(
                    num: '01',
                    title: S.isKo ? '외관' : 'APPEARANCE',
                    children: [
                      _navRow(
                        label: S.isKo ? '테마' : 'Theme',
                        sub: 'VISUAL · MOOD',
                        value: themeDisplayName,
                        accent: true,
                        onTap: () { SfxService().tapCard(); onThemeTap(); },
                      ),
                      _segmentRow(
                        label: S.isKo ? '언어' : 'Language',
                        sub: 'LANGUAGE',
                        options: const ['ko', 'en'],
                        labels: const ['한국어', 'English'],
                        selected: langCode,
                        onChanged: (v) { SfxService().toggle(); onLangChange(v); },
                      ),
                      _segmentRow(
                        label: S.runMode,
                        sub: 'RUN MODE',
                        options: const ['fullmap', 'mapcenter', 'datacenter'],
                        labels: [S.fullMap, S.mapFocus, S.dataFocus],
                        locks: [false, !isPro, !isPro],
                        selected: runMode,
                        onChanged: (v) { SfxService().toggle(); onRunModeChange(v); },
                      ),
                      _segmentRow(
                        label: S.distanceUnits,
                        sub: 'UNITS',
                        options: const ['km', 'mi'],
                        labels: const ['km', 'mi'],
                        selected: unit,
                        onChanged: (v) { SfxService().toggle(); onUnitChange(v); },
                      ),
                    ],
                  ),

                  _section(
                    num: '02',
                    title: S.isKo ? '러닝' : 'RUN',
                    children: [
                      _navRow(
                        label: S.isKo ? '러닝화' : 'Shoes',
                        sub: 'FOOTPRINTS',
                        value: _shoesSummary(),
                        onTap: () { SfxService().tapCard(); onShoesTap(); },
                      ),
                    ],
                  ),

                  _section(
                    num: '03',
                    title: S.isKo ? '목표' : 'GOAL',
                    children: [
                      _navRow(
                        label: S.isKo ? '활성 목표' : 'Active goal',
                        sub: 'BRIEF',
                        value: _goalSummary(),
                        accent: activeGoal != null,
                        onTap: () { SfxService().tapCard(); onGoalEditTap(); },
                      ),
                    ],
                  ),

                  _section(
                    num: '04',
                    title: S.isKo ? '오디오' : 'AUDIO',
                    children: [
                      _navRow(
                        label: S.isKo ? '나레이터 목소리' : 'Voice of Shadow',
                        sub: 'NARRATOR',
                        value: voiceLabel,
                        onTap: () { SfxService().tapCard(); onVoiceTap(); },
                      ),
                      _switchRow(
                        label: S.isKo ? '효과음' : 'Sound Effects',
                        sub: 'SUSPECT AUDIO',
                        value: sfxEnabled,
                        onChanged: onSfxToggle,
                      ),
                      _switchRow(
                        label: S.hapticDread,
                        sub: 'HAPTIC',
                        value: hapticEnabled,
                        onChanged: onHapticToggle,
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: BgmPreferences.I.enabled,
                        builder: (context, bgmOn, _) => _switchRow(
                          label: S.isKo ? '배경음' : 'Background Music',
                          sub: 'RADIO STATIC',
                          value: bgmOn,
                          onChanged: (v) => BgmPreferences.I.setEnabled(v),
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: BgmPreferences.I.enabled,
                        builder: (context, bgmOn, _) => ValueListenableBuilder<double>(
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
                          onChanged: (v) => BgmPreferences.I.setExternalMusicMode(v),
                        ),
                      ),
                    ],
                  ),

                  // FEAR (header tap -> admin)
                  _fearSection(),

                  // PRO
                  _proSection(),

                  // SUPPORT
                  _section(
                    num: '07',
                    title: S.isKo ? '지원' : 'SUPPORT',
                    children: [
                      _navRow(
                        label: S.isKo ? '개인정보 처리방침' : 'Privacy',
                        sub: 'CLASSIFIED FILES',
                        value: '',
                        onTap: () { SfxService().tapCard(); onPrivacyTap(); },
                      ),
                      _navRow(
                        label: S.isKo ? '이용 약관' : 'Terms of Service',
                        sub: 'CODE OF CONDUCT',
                        value: '',
                        onTap: () { SfxService().tapCard(); onTermsTap(); },
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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ============ TOP / TITLE ============

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { SfxService().tapCard(); onBack(); },
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Center(
                child: Text(
                  '‹  ${S.isKo ? "HOME" : "HOME"}',
                  style: GoogleFonts.oswald(
                    fontSize: 11,
                    color: _paperFade,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Transform.rotate(
          angle: 0.04,
          child: _stamp('PERSONNEL FILE'),
        ),
      ],
    );
  }

  Widget _titleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CASE FILE · §06',
          style: GoogleFonts.oswald(
            fontSize: 10,
            color: _brass,
            letterSpacing: 3.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          S.isKo ? 'Agent Profile' : 'Agent Profile',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 46,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: _paper,
            height: 0.95,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          color: _line,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'CREDENTIALS · BADGE · PREFS',
              style: GoogleFonts.oswald(
                fontSize: 9,
                color: _paperFade,
                letterSpacing: 3,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              _todayEn(),
              style: GoogleFonts.oswald(
                fontSize: 9,
                color: _paperFade,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stamp(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: _wine, width: 1)),
      child: Text(
        text,
        style: GoogleFonts.oswald(
          fontSize: 9,
          color: _wine,
          letterSpacing: 3,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ============ PROFILE CARD ============

  Widget _profileCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () { SfxService().tapCard(); onProfilePhotoTap(); },
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: _ink2,
          border: Border.all(color: _line, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _avatar(),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CODENAME · BADGE',
                        style: GoogleFonts.oswald(
                          fontSize: 9,
                          color: _paperFade,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userName.isEmpty
                            ? (S.isKo ? 'Agent ???' : 'Agent ???')
                            : 'Agent $userName',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 20,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                          color: _paper,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (isPro)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _wine,
                              ),
                              child: Text(
                                'PRO · MEMBER',
                                style: GoogleFonts.oswald(
                                  fontSize: 8,
                                  color: _paper,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: _brassDim, width: 1),
                              ),
                              child: Text(
                                'FIELD · ROOKIE',
                                style: GoogleFonts.oswald(
                                  fontSize: 8,
                                  color: _brass,
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hasProfilePhoto
                                  ? (S.isKo
                                      ? '사진 교체 · 맵 마커에 반영'
                                      : 'tap to replace · map marker')
                                  : (S.isKo
                                      ? '사진 등록 · 맵 마커 표시'
                                      : 'tap to capture · map marker'),
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.oswald(
                                fontSize: 9,
                                color: _paperFade,
                                letterSpacing: 1.8,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '›',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: _brass,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 0.5, color: _line),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _miniStat(shoes.length.toString(), 'SHOES')),
                Container(width: 0.5, height: 26, color: _line),
                Expanded(
                    child: _miniStat(horrorLevel.toString().padLeft(2, '0'),
                        'FEAR LV')),
                Container(width: 0.5, height: 26, color: _line),
                Expanded(child: _miniStat(isPro ? 'PRO' : 'FREE', 'GRADE')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String v, String k) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          v,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w700,
            color: _brass,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          k,
          style: GoogleFonts.oswald(
            fontSize: 8,
            color: _paperFade,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _avatar() {
    if (hasProfilePhoto && profilePhotoFile != null) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          border: Border.all(color: _brass, width: 1),
          image: DecorationImage(
            image: FileImage(profilePhotoFile!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _ink3,
        border: Border.all(color: _brass, width: 1),
      ),
      child: Text(
        _avatarChar(userName),
        style: GoogleFonts.cormorantGaramond(
          fontSize: 28,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w700,
          color: _paper,
        ),
      ),
    );
  }

  // ============ SECTIONS ============

  Widget _section({
    required String num,
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHead(num: num, title: title),
          ...children,
        ],
      ),
    );
  }

  Widget _sectionHead({required String num, required String title}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            '$num · $title',
            style: GoogleFonts.oswald(
              fontSize: 10,
              color: _brass,
              letterSpacing: 3.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 0.5, color: _line)),
          const SizedBox(width: 10),
          Text(
            '§$num',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: _paperFade,
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
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Text(
                    '05 · ${S.isKo ? "공포" : "FEAR"}',
                    style: GoogleFonts.oswald(
                      fontSize: 10,
                      color: _wine,
                      letterSpacing: 3.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Container(height: 0.5, color: _line)),
                  const SizedBox(width: 10),
                  Text(
                    '§05',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: _paperFade,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _horrorLevelRow(),
          _switchRow(
            label: S.entityAudio,
            sub: 'WHISPERS',
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
        sub: 'STATUS',
        value: isTrial
            ? '${S.isKo ? "체험" : "TRIAL"} · $trialDaysLeft${S.isKo ? "일" : "D"}'
            : (S.isKo ? '활성' : 'ACTIVE'),
        accent: true,
        onTap: () {},
      ));
      if (isTrial) {
        children.add(_navRow(
          label: S.upgradeToPro,
          sub: 'UNLOCK',
          value: '',
          accent: true,
          onTap: () { SfxService().tapCard(); onProUpgradeTap(); },
        ));
      }
    } else {
      children.add(_navRow(
        label: S.upgradeToPro,
        sub: 'UNLOCK ULTIMATE TERROR',
        value: '',
        accent: true,
        onTap: () { SfxService().tapCard(); onProUpgradeTap(); },
      ));
      if (!trialAlreadyUsed) {
        children.add(_navRow(
          label: S.startFreeTrial,
          sub: 'TRIAL',
          value: '',
          onTap: () { SfxService().tapCard(); onStartTrialTap(); },
        ));
      }
      children.add(_navRow(
        label: S.restorePurchases,
        sub: 'RESTORE',
        value: '',
        onTap: () { SfxService().tapCard(); onRestorePurchases(); },
      ));
    }
    return _section(
      num: '06',
      title: S.isKo ? '증표' : 'PRO',
      children: children,
    );
  }

  // ============ ROW WIDGETS ============

  Widget _navRow({
    required String label,
    required String sub,
    required String value,
    bool accent = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(child: _labelSub(label, sub)),
            if (value.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: accent ? _wine : _paperDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Text(
              '›',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 18,
                fontStyle: FontStyle.italic,
                color: _brassDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required String sub,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line, width: 0.5)),
      ),
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
              activeThumbColor: _brass,
              activeTrackColor: _brassDim.withValues(alpha: 0.5),
              inactiveThumbColor: _paperFade,
              inactiveTrackColor: _line,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line, width: 0.5)),
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
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 15,
                    fontStyle: FontStyle.italic,
                    color: _paper,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.oswald(
                    fontSize: 9,
                    color: _paperFade,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w400,
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
              activeThumbColor: _brass,
              activeTrackColor: _brassDim.withValues(alpha: 0.5),
              inactiveThumbColor: _paperFade,
              inactiveTrackColor: _line,
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
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _line, width: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                    child: _labelSub(
                        S.isKo ? '배경음 크기' : 'BGM Volume', 'VOLUME')),
                Text(
                  '$percent%',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontStyle: FontStyle.italic,
                    color: _brass,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _brass,
                inactiveTrackColor: _line,
                thumbColor: _paper,
                overlayColor: _brass.withValues(alpha: 0.15),
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
                onChangeEnd: enabled
                    ? (v) => BgmPreferences.I.setVolume(v)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentRow({
    required String label,
    required String sub,
    required List<String> options,
    required List<String> labels,
    List<bool>? locks,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final lockList = locks ?? List<bool>.filled(options.length, false);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _line, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelSub(label, sub),
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
                          color: isSelected ? _brass : _line,
                          width: 1,
                        ),
                        color: isSelected
                            ? const Color(0x22B89660)
                            : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            labels[i],
                            style: GoogleFonts.oswald(
                              fontSize: 10,
                              color: isSelected
                                  ? _brass
                                  : locked
                                      ? _paperFade
                                      : _paperDim,
                              letterSpacing: 2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (locked) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.lock, size: 9, color: _paperFade),
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
        border: Border(bottom: BorderSide(color: _line, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _labelSub(S.anxietyLevel, 'INTENSITY')),
              Text(
                horrorLevel.toString().padLeft(2, '0'),
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 34,
                  fontStyle: FontStyle.italic,
                  color: _wine,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _wine,
              inactiveTrackColor: _line,
              thumbColor: _paper,
              overlayColor: _wine.withValues(alpha: 0.2),
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
                      style: GoogleFonts.oswald(
                        fontSize: 10,
                        color: isActive ? _wine : _paperFade,
                        letterSpacing: 1.5,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.lock, size: 8, color: _paperFade),
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
          style: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: _paper,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            sub,
            style: GoogleFonts.oswald(
              fontSize: 9,
              color: _paperFade,
              letterSpacing: 2.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  // ============ FOOTER + NAV ============

  Widget _footer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        border: Border.all(color: _line, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'SHADOW RUN · FIELD AGENCY',
            style: GoogleFonts.oswald(
              fontSize: 9,
              color: _brass,
              letterSpacing: 3.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            versionLabel,
            textAlign: TextAlign.center,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: _paperFade,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.isKo
                ? '// 버전 ×7 탭 · 콜드케이스 열람'
                : '// tap ×7 to unlock the cold file',
            textAlign: TextAlign.center,
            style: GoogleFonts.oswald(
              fontSize: 8,
              color: _paperFade,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _ink,
        border: Border(top: BorderSide(color: _line, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _navItem('HOME', 'home', onTap: () {
                SfxService().tapCard();
                context.go('/');
              }),
              _navItem('FILES', 'archive', onTap: () {
                SfxService().tapCard();
                context.go('/history');
              }),
              _navItem('STATS', 'report', onTap: () {
                SfxService().tapCard();
                context.go('/analysis');
              }),
              _navItem('AGENT', 'profile', active: true, onTap: () {}),
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
    final color = active ? _brass : _paperFade;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              top,
              style: GoogleFonts.oswald(
                fontSize: 10,
                color: color,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              bottom,
              style: GoogleFonts.cormorantGaramond(
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

  static String _todayEn() {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final now = DateTime.now();
    return '${weekdays[now.weekday - 1]} · ${months[now.month - 1]} ${now.day}';
  }
}
