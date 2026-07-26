class AppImages {
  static const String _basePath = 'assets/images/';

  // Brand-identity images: materialized by `dart run tool/activate_brand.dart
  // <brand>` from brands/<brand>/assets/ under fixed filenames.
  static const String _brandPath = 'assets/brand/';
  static const String brandLogo = '${_brandPath}logo.png';
  static const String brandWordmark = '${_brandPath}wordmark.png';
  static const String brandSplash = '${_brandPath}splash.png';

  // Main screens
  static const String appLogo = brandLogo;
  static const String appSplash = brandSplash;
  static const String forgotPassword = '${_basePath}forgot_password.png';
  static const String oneStep = '${_basePath}one-step.png';

  //misc
  static const String noResults = '${_basePath}no-results.png';

}
