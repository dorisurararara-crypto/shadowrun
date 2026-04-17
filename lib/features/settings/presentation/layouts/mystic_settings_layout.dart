import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

/// T3 Korean Mystic Horror 테마 전용 설정 화면 레이아웃.
///
/// 간소화 버전: 언어 / 테마 / 기본 설정(음성·효과음·목표) / PRO / 공포 트리거만 노출.
/// 공포 섹션 헤더(`恐`)를 5번 탭하면 [onHorrorHeaderTap] 이 실행되어
/// admin key 다이얼로그(기존 SettingsScreen 소유)가 뜬다. 이 로직은 건드리지 않는다.
class MysticSettingsLayout extends StatelessWidget {
  final String userName;
  final bool isPro;
  final int horrorLevel;
  final String versionLabel; // 예: "1.0.0 · 012"
  final VoidCallback onHorrorHeaderTap;
  final VoidCallback onThemeTap;
  final VoidCallback onLanguageToggle;
  final VoidCallback onVoiceTap;
  final VoidCallback onGoalTap;
  final VoidCallback onProTap;
  final VoidCallback onPrivacyTap;
  final VoidCallback onReviewTap;
  final VoidCallback onTermsTap;
  final VoidCallback onBack;

  const MysticSettingsLayout({
    super.key,
    required this.userName,
    required this.isPro,
    required this.horrorLevel,
    required this.versionLabel,
    required this.onHorrorHeaderTap,
    required this.onThemeTap,
    required this.onLanguageToggle,
    required this.onVoiceTap,
    required this.onGoalTap,
    required this.onProTap,
    required this.onPrivacyTap,
    required this.onReviewTap,
    required this.onTermsTap,
    required this.onBack,
  });

  static const _ink = Color(0xFF050302);
  static const _rice = Color(0xFFF0EBE3);
  static const _riceDim = Color(0xFFA9A09A);
  static const _bloodDry = Color(0xFF7A0A0E);
  static const _bloodFresh = Color(0xFFC42029);
  static const _outline = Color(0xFF7A6858);
  static const _fade = Color(0xFF5A4840);
  static const _borderInk = Color(0xFF2A1518);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _ink,
      body: Stack(
        children: [
          // 배경 워터마크 — 設
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
          SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 22,
              right: 22,
              bottom: 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _topBar(context),
                const SizedBox(height: 18),
                _title(),
                const SizedBox(height: 22),
                _brushRule(),
                const SizedBox(height: 16),
                _profileCard(),
                const SizedBox(height: 28),

                // 외관
                _sectionHead(hanja: '貌', title: '외 관', en: 'APPEARANCE'),
                _navRow(
                  label: S.isKo ? '테마' : 'Theme',
                  subLabel: 'T H E M E',
                  value: S.isKo ? '먹빛 호러' : 'Ink Horror',
                  onTap: () { SfxService().tapCard(); onThemeTap(); },
                ),
                _navRow(
                  label: S.isKo ? '언어' : 'Language',
                  subLabel: 'L A N G U A G E',
                  value: S.isKo ? '한국어' : 'English',
                  onTap: () { SfxService().toggle(); onLanguageToggle(); },
                ),
                const SizedBox(height: 24),

                // 소리
                _sectionHead(hanja: '音', title: '소 리', en: 'AUDIO'),
                _navRow(
                  label: S.isKo ? '나레이션 목소리' : 'Narration voice',
                  subLabel: 'V O I C E   O F   S H A D O W',
                  value: S.isKo ? '저음 · 남성' : 'Low · Male',
                  onTap: () { SfxService().tapCard(); onVoiceTap(); },
                ),
                const SizedBox(height: 24),

                // 게임
                _sectionHead(hanja: '戱', title: '게 임', en: 'GAME'),
                _navRow(
                  label: S.isKo ? '목표' : 'Goal',
                  subLabel: 'G O A L',
                  value: S.isKo ? '주간 목표' : 'Weekly',
                  onTap: () { SfxService().tapCard(); onGoalTap(); },
                ),
                _navRow(
                  label: 'PRO',
                  subLabel: 'S U B S C R I P T I O N',
                  value: isPro
                      ? (S.isKo ? '활성' : 'Active')
                      : (S.isKo ? '무료' : 'Free'),
                  valueColor: isPro ? _bloodFresh : _outline,
                  onTap: () { SfxService().tapCard(); onProTap(); },
                ),
                const SizedBox(height: 24),

                // 공포 (탭 5회 -> admin key)
                _horrorSectionHead(),
                _navRow(
                  label: S.isKo ? '공포 강도' : 'Horror level',
                  subLabel: 'I N T E N S I T Y',
                  value: '${horrorLevel.toString().padLeft(2, '0')} / 10',
                  valueColor: _bloodFresh,
                  onTap: () {}, // 강도 조절은 기본 설정에서. 여기는 표시만.
                ),
                const SizedBox(height: 24),

                // 도움
                _sectionHead(hanja: '助', title: '도 움', en: 'SUPPORT'),
                _navRow(
                  label: S.isKo ? '리뷰 남기기' : 'Leave a review',
                  subLabel: 'R E V I E W',
                  value: '',
                  onTap: () { SfxService().tapCard(); onReviewTap(); },
                ),
                _navRow(
                  label: S.isKo ? '이용약관' : 'Terms',
                  subLabel: 'T E R M S',
                  value: '',
                  onTap: () { SfxService().tapCard(); onTermsTap(); },
                ),
                _navRow(
                  label: S.isKo ? '개인정보 처리방침' : 'Privacy',
                  subLabel: 'P R I V A C Y',
                  value: '',
                  onTap: () { SfxService().tapCard(); onPrivacyTap(); },
                ),

                const SizedBox(height: 36),
                _versionFooter(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () { SfxService().tapCard(); onBack(); },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
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

  Widget _profileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0606),
        border: Border.all(color: _borderInk, width: 1),
      ),
      child: Row(
        children: [
          // 影 아바타
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ink,
              border: Border.all(color: _bloodDry, width: 1),
            ),
            child: Text(
              '影',
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 24,
                color: _rice,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName.isEmpty ? (S.isKo ? '이름 없는 그림자' : 'Nameless shadow') : userName,
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
                  S.isKo ? '제 028 밤 · 그림자와 함께' : 'Night 028 · with the shadow',
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
    );
  }

  Widget _sectionHead({required String hanja, required String title, required String en}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
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
          Expanded(
            child: Container(height: 0.5, color: _borderInk),
          ),
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

  /// 공포 섹션 헤더 — 5번 탭 트리거. onHorrorHeaderTap 로직은 상위에서 관리.
  Widget _horrorSectionHead() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onHorrorHeaderTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 2),
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
              S.isKo ? '공 포' : 'HORROR',
              style: GoogleFonts.nanumMyeongjo(
                fontSize: 12,
                color: _rice,
                letterSpacing: 2,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(height: 0.5, color: _borderInk),
            ),
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
    );
  }

  Widget _navRow({
    required String label,
    required String subLabel,
    required String value,
    Color? valueColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: _borderInk, width: 0.5, style: BorderStyle.solid),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.nanumMyeongjo(
                      fontSize: 14,
                      color: _rice,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subLabel.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subLabel,
                      style: GoogleFonts.nanumMyeongjo(
                        fontSize: 9,
                        color: _fade,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  value,
                  style: GoogleFonts.gowunBatang(
                    fontSize: 12,
                    color: valueColor ?? _riceDim,
                    fontWeight: FontWeight.w400,
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

  Widget _versionFooter() {
    return Column(
      children: [
        Text(
          '影 影 影 影 影 影 影',
          textAlign: TextAlign.center,
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 12,
            color: _fade,
            letterSpacing: 8,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'tap × 7 to unlock',
          textAlign: TextAlign.center,
          style: GoogleFonts.nanumMyeongjo(
            fontSize: 9,
            color: _fade,
            letterSpacing: 3,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'v$versionLabel',
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
}
