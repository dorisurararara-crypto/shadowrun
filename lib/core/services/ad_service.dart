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
  static const _realInterstitialId = 'ca-app-pub-8170207135799034/2917990766';

  static const _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const _testInterstitialId = 'ca-app-pub-3940256099942544/4411468910';

  static String get _bannerId => _useTestAds ? _testBannerId : _realBannerId;
  static String get _rewardedId => _useTestAds ? _testRewardedId : _realRewardedId;
  static String get _interstitialId => _useTestAds ? _testInterstitialId : _realInterstitialId;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  int _retryCount = 0;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialReady = false;
  int _interstitialRetry = 0;
  // Result 화면 누적 진입 카운터 (in-memory, 앱 재실행 시 reset).
  // 첫 결과는 광고 없이 깨끗하게 보여주고, 짝수 번째 결과부터 노출.
  int _resultViewCount = 0;

  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isInterstitialReady => _isInterstitialReady;

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
    loadInterstitialAd();
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

  /// 전면 광고 미리 로드. Result 화면 진입 시 시청 위해 백그라운드 로드.
  void loadInterstitialAd() {
    if (_interstitialRetry >= 3) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _interstitialRetry = 0;
          debugPrint('전면 광고 로드 완료');
        },
        onAdFailedToLoad: (error) {
          _isInterstitialReady = false;
          _interstitialRetry++;
          debugPrint('전면 광고 로드 실패: ${error.message}');
          Future.delayed(const Duration(seconds: 5), loadInterstitialAd);
        },
      ),
    );
  }

  /// Result 화면 진입 시 호출. 짝수 번째 진입에만 전면 광고 노출 (frequency cap).
  /// Pro 유저거나 광고 미준비면 no-op. 호출 측은 결과를 신경쓰지 않아도 됨.
  Future<void> maybeShowResultInterstitial() async {
    _resultViewCount++;
    // 첫 진입(1)·홀수 진입은 skip. 2,4,6번째에만 노출.
    if (_resultViewCount % 2 != 0) return;
    if (!_isInterstitialReady || _interstitialAd == null) {
      debugPrint('전면 광고 준비 안 됨 — skip');
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _isInterstitialReady = false;
        _interstitialRetry = 0;
        loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _isInterstitialReady = false;
        _interstitialRetry = 0;
        loadInterstitialAd();
      },
    );
    await _interstitialAd!.show();
    _interstitialAd = null;
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
