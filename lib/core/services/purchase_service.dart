import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shadowrun/core/database/database_helper.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._();
  factory PurchaseService() => _instance;
  PurchaseService._();

  static const _proProductId = 'shadowrun_pro';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isPro = false;

  bool get isPro => _isPro;

  Future<void> initialize() async {
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

    // 저장된 PRO 상태 확인
    final savedPro = await DatabaseHelper.getSetting('is_pro');
    _isPro = savedPro == 'true';
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

  /// 구매 복원
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
