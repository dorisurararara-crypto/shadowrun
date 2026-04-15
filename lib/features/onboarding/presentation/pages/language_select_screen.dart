import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';

class LanguageSelectScreen extends StatelessWidget {
  const LanguageSelectScreen({super.key});

  Future<void> _selectLanguage(BuildContext context, String langCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', langCode);
    await prefs.setBool('language_selected', true);
    await S.init(langCode);
    if (context.mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SRColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Logo
              Text(
                'SHADOW RUN',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: SRColors.primary,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your language',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: SRColors.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const Spacer(),
              // Korean
              _LanguageButton(
                flag: '🇰🇷',
                title: '한국어',
                subtitle: 'Korean',
                onTap: () { SfxService().tapCard(); _selectLanguage(context, 'ko'); },
              ),
              const SizedBox(height: 16),
              // English
              _LanguageButton(
                flag: '🇺🇸',
                title: 'English',
                subtitle: '영어',
                onTap: () { SfxService().tapCard(); _selectLanguage(context, 'en'); },
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: SRColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SRColors.divider),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: SRColors.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: SRColors.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: SRColors.primaryContainer, size: 18),
          ],
        ),
      ),
    );
  }
}
