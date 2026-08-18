import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const _proKey = 'entitlement_pro_v12';
  static const _plusKey = 'entitlement_plus_v12';
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
    await _loadLocal();
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
          _persist();
        },
      );
      await refresh();
    } catch (_) {}
  }

  Future<void> _loadLocal() async {
    // Local entitlement toggles exist only for debug/Chrome testing. Production
    // access is always rebuilt from RevenueCat CustomerInfo, which has its own
    // signed store receipt validation and offline cache.
    if (!kDebugMode) {
      _pro = false;
      _plus = false;
      notifyListeners();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _pro = prefs.getBool(_proKey) ?? false;
    _plus = prefs.getBool(_plusKey) ?? false;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_proKey, _pro);
      await prefs.setBool(_plusKey, _plus);
    }
    notifyListeners();
  }

  Future<void> _applyState(Map<String, bool>? state) async {
    if (state == null) return;
    _pro = state['pro'] ?? false;
    _plus = (state['plus'] ?? false) || _pro;
    await _persist();
  }

  Future<void> refresh() async {
    if (!configured) {
      await _loadLocal();
      return;
    }
    try {
      await _applyState(await _backend.refresh(
        proEntitlementId: AppConfig.proEntitlementId,
        plusEntitlementId: AppConfig.plusEntitlementId,
      ));
    } catch (_) {}
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
      return raw.map((e) => TxStorePackage(
        productId: e['productId']?.toString() ?? '',
        priceString: e['priceString']?.toString() ?? '',
        nativePackage: e['native'],
      )).where((e) => e.productId.isNotEmpty).toList();
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
    } catch (_) {}
  }


  Future<void> detachAccountIdentity() async {
    if (!configured) return;
    try {
      await _applyState(await _backend.logOut(
        proEntitlementId: AppConfig.proEntitlementId,
        plusEntitlementId: AppConfig.plusEntitlementId,
      ));
    } catch (_) {}
  }

  Future<void> setDebugEntitlements({required bool pro, required bool plus}) async {
    if (!kDebugMode) return;
    _pro = pro;
    _plus = plus || pro;
    await _persist();
  }
}
