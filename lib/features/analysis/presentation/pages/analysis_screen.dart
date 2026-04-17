import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/theme/theme_id.dart';
import 'package:shadowrun/core/theme/theme_manager.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';
import 'package:shadowrun/core/services/sfx_service.dart';
import 'package:shadowrun/features/analysis/presentation/layouts/mystic_analysis_layout.dart';
import 'package:shadowrun/features/analysis/presentation/layouts/pure_analysis_layout.dart';
import 'package:shadowrun/features/analysis/presentation/widgets/analysis_dashboard.dart';
import 'package:shadowrun/features/history/presentation/widgets/analytics_overview.dart';

/// 분석 탭 — 테마별 레이아웃 분기.
/// - AnalysisDashboard 공통 위젯에 테마 팔레트 주입해 렌더
/// - PRO 전용: 락 걸린 경우 blur 오버레이 + 구매 유도
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    PurchaseService().proNotifier.addListener(_onProChanged);
  }

  @override
  void dispose() {
    PurchaseService().proNotifier.removeListener(_onProChanged);
    super.dispose();
  }

  void _onProChanged() {
    if (mounted) setState(() {});
  }

  void _goHome() {
    SfxService().tapCard();
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isPro = PurchaseService().isPro;

    return ValueListenableBuilder<ThemeId>(
      valueListenable: ThemeManager.I.themeIdNotifier,
      builder: (context, themeId, _) {
        if (themeId == ThemeId.koreanMystic) {
          return MysticAnalysisLayout(
            onClose: _goHome,
            locked: !isPro,
            proOverlay: !isPro ? _buildProOverlay() : null,
          );
        }
        if (themeId == ThemeId.pureCinematic) {
          return PureAnalysisLayout(
            onClose: _goHome,
            locked: !isPro,
            proOverlay: !isPro ? _buildProOverlay() : null,
          );
        }
        return _buildDefaultLayout(isPro);
      },
    );
  }

  Widget _buildDefaultLayout(bool isPro) {
    const palette = AnalyticsPalette(
      card: SRColors.card,
      border: Color(0xFF222222),
      text: SRColors.onSurface,
      muted: SRColors.neutral500,
      fade: Color(0xFF3A3A3A),
      accent: SRColors.primaryContainer,
      danger: SRColors.primaryContainer,
      numFamily: 'Space Grotesk',
      bodyFamily: 'Inter',
    );

    return Scaffold(
      backgroundColor: SRColors.background,
      appBar: AppBar(
        backgroundColor: SRColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: SRColors.onSurface),
          onPressed: _goHome,
        ),
        title: Text(
          S.isKo ? '분석' : 'ANALYSIS',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: SRColors.primary,
            letterSpacing: 1,
          ),
        ),
        centerTitle: false,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: const AnalysisDashboard(palette: palette),
          ),
          if (!isPro) _buildProOverlay(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildProOverlay() {
    return Positioned.fill(
      child: Container(
        color: SRColors.background.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: SRColors.proBadge, size: 48),
              const SizedBox(height: 16),
              Text('PRO', style: GoogleFonts.spaceGrotesk(
                fontSize: 28, fontWeight: FontWeight.w900, color: SRColors.proBadge, letterSpacing: 4,
              )),
              const SizedBox(height: 8),
              Text(
                S.isKo ? '러닝 분석은 PRO 전용 기능입니다' : 'Running analysis requires PRO',
                style: GoogleFonts.inter(fontSize: 14, color: SRColors.onSurface.withValues(alpha: 0.5)),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 200, height: 48,
                child: ElevatedButton(
                  onPressed: () => context.push('/settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF0044),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: Text(S.upgradeToPro, style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 2,
                  )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: SRColors.surface,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 8, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navIcon(Icons.directions_run, false, () { SfxService().tapCard(); context.go('/'); }),
          _navIcon(Icons.monitor_heart_outlined, false, () { SfxService().tapCard(); context.go('/history'); }),
          _navIcon(Icons.settings_outlined, false, () { SfxService().tapCard(); context.go('/settings'); }),
          _navIcon(Icons.analytics_outlined, true, () {}),
        ],
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: isActive ? SRColors.primaryContainer.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22,
          color: isActive ? SRColors.primaryContainer : SRColors.onSurface.withValues(alpha: 0.3)),
      ),
    );
  }
}
