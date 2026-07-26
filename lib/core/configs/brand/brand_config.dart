/// Compile-time brand configuration for white-label builds.
///
/// Every value is injected at build time via
/// `--dart-define-from-file=brands/<brand>/brand.json`. Run and build
/// commands MUST pass that flag; [requireStoreId] enforces it at startup
/// so a build can never silently target the wrong tenant.
class BrandConfig {
  BrandConfig._();

  static const String brandId = String.fromEnvironment('BRAND_ID');
  static const String storeId = String.fromEnvironment('STORE_ID');
  static const String appName =
      String.fromEnvironment('APP_NAME', defaultValue: 'Store');
  static const bool hasWordmark =
      bool.fromEnvironment('HAS_WORDMARK', defaultValue: false);

  // Firebase app registration (per-brand apps inside the shared project).
  static const String firebaseAndroidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const String firebaseAndroidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const String firebaseIosAppId =
      String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String firebaseIosApiKey =
      String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const String firebaseWebAppId =
      String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String firebaseWebApiKey =
      String.fromEnvironment('FIREBASE_WEB_API_KEY');

  static const bool isConfigured = storeId != '';

  /// Tenant-safety gate: a shopper build without a STORE_ID would read and
  /// write the wrong tenant's data, so refuse to start instead.
  static void requireStoreId() {
    if (!isConfigured) {
      throw StateError(
        'Missing STORE_ID. Launch/build with '
        '--dart-define-from-file=brands/<brand>/brand.json '
        '(e.g. brands/buybuy/brand.json).',
      );
    }
  }
}
