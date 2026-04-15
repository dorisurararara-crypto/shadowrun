import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  // 릴리즈 빌드에서만 실제 광고 ID 사용 (디버그/프로필은 테스트 ID)
  static final bool _useTestAds = !kReleaseMode;

  static const _realBannerId = 'ca-app-pub-8170207135799034/9789728281';
  static const _realRewardedId = 'ca-app-pub-8170207135799034/7163564942';

  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  static String get _bannerId => _useTestAds ? _testBannerId : _realBannerId;
  static String get _rewardedId => _useTestAds ? _testRewardedId : _realRewardedId;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  int _retryCount = 0;

  bool get isRewardedAdReady => _isRewardedAdReady;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  /// 보상형 광고 미리 로드
  void loadRewardedAd() {
    if (_retryCount >= 3) return;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _retryCount = 0;
          debugPrint('보상형 광고 로드 완료');
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
          _retryCount++;
          debugPrint('보상형 광고 로드 실패: ${error.message}');
          // 5초 후 재시도
          Future.delayed(const Duration(seconds: 5), loadRewardedAd);
        },
      ),
    );
  }

  /// 보상형 광고 표시 → 성공 시 onRewarded 콜백 실행
  Future<bool> showRewardedAd({required VoidCallback onRewarded}) async {
    if (!_isRewardedAdReady || _rewardedAd == null) {
      debugPrint('보상형 광고가 준비되지 않았습니다');
      // 재시도 한도 도달 후 사용자가 광고 시청 시도 시 리셋
      if (_retryCount >= 3) {
        _retryCount = 0;
        loadRewardedAd();
      }
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isRewardedAdReady = false;
        _retryCount = 0;
        loadRewardedAd(); // 다음 광고 미리 로드
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isRewardedAdReady = false;
        _retryCount = 0;
        loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('보상 획득: ${reward.amount} ${reward.type}');
        onRewarded();
      },
    );

    _rewardedAd = null;
    return true;
  }

  /// 배너 광고 생성 (결과 화면용)
  BannerAd createBannerAd({VoidCallback? onLoaded}) {
    return BannerAd(
      adUnitId: _bannerId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('배너 광고 로드 완료');
          onLoaded?.call();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('배너 광고 로드 실패: ${error.message}');
          ad.dispose();
        },
      ),
    );
  }
}
