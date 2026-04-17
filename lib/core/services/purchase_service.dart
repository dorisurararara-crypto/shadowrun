import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shadowrun/core/database/database_helper.dart';
import 'package:shadowrun/core/theme/theme_id.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  static const _proProductId = 'shadowrun_pro';
  static const _trialDays = 7;

  static const Map<String, ThemeId> _themeProductMap = {
    'shadowrun_theme_noir': ThemeId.filmNoir,
    'shadowrun_theme_mystic': ThemeId.koreanMystic,
    'shadowrun_theme_editorial': ThemeId.editorial,
    'shadowrun_theme_cyber': ThemeId.neoNoirCyber,
  };

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isPro = false;
  bool _isTrial = false;
  int _trialDaysLeft = 0;
  final Set<ThemeId> _purchasedThemes = {};

  /// PRO 상태 변경 알림 (UI 자동 갱신용)
  final ValueNotifier<bool> proNotifier = ValueNotifier(false);

  /// 테마 구매 상태 변경 알림
  final ValueNotifier<Set<ThemeId>> themesNotifier = ValueNotifier({});

  bool get isPro => _isPro;
  bool get isTrial => _isTrial;
  int get trialDaysLeft => _trialDaysLeft;
  Set<ThemeId> get purchasedThemes => Set.unmodifiable(_purchasedThemes);

  /// 테마 사용 가능 여부 — 무료 or PRO or 개별 구매됨
  bool canUseTheme(ThemeId id) {
    if (id.isFree) return true;
    if (id.comingSoon) return false;
    if (_isPro) return true;
    return _purchasedThemes.contains(id);
  }

  /// 관리자 키 등 외부에서 PRO 활성화 시 호출
  Future<void> activatePro() async {
    _isPro = true;
    proNotifier.value = true;
    await DatabaseHelper.setSetting('is_pro', 'true');
  }

  Future<void> initialize() async {
    // 저장된 PRO 상태를 항상 먼저 확인
    final savedPro = await DatabaseHelper.getSetting('is_pro');
    _isPro = savedPro == 'true';
    proNotifier.value = _isPro;

    // 개별 구매된 테마 목록 로드
    await _loadPurchasedThemes();

    // 무료체험 확인 (PRO 미구매 시에만)
    if (!_isPro) {
      await _checkTrial();
    }

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('인앱 결제 사용 불가');
      return;
    }

    // 구매 스트림 리스닝
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (error) => debugPrint('구매 스트림 에러: $error'),
    );
  }

  Future<void> _loadPurchasedThemes() async {
    _purchasedThemes.clear();
    for (final entry in _themeProductMap.entries) {
      final saved = await DatabaseHelper.getSetting('theme_purchased_${entry.value.key}');
      if (saved == 'true') _purchasedThemes.add(entry.value);
    }
    themesNotifier.value = Set.from(_purchasedThemes);
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == _proProductId) {
          _verifyAndActivatePro(purchase);
        } else if (_themeProductMap.containsKey(purchase.productID)) {
          _activateTheme(_themeProductMap[purchase.productID]!);
        }
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndActivatePro(PurchaseDetails purchase) async {
    _isPro = true;
    proNotifier.value = true;
    await DatabaseHelper.setSetting('is_pro', 'true');
    debugPrint('PRO 활성화 완료');
  }

  Future<void> _activateTheme(ThemeId id) async {
    _purchasedThemes.add(id);
    themesNotifier.value = Set.from(_purchasedThemes);
    await DatabaseHelper.setSetting('theme_purchased_${id.key}', 'true');
    debugPrint('테마 활성화 완료: ${id.key}');
  }

  /// 테마 구매
  Future<bool> buyTheme(ThemeId id) async {
    final pid = id.productId;
    if (pid == null || id.comingSoon) return false;

    final available = await _iap.isAvailable();
    if (!available) return false;

    final response = await _iap.queryProductDetails({pid});
    if (response.productDetails.isEmpty) {
      debugPrint('테마 상품을 찾을 수 없습니다: $pid');
      return false;
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('테마 구매 실패: $e');
      return false;
    }
  }

  /// PRO 구매
  Future<bool> buyPro() async {
    final available = await _iap.isAvailable();
    if (!available) return false;

    final response = await _iap.queryProductDetails({_proProductId});
    if (response.productDetails.isEmpty) {
      debugPrint('상품을 찾을 수 없습니다: $_proProductId');
      // Play Console에 상품이 등록되지 않은 경우
      return false;
    }

    final product = response.productDetails.first;
    final purchaseParam = PurchaseParam(productDetails: product);

    try {
      return await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      debugPrint('구매 실패: $e');
      return false;
    }
  }

  /// 무료체험 시작
  Future<bool> startTrial() async {
    final existing = await DatabaseHelper.getSetting('trial_start_date');
    if (existing != null) return false; // 이미 사용함
    final now = DateTime.now().toIso8601String().substring(0, 10);
    await DatabaseHelper.setSetting('trial_start_date', now);
    _isTrial = true;
    _isPro = true;
    _trialDaysLeft = _trialDays;
    proNotifier.value = true;
    return true;
  }

  Future<void> _checkTrial() async {
    final startStr = await DatabaseHelper.getSetting('trial_start_date');
    if (startStr == null) {
      _isTrial = false;
      return;
    }
    final start = DateTime.tryParse(startStr);
    if (start == null) {
      _isTrial = false;
      return;
    }
    final now = DateTime.now();
    final elapsed = now.difference(start).inDays;
    if (elapsed < _trialDays) {
      _isTrial = true;
      _isPro = true;
      _trialDaysLeft = _trialDays - elapsed;
    } else {
      _isTrial = false;
      _trialDaysLeft = 0;
    }
  }

  /// 구매 복원
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
