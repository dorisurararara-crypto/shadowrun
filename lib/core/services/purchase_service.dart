import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shadowrun/core/database/database_helper.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  static const _proProductId = 'shadowrun_pro';
  static const _trialDays = 7;

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isPro = false;
  bool _isTrial = false;
  int _trialDaysLeft = 0;

  bool get isPro => _isPro;
  bool get isTrial => _isTrial;
  int get trialDaysLeft => _trialDaysLeft;

  /// 관리자 키 등 외부에서 PRO 활성화 시 호출
  Future<void> activatePro() async {
    _isPro = true;
    await DatabaseHelper.setSetting('is_pro', 'true');
  }

  Future<void> initialize() async {
    // 저장된 PRO 상태를 항상 먼저 확인
    final savedPro = await DatabaseHelper.getSetting('is_pro');
    _isPro = savedPro == 'true';

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

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == _proProductId) {
          _verifyAndActivatePro(purchase);
        }
      }

      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  Future<void> _verifyAndActivatePro(PurchaseDetails purchase) async {
    // 로컬 앱에서는 영수증 서버 검증 없이 바로 활성화
    // 프로덕션에서는 서버 검증 추가 권장
    _isPro = true;
    await DatabaseHelper.setSetting('is_pro', 'true');
    debugPrint('PRO 활성화 완료');
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
