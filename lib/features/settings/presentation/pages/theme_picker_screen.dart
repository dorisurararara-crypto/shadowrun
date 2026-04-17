import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/theme/app_theme_set.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

class ThemePickerScreen extends StatefulWidget {
  const ThemePickerScreen({super.key});

  @override
  State<ThemePickerScreen> createState() => _ThemePickerScreenState();
}

class _ThemePickerScreenState extends State<ThemePickerScreen> {
  @override
  void initState() {
    super.initState();
    PurchaseService().themesNotifier.addListener(_onUpdate);
    PurchaseService().proNotifier.addListener(_onUpdate);
    ThemeManager.I.themeIdNotifier.addListener(_onUpdate);
  }

  @override
  void dispose() {
    PurchaseService().themesNotifier.removeListener(_onUpdate);
    PurchaseService().proNotifier.removeListener(_onUpdate);
    ThemeManager.I.themeIdNotifier.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentId = ThemeManager.I.currentId;
    final purchase = PurchaseService();

    return Scaffold(
      backgroundColor: SRColors.background,
      appBar: AppBar(
        backgroundColor: SRColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: SRColors.onSurface),
        title: Text(
          '테마',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: SRColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          _header(),
          const SizedBox(height: 16),
          ...ThemeManager.all().map((t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _themeCard(
                theme: t,
                isSelected: t.id == currentId,
                canUse: purchase.canUseTheme(t.id),
                isPurchased: purchase.purchasedThemes.contains(t.id),
                isPro: purchase.isPro,
              ),
            );
          }),
          const SizedBox(height: 12),
          _restore(),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: SRColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SRColors.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Shadow',
            style: GoogleFonts.playfairDisplay(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: SRColors.primaryContainer,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '달리기의 무드를 바꾸세요. PRO 구매 시 모든 테마가 자동 해제됩니다.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: SRColors.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeCard({
    required AppThemeSet theme,
    required bool isSelected,
    required bool canUse,
    required bool isPurchased,
    required bool isPro,
  }) {
    final locked = !canUse;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        SfxService().tapCard();
        _onTapTheme(theme, canUse);
      },
      child: Container(
        decoration: BoxDecoration(
          color: SRColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? SRColors.primaryContainer : SRColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _preview(theme, locked: locked),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          theme.id.displayNameKo,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: SRColors.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      _badge(theme, canUse: canUse, isPurchased: isPurchased, isPro: isPro),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    theme.id.description,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: SRColors.onSurface.withValues(alpha: 0.55),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (isSelected)
                    _ctaApplied()
                  else if (theme.id.comingSoon)
                    _ctaComingSoon()
                  else if (canUse)
                    _ctaSelect(theme)
                  else
                    _ctaBuy(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview(AppThemeSet theme, {required bool locked}) {
    final p = theme.palette;
    return Stack(
      children: [
        Container(
          height: 96,
          decoration: BoxDecoration(
            color: p.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Stack(
            children: [
              if (theme.showHanjaWatermark)
                Positioned(
                  right: -18,
                  top: -10,
                  child: Text(
                    theme.hanjaSet.isNotEmpty ? theme.hanjaSet.first : '',
                    style: TextStyle(
                      fontFamily: 'Nanum Myeongjo',
                      fontSize: 110,
                      color: p.accent.withValues(alpha: 0.18),
                      height: 1,
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                top: 16,
                child: Text(
                  theme.tagline,
                  style: TextStyle(
                    fontFamily: theme.fonts.bodyFamily,
                    fontSize: 11,
                    color: p.accentSoft,
                    letterSpacing: 0.15,
                    fontStyle: theme.fonts.heroItalic ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 38,
                child: Text(
                  'SHADOW RUN',
                  style: TextStyle(
                    fontFamily: theme.fonts.heroFamily,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontStyle: theme.fonts.heroItalic ? FontStyle.italic : FontStyle.normal,
                    color: p.onSurface,
                    letterSpacing: -1,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '+312m',
                    style: TextStyle(
                      fontFamily: theme.fonts.numFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (locked)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: const Center(
                child: Icon(Icons.lock_outline, color: Colors.white70, size: 28),
              ),
            ),
          ),
      ],
    );
  }

  Widget _badge(AppThemeSet theme, {required bool canUse, required bool isPurchased, required bool isPro}) {
    if (theme.id.isFree) {
      return _chip('FREE', SRColors.tertiary);
    }
    if (theme.id.comingSoon) {
      return _chip('COMING', SRColors.onSurface.withValues(alpha: 0.4));
    }
    if (isPro) return _chip('PRO', SRColors.proBadge);
    if (isPurchased) return _chip('OWNED', SRColors.tertiary);
    return _chip('₩${theme.id.priceKrw.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    )}', SRColors.primaryContainer);
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _ctaApplied() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: SRColors.primaryContainer.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SRColors.primaryContainer, width: 1),
      ),
      child: Center(
        child: Text(
          '● 현재 적용됨',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: SRColors.primaryContainer,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _ctaSelect(AppThemeSet theme) {
    return ElevatedButton(
      onPressed: () => _applyTheme(theme.id),
      style: ElevatedButton.styleFrom(
        backgroundColor: SRColors.primaryContainer,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      child: Text(
        '이 테마로 바꾸기',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _ctaBuy(AppThemeSet theme) {
    return OutlinedButton(
      onPressed: () => _buyTheme(theme.id),
      style: OutlinedButton.styleFrom(
        foregroundColor: SRColors.primaryContainer,
        side: const BorderSide(color: SRColors.primaryContainer, width: 1),
        minimumSize: const Size.fromHeight(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        '구매 · ₩${theme.id.priceKrw.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        )}',
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }

  Widget _ctaComingSoon() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: SRColors.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SRColors.divider, width: 1),
      ),
      child: Center(
        child: Text(
          'COMING SOON',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: SRColors.onSurface.withValues(alpha: 0.4),
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _restore() {
    return TextButton(
      onPressed: () async {
        await PurchaseService().restorePurchases();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('구매 복원 요청됨'), backgroundColor: SRColors.surface),
          );
        }
      },
      child: Text(
        '구매 복원',
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SRColors.onSurface.withValues(alpha: 0.5),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _onTapTheme(AppThemeSet theme, bool canUse) async {
    if (theme.id == ThemeManager.I.currentId) return;
    if (theme.id.comingSoon) return;
    if (canUse) {
      await _applyTheme(theme.id);
    }
  }

  Future<void> _applyTheme(ThemeId id) async {
    SfxService().tapCard();
    await ThemeManager.I.setTheme(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${id.displayNameKo} 테마가 적용되었습니다.'),
          backgroundColor: SRColors.surface,
        ),
      );
    }
  }

  Future<void> _buyTheme(ThemeId id) async {
    SfxService().tapCard();
    final ok = await PurchaseService().buyTheme(id);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('구매를 시작할 수 없습니다. 잠시 후 다시 시도해주세요.'),
          backgroundColor: SRColors.surface,
        ),
      );
    }
  }
}
