class PurchaseBackend {
  bool get configured => false;

  Future<void> initialize({
    required String apiKey,
    String? userId,
    required void Function(bool pro, bool plus) onState,
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async {}

  Future<Map<String, bool>> refresh({
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async => const {'pro': false, 'plus': false};

  Future<List<Map<String, Object?>>> loadPackages() async => const [];

  Future<Map<String, bool>?> buy(
    Object? nativePackage, {
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async => null;

  Future<Map<String, bool>?> restore({
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async => null;

  Future<Map<String, bool>?> logIn(
    String userId, {
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async => null;

  Future<Map<String, bool>?> logOut({
    required String proEntitlementId,
    required String plusEntitlementId,
  }) async => null;
}
