/// Holds the tenant (store) the app is currently operating on.
///
/// Shopper builds seed this once at startup from [BrandConfig.storeId]
/// (compile-time). The admin web app sets it after login, from the store
/// owner's custom claim. All Firestore access must go through
/// [TenantCollections], which reads this context.
class StoreContext {
  String? _storeId;

  bool get isSet => _storeId != null && _storeId!.isNotEmpty;

  String get storeId {
    final id = _storeId;
    if (id == null || id.isEmpty) {
      throw StateError(
        'StoreContext is not set. Shopper builds must pass '
        '--dart-define-from-file=brands/<brand>/brand.json; the admin app '
        'sets it after owner login.',
      );
    }
    return id;
  }

  void set(String id) {
    if (id.isEmpty) {
      throw ArgumentError('storeId must not be empty');
    }
    _storeId = id;
  }

  void clear() {
    _storeId = null;
  }
}
