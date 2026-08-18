import 'package:flutter/foundation.dart';
import '../core/app_config.dart';
import 'supabase_service.dart';
import 'purchases/purchase_backend_stub.dart'
    if (dart.library.io) 'purchases/purchase_backend_revenuecat.dart';

class TxStorePackage {
  final String productId;
  final String priceString;
  final Object? nativePackage;
  const TxStorePackage({required this.productId, required this.priceString, this.nativePackage});
}

class EntitlementService extends ChangeNotifier {
  EntitlementService._();
  static final instance = EntitlementService._();

  final PurchaseBackend _backend = PurchaseBackend();
  bool _pro = false;
  bool _plus = false;

  bool get pro => _pro;
  bool get plus => _plus || _pro;
  bool get adFree => plus;
  bool get configured => _backend.configured;

  String get _apiKey {
    if (kIsWeb) return '';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => AppConfig.revenueCatAndroidKey,
      TargetPlatform.iOS => AppConfig.revenueCatIosKey,
      _ => '',
    };
  }

  Future<void> initialize() async {
    // Every launch starts from Free. Paid state is restored only from the
    // verified store/RevenueCat state; stale local debug flags are never trusted.
    _pro = false;
    _plus = false;
    notifyListeners();

    if (kIsWeb || _apiKey.isEmpty) return;
    try {
      final uid = SupabaseService.client?.auth.currentUser?.id;
      await _backend.initialize(
        apiKey: _apiKey,
        userId: uid,
        proEntitlementId: AppConfig.proEntitlementId,
        plusEntitlementId: AppConfig.plusEntitlementId,
        onState: (pro, plus) {
          _pro = pro;
          _plus = plus || pro;
          notifyListeners();
        },
      );
      await refresh();
    } catch (_) {
      _pro = false;
      _plus = false;
      notifyListeners();
    }
  }

  Future<void> _applyState(Map<String, bool>? state) async {
    if (state == null) {
      _pro = false;
      _plus = false;
    } else {
      _pro = state['pro'] ?? false;
      _plus = (state['plus'] ?? false) || _pro;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (!configured) {
      _pro = false;
      _plus = false;
      notifyListeners();
      return;
    }
    try {
      await _applyState(await _backend.refresh(
        proEntitlementId: AppConfig.proEntitlementId,
        plusEntitlementId: AppConfig.plusEntitlementId,
      ));
    } catch (_) {
      _pro = false;
      _plus = false;
      notifyListeners();
    }
  }

  Future<bool> currentPro() async {
    await refresh();
    return _pro;
  }

  Future<bool> currentPlus() async {
    await refresh();
    return plus;
  }

  Future<bool> currentAdFree() async => currentPlus();

  Future<List<TxStorePackage>> loadPackages() async {
    if (!configured) return [];
    try {
      final raw = await _backend.loadPackages();
      return raw
          .map((e) => TxStorePackage(
                productId: e['productId']?.toString() ?? '',
                priceString: e['priceString']?.toString() ?? '',
                nativePackage: e['native'],
              ))
          .where((e) => e.productId.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<bool> buyPackage(TxStorePackage package) async {
    if (!configured) return false;
    try {
      final state = await _backend.buy(
        package.nativePackage,
        proEntitlementId: AppConfig.proEntitlementId,
        plusEntitlementId: AppConfig.plusEntitlementId,
      );
      if (state == null) return false;
      await _applyState(state);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> restore() async {
    if (!configured) return false;
    try {
      final state = await _backend.restore(
        proEntitlementId: AppConfig.proEntitlementId,
        plusEntitlementId: AppConfig.plusEntitlementId,
      );
      if (state == null) return false;
      await _applyState(state);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> identifySupabaseUser() async {
    if (!configured) return;
    final uid = SupabaseService.client?.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return;
    try {
      await _applyState(await _backend.logIn(
        uid,
        proEntitlementId: AppConfig.proEntitlementId,
        plusEntitlementId: AppConfig.plusEntitlementId,
      ));
    } catch (_) {
      _pro = false;
      _plus = false;
      notifyListeners();
    }
  }

  Future<void> detachAccountIdentity() async {
    if (!configured) {
      _pro = false;
      _plus = false;
      notifyListeners();
      return;
    }
    try {
      await _applyState(await _backend.logOut(
        proEntitlementId: AppConfig.proEntitlementId,
        plusEntitlementId: AppConfig.plusEntitlementId,
      ));
    } catch (_) {
      _pro = false;
      _plus = false;
      notifyListeners();
    }
  }

  // Kept only so older debug-only store UI references still compile.
  // It intentionally never grants paid access: debug and release both remain
  // Free unless RevenueCat/store verification returns a real entitlement.
  Future<void> setDebugEntitlements({required bool pro, required bool plus}) async {
    _pro = false;
    _plus = false;
    notifyListeners();
  }
}
