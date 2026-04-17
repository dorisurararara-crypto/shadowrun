import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

/// T1 Pure Cinematic 테마 전용 설정 화면 레이아웃.
///
/// 무드: 순검정(#000) 위에 오프화이트(#F5F5F5)와 말린 피(#8B0000/#C83030).
/// 한글은 Noto Serif KR, 영문은 Playfair Display Italic.
/// FEAR 섹션 헤더가 공포 헤더 탭 대상 — [onHorrorHeaderTap] 이 실행되어
/// admin key 다이얼로그(기존 SettingsScreen 소유)가 뜬다. 이 로직은 건드리지 않는다.
class PureSettingsLayout extends StatelessWidget {
  final String userName;
  final bool isPro;
  final int horrorLevel;
  final VoidCallback onHorrorHeaderTap;
  final VoidCallback onThemeTap;
  final VoidCallback onBack;

  const PureSettingsLayout({
    super.key,
    required this.userName,
    required this.isPro,
    required this.horrorLevel,
    required this.onHorrorHeaderTap,
    required this.onThemeTap,
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
  static const _hair = Color(0x14F5F5F5); // rgba(245,245,245,0.08)

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
              rows: [
                _Row(
                  label: S.isKo ? '테마' : 'Theme',
                  sub: 'theme',
                  value: S.isKo ? '순정 시네마' : 'Pure Cinematic',
                  accent: true,
                  onTap: () { SfxService().tapCard(); onThemeTap(); },
                ),
                _Row(
                  label: S.isKo ? '언어' : 'Language',
                  sub: 'language',
                  value: S.isKo ? '한국어' : 'English',
                  onTap: () {}, // 언어 토글은 기본 설정에서.
                ),
              ],
            ),

            // AUDIO
            _section(
              title: 'Audio',
              rows: [
                _Row(
                  label: S.isKo ? '나레이터 목소리' : 'Narration voice',
                  sub: 'voice of shadow',
                  value: S.isKo ? '깊은 남성' : 'Deep · Male',
                  onTap: () {},
                ),
              ],
            ),

            // GAME
            _section(
              title: 'Game',
              rows: [
                _Row(
                  label: S.isKo ? '목표 설정' : 'Goal',
                  sub: 'goal',
                  value: S.isKo ? '주간 목표' : 'Weekly',
                  onTap: () {},
                ),
                _Row(
                  label: 'PRO',
                  sub: 'subscription',
                  value: isPro
                      ? (S.isKo ? '활성' : 'Active')
                      : (S.isKo ? '무료' : 'Free'),
                  accent: isPro,
                  onTap: () {},
                ),
              ],
            ),

            // FEAR — 탭 7회 트리거
            _fearSection(
              context: context,
              rows: [
                _Row(
                  label: S.isKo ? '공포 강도' : 'Horror level',
                  sub: 'intensity',
                  value: '${horrorLevel.toString().padLeft(2, '0')} / 10',
                  accent: true,
                  onTap: () {},
                ),
              ],
            ),

            // SUPPORT
            _section(
              title: 'Support',
              rows: [
                _Row(
                  label: S.isKo ? '리뷰 남기기' : 'Leave a review',
                  sub: 'review',
                  onTap: () {},
                ),
                _Row(
                  label: S.isKo ? '이용 약관' : 'Terms',
                  sub: 'terms',
                  onTap: () {},
                ),
                _Row(
                  label: S.isKo ? '개인정보 처리방침' : 'Privacy',
                  sub: 'privacy',
                  onTap: () {},
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

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () { SfxService().tapCard(); onBack(); },
            child: const SizedBox(
              height: 36,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: _BackLabel(),
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
        Container(
          width: 28,
          height: 1,
          color: _redEmber,
        ),
      ],
    );
  }

  Widget _profileCard() {
    return Container(
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
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: Border.all(color: _red, width: 1).toBoxDecoration(),
            child: Text(
              _avatarChar(userName),
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                color: _ink,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
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
                        userName.isEmpty ? (S.isKo ? '이름 없는 그림자' : 'Nameless shadow') : userName,
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
                  S.isKo ? '3월부터 · 28 챕터' : 'since march · 28 chapters',
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
    );
  }

  Widget _section({required String title, required List<_Row> rows}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(title),
          ..._renderRows(rows),
        ],
      ),
    );
  }

  Widget _fearSection({required BuildContext context, required List<_Row> rows}) {
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
          ..._renderRows(rows),
        ],
      ),
    );
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

  List<Widget> _renderRows(List<_Row> rows) {
    return [
      for (int i = 0; i < rows.length; i++)
        _row(rows[i], isLast: i == rows.length - 1),
    ];
  }

  Widget _row(_Row r, {required bool isLast}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: r.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast ? Colors.transparent : _hair,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    r.label,
                    style: GoogleFonts.notoSerifKr(
                      fontSize: 13,
                      color: _ink,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.13,
                    ),
                  ),
                  if (r.sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      r.sub,
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
              ),
            ),
            if (r.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  r.value,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 12,
                    color: r.accent ? _redSub : _inkDim,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.24,
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

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 10.5,
                color: _inkGhost,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.5,
                height: 1.7,
              ),
              children: [
                TextSpan(
                  text: 'v1.0.0',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 10.5,
                    color: _redEmber,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                    height: 1.7,
                  ),
                ),
                const TextSpan(text: '  ·  build 12'),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'tap × 7 to unlock',
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

  String _avatarChar(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '影';
    return trimmed.characters.first.toUpperCase();
  }
}

/// 섹션 내부 단일 행 정의.
class _Row {
  final String label;
  final String sub;
  final String value;
  final bool accent;
  final VoidCallback onTap;

  const _Row({
    required this.label,
    required this.sub,
    this.value = '',
    this.accent = false,
    required this.onTap,
  });
}

/// '← back' 라벨 — Playfair Italic.
class _BackLabel extends StatelessWidget {
  const _BackLabel();

  @override
  Widget build(BuildContext context) {
    return Text(
      S.isKo ? '‹  홈' : '‹  back',
      style: GoogleFonts.playfairDisplay(
        fontSize: 12,
        color: PureSettingsLayout._inkFade,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
      ),
    );
  }
}

extension _BorderBox on Border {
  BoxDecoration toBoxDecoration() => BoxDecoration(border: this);
}
