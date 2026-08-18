import 'package:purchases_flutter/purchases_flutter.dart';

class PurchaseBackend {
  bool _configured = false;
  bool get configured => _configured;

  Map<String, bool> _state(CustomerInfo info, String proId, String plusId) {
    final active = info.entitlements.active;
    final pro = active.containsKey(proId);
    final plus = active.containsKey(plusId) || pro;
    return {'pro': pro, 'plus': plus};
  }

  Future<void> initialize({
    required String apiKey,
    String? userId,
    required void Function(bool pro, bool plus) onState,
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async {
    if (apiKey.isEmpty) return;
    final config = PurchasesConfiguration(apiKey);
    if (userId != null && userId.isNotEmpty) config.appUserID = userId;
    await Purchases.configure(config);
    _configured = true;
    Purchases.addCustomerInfoUpdateListener((info) {
      final s = _state(info, proEntitlementId, plusEntitlementId);
      onState(s['pro'] ?? false, s['plus'] ?? false);
    });
  }

  Future<Map<String, bool>> refresh({
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async {
    if (!_configured) return const {'pro': false, 'plus': false};
    final info = await Purchases.getCustomerInfo();
    return _state(info, proEntitlementId, plusEntitlementId);
  }

  Future<List<Map<String, Object?>>> loadPackages() async {
    if (!_configured) return const [];
    final offerings = await Purchases.getOfferings();
    final list = offerings.current?.availablePackages ?? <Package>[];
    return list.map((p) => <String, Object?>{
      'productId': p.storeProduct.identifier,
      'priceString': p.storeProduct.priceString,
      'native': p,
    }).toList();
  }

  Future<Map<String, bool>?> buy(
    Object? nativePackage, {
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async {
    if (!_configured || nativePackage is! Package) return null;
    final purchaseParams = PurchaseParams.package(nativePackage);
    final result = await Purchases.purchase(purchaseParams);
    return _state(result.customerInfo, proEntitlementId, plusEntitlementId);
  }

  Future<Map<String, bool>?> restore({
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async {
    if (!_configured) return null;
    final info = await Purchases.restorePurchases();
    return _state(info, proEntitlementId, plusEntitlementId);
  }

  Future<Map<String, bool>?> logIn(
    String userId, {
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async {
    if (!_configured || userId.isEmpty) return null;
    final result = await Purchases.logIn(userId);
    return _state(result.customerInfo, proEntitlementId, plusEntitlementId);
  }

  Future<Map<String, bool>?> logOut({
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async {
    if (!_configured) return null;
    final info = await Purchases.logOut();
    return _state(info, proEntitlementId, plusEntitlementId);
  }

}
