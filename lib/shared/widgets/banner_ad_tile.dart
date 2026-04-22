import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shadowrun/core/services/ad_service.dart';
import 'package:shadowrun/core/services/purchase_service.dart';
import 'package:shadowrun/core/theme/app_theme.dart';
import 'package:shadowrun/core/l10n/app_strings.dart';

/// 재사용 가능한 배너 광고 타일. Pro 유저면 SizedBox.shrink 반환.
/// 로드 실패 / 로딩 중에도 SizedBox.shrink — 레이아웃 흔들림 없음.
///
/// 사용처:
/// - History 화면 하단
/// - Analysis 화면 하단
/// - (Result 화면은 자체 BannerAd 관리 — 이 위젯 사용 안 함)
class BannerAdTile extends StatefulWidget {
  /// 광고 아래에 "PRO 유저는 광고가 표시되지 않습니다" 힌트 렌더 여부.
  final bool showProHint;

  const BannerAdTile({super.key, this.showProHint = true});

  @override
  State<BannerAdTile> createState() => _BannerAdTileState();
}

class _BannerAdTileState extends State<BannerAdTile> {
  BannerAd? _ad;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    if (PurchaseService().isPro) return;
    _ad = AdService().createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _ready = true);
      },
    );
    _ad?.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PurchaseService().isPro || !_ready || _ad == null) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          alignment: Alignment.center,
          width: _ad!.size.width.toDouble(),
          height: _ad!.size.height.toDouble(),
          child: AdWidget(ad: _ad!),
        ),
        if (widget.showProHint) ...[
          const SizedBox(height: 6),
          Text(
            S.proNoAds,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: SRColors.proBadge.withValues(alpha: 0.5),
              letterSpacing: 0.5,
            ),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}
