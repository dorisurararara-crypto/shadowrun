import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

/// T3 Korean Mystic Horror 테마 전용 설정 화면 레이아웃.
///
/// PureSettingsLayout과 동일한 props 시그니처를 가지되 먹빛/쌀빛/血 톤으로
/// 재해석한다. 섹션 헤더는 한자(貌·走·目·音·恐·證·助) + 한/영 라벨 조합.
///
/// 공포 섹션 헤더(`恐`)를 탭하면 [onHorrorHeaderTap]이 실행되어 상위
/// SettingsScreen이 admin key 다이얼로그를 띄운다. 이 로직은 건드리지 않는다.
class MysticSettingsLayout extends StatelessWidget {
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

  const MysticSettingsLayout({
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

  // Mystic 팔레트
  static const _ink = Color(0xFF050302);
  static const _rice = Color(0xFFF0EBE3);
  static const _riceDim = Color(0xFFA9A09A);
  static const _bloodDry = Color(0xFF7A0A0E);
  static const _bloodFresh = Color(0xFFC42029);
  static const _outline = Color(0xFF7A6858);
  static const _fade = Color(0xFF5A4840);
  static const _borderInk = Color(0xFF2A1518);
  static const _surface = Color(0xFF0A0606);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          // 배경 한자 워터마크 — 設
          const Positioned(
            right: -60,
            top: 80,
            child: IgnorePointer(
              child: Text(
                '設',
                style: TextStyle(
                  fontFamily: 'Nanum Myeongjo',
                  fontSize: 320,
                  color: Color(0x22B00A12),
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                left: 22,
                right: 22,
                bottom: 40,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _topBar(),
                  const SizedBox(height: 18),
                  _title(),
                  const SizedBox(height: 20),
                  _brushRule(),
                  const SizedBox(height: 18),
                  _profileCard(),
                  const SizedBox(height: 8),

                  // 貌 외관
                  _sectionHead(hanja: '貌', title: S.isKo ? '외 관' : 'APPEARANCE', en: 'APPEARANCE'),
                  _navRow(
                    label: S.isKo ? '테마' : 'Theme',
                    subLabel: 'T H E M E',
                    value: themeDisplayName,
                    onTap: () { SfxService().tapCard(); onThemeTap(); },
                  ),
                  _segmentRow(
                    label: S.isKo ? '언어' : 'Language',
                    subLabel: 'L A N G U A G E',
                    options: const ['ko', 'en'],
                    labels: const ['한국어', 'English'],
                    selected: langCode,
                    onChanged: (v) { SfxService().toggle(); onLangChange(v); },
                  ),
                  _segmentRow(
                    label: S.runMode,
                    subLabel: 'R U N   M O D E',
                    options: const ['fullmap', 'mapcenter', 'datacenter'],
                    labels: [S.fullMap, S.mapFocus, S.dataFocus],
                    locks: [false, !isPro, !isPro],
                    selected: runMode,
                    onChanged: (v) { SfxService().toggle(); onRunModeChange(v); },
                  ),
                  _segmentRow(
                    label: S.distanceUnits,
                    subLabel: 'U N I T S',
                    options: const ['km', 'mi'],
                    labels: const ['km', 'mi'],
                    selected: unit,
                    onChanged: (v) { SfxService().toggle(); onUnitChange(v); },
                  ),
                  const SizedBox(height: 14),

                  // 走 러닝
                  _sectionHead(hanja: '走', title: S.isKo ? '러 닝' : 'RUN', en: 'RUN'),
                  _navRow(
                    label: S.isKo ? '러닝화' : 'Shoes',
                    subLabel: 'F O O T P R I N T S',
                    value: _shoesSummary(),
                    onTap: () { SfxService().tapCard(); onShoesTap(); },
                  ),
                  const SizedBox(height: 14),

                  // 目 목표
                  _sectionHead(hanja: '目', title: S.isKo ? '목 표' : 'GOAL', en: 'GOAL'),
                  _navRow(
                    label: S.isKo ? '활성 목표' : 'Active goal',
                    subLabel: 'G O A L',
                    value: _goalSummary(),
                    valueColor: activeGoal != null ? _bloodFresh : _riceDim,
                    onTap: () { SfxService().tapCard(); onGoalEditTap(); },
                  ),
                  const SizedBox(height: 14),

                  // 音 소리
                  _sectionHead(hanja: '音', title: S.isKo ? '소 리' : 'AUDIO', en: 'AUDIO'),
                  _navRow(
                    label: S.isKo ? '나레이션 목소리' : 'Voice of Shadow',
                    subLabel: 'V O I C E',
                    value: voiceLabel,
                    onTap: () { SfxService().tapCard(); onVoiceTap(); },
                  ),
                  _switchRow(
                    label: S.isKo ? '효과음' : 'Sound Effects',
                    subLabel: 'S F X',
                    value: sfxEnabled,
                    onChanged: onSfxToggle,
                  ),
                  _switchRow(
                    label: S.hapticDread,
                    subLabel: 'H A P T I C',
                    value: hapticEnabled,
                    onChanged: onHapticToggle,
                  ),
                  const SizedBox(height: 14),

                  // 恐 공포 (탭 5회 -> admin key)
                  _horrorSectionHead(),
                  _horrorLevelRow(),
                  _switchRow(
                    label: S.entityAudio,
                    subLabel: 'W H I S P E R S',
                    value: ttsEnabled,
                    onChanged: onTtsToggle,
                  ),
                  const SizedBox(height: 14),

                  // 證 증표 (PRO)
                  _sectionHead(hanja: '證', title: S.isKo ? '증 표' : 'PRO', en: 'PRO'),
                  ..._proRows(),
                  const SizedBox(height: 14),

                  // 助 도움
                  _sectionHead(hanja: '助', title: S.isKo ? '도 움' : 'SUPPORT', en: 'SUPPORT'),
                  _navRow(
                    label: S.isKo ? '개인정보 처리방침' : 'Privacy Policy',
                    subLabel: 'P R I V A C Y',
                    value: '',
                    onTap: () { SfxService().tapCard(); onPrivacyTap(); },
                  ),
                  _navRow(
                    label: S.isKo ? '이용 약관' : 'Terms of Service',
                    subLabel: 'T E R M S',
                    value: '',
                    onTap: () { SfxService().tapCard(); onTermsTap(); },
                  ),

                  const SizedBox(height: 32),
                  _versionFooter(),
                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ======= TOP =======

  Widget _topBar() {
    return Row(
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () { SfxService().tapCard(); onBack(); },
          child: SizedBox(
            height: 32,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Center(
                child: Text(
                  S.isKo ? '‹  홈' : '‹  Home',
                  style: GoogleFonts.nanumMyeongjo(
                    fontSize: 13,
                    color: _outline,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        Text(
          '設',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 22,
            color: _bloodDry,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.isKo ? '설 정' : '설 정',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 40,
            color: _rice,
            height: 1.0,
            fontWeight: FontWeight.w800,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'S E T T I N G S',
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 11,
            color: _fade,
            letterSpacing: 5,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _brushRule() {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _bloodDry, Colors.transparent],
        ),
      ),
    );
  }

  // ======= PROFILE =======

  Widget _profileCard() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () { SfxService().tapCard(); onProfilePhotoTap(); },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          border: Border.all(color: _borderInk, width: 1),
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
                          style: GoogleFonts.nanumMyeongjo(
                            fontSize: 16,
                            color: _rice,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (isPro) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _bloodFresh,
                            border: Border.all(color: _bloodFresh, width: 1),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.nanumMyeongjo(
                              fontSize: 9,
                              color: _ink,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
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
                    style: GoogleFonts.gowunBatang(
                      fontSize: 11,
                      color: _fade,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 20,
                color: _outline,
                fontWeight: FontWeight.w400,
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
          shape: BoxShape.circle,
          border: Border.all(color: _bloodDry, width: 1),
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
        color: _ink,
        border: Border.all(color: _bloodDry, width: 1),
      ),
      child: Text(
        _avatarChar(userName),
        style: GoogleFonts.nanumMyeongjo(
          fontSize: 24,
          color: _rice,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ======= SECTION HEAD =======

  Widget _sectionHead({required String hanja, required String title, required String en}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 14),
      child: Row(
        children: [
          Text(
            hanja,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 18,
              color: _bloodDry,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 12,
              color: _rice,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 0.5, color: _borderInk)),
          const SizedBox(width: 10),
          Text(
            en,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 9,
              color: _fade,
              letterSpacing: 3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _horrorSectionHead() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onHorrorHeaderTap,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 14),
          child: Row(
            children: [
              Text(
                '恐',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 18,
                  color: _bloodFresh,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                S.isKo ? '공 포' : 'FEAR',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 12,
                  color: _rice,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 0.5, color: _borderInk)),
              const SizedBox(width: 10),
              Text(
                'F E A R',
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 9,
                  color: _fade,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======= ROWS =======

  Widget _navRow({
    required String label,
    required String subLabel,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _borderInk, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(child: _labelSub(label, subLabel)),
            if (value.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.gowunBatang(
                      fontSize: 12,
                      color: valueColor ?? _riceDim,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            Text(
              '›',
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 18,
                color: _outline,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required String subLabel,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _borderInk, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _labelSub(label, subLabel)),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: (v) {
                v ? SfxService().switchOn() : SfxService().switchOff();
                onChanged(v);
              },
              activeThumbColor: _bloodFresh,
              activeTrackColor: _bloodDry.withValues(alpha: 0.55),
              inactiveThumbColor: _outline,
              inactiveTrackColor: _borderInk,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segmentRow({
    required String label,
    required String subLabel,
    required List<String> options,
    required List<String> labels,
    List<bool>? locks,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    final lockList = locks ?? List<bool>.filled(options.length, false);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _borderInk, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _labelSub(label, subLabel),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
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
                          color: isSelected ? _bloodDry : _borderInk,
                          width: 1,
                        ),
                        color: isSelected ? const Color(0x22C42029) : Colors.transparent,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            labels[i],
                            style: GoogleFonts.nanumMyeongjo(
                              fontSize: 11,
                              color: isSelected
                                  ? _bloodFresh
                                  : locked
                                      ? _fade
                                      : _riceDim,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (locked) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.lock, size: 9, color: _fade),
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
        border: Border(
          bottom: BorderSide(color: _borderInk, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _labelSub(S.anxietyLevel, 'I N T E N S I T Y')),
              Text(
                horrorLevel.toString().padLeft(2, '0'),
                style: GoogleFonts.nanumMyeongjo(
                  fontSize: 28,
                  color: _bloodFresh,
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
              activeTrackColor: _bloodDry,
              inactiveTrackColor: _borderInk,
              thumbColor: _bloodFresh,
              overlayColor: _bloodDry.withValues(alpha: 0.2),
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
                      style: GoogleFonts.nanumMyeongjo(
                        fontSize: 10,
                        color: isActive ? _bloodFresh : _outline,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w400,
                      ),
                    ),
                    if (locked) ...[
                      const SizedBox(width: 2),
                      Icon(Icons.lock, size: 8, color: _fade),
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

  // ======= PRO ROWS =======

  List<Widget> _proRows() {
    final rows = <Widget>[];
    if (isPro) {
      rows.add(_navRow(
        label: S.isKo ? 'PRO 상태' : 'PRO status',
        subLabel: 'S T A T U S',
        value: isTrial
            ? '${S.isKo ? "체험" : "trial"} · $trialDaysLeft${S.isKo ? "일" : "d"}'
            : (S.isKo ? '활성' : 'active'),
        valueColor: _bloodFresh,
        onTap: () {},
      ));
      if (isTrial) {
        rows.add(_navRow(
          label: S.upgradeToPro,
          subLabel: 'U N L O C K',
          value: '',
          valueColor: _bloodFresh,
          onTap: () { SfxService().tapCard(); onProUpgradeTap(); },
        ));
      }
    } else {
      rows.add(_navRow(
        label: S.upgradeToPro,
        subLabel: S.unlockUltimateTerror.toUpperCase().split('').join(' '),
        value: '',
        valueColor: _bloodFresh,
        onTap: () { SfxService().tapCard(); onProUpgradeTap(); },
      ));
      if (!trialAlreadyUsed) {
        rows.add(_navRow(
          label: S.startFreeTrial,
          subLabel: 'T R I A L',
          value: '',
          onTap: () { SfxService().tapCard(); onStartTrialTap(); },
        ));
      }
      rows.add(_navRow(
        label: S.restorePurchases,
        subLabel: 'R E S T O R E',
        value: '',
        onTap: () { SfxService().tapCard(); onRestorePurchases(); },
      ));
    }
    return rows;
  }

  // ======= LABEL SUB =======

  Widget _labelSub(String label, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 14,
            color: _rice,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (sub.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            sub,
            style: GoogleFonts.nanumMyeongjo(
              fontSize: 9,
              color: _fade,
              letterSpacing: 2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }

  // ======= FOOTER =======

  Widget _versionFooter() {
    return Column(
      children: [
        Text(
          '影 × 七 回',
          textAlign: TextAlign.center,
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 13,
            color: _fade,
            letterSpacing: 8,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          S.isKo ? '× 7회 탭하여 잠금해제' : 'tap × 7 to unlock',
          textAlign: TextAlign.center,
          style: GoogleFonts.gowunBatang(
            fontSize: 10,
            color: _fade,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          versionLabel,
          textAlign: TextAlign.center,
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 10,
            color: _outline,
            letterSpacing: 2,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  // ======= HELPERS =======

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
