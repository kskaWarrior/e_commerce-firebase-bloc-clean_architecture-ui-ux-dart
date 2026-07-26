class AppImages {
  static const String _basePath = 'assets/images/';

  // Brand-identity images: materialized by `dart run tool/activate_brand.dart
  // <brand>` from brands/<brand>/assets/ under fixed filenames.
  static const String _brandPath = 'assets/brand/';
  static const String brandLogo = '${_brandPath}logo.png';
  static const String brandWordmark = '${_brandPath}wordmark.png';
  static const String brandSplash = '${_brandPath}splash.png';
  // Portuguese variant of the splash art (translated tagline baked in).
  // Falls back to [brandSplash] when a brand ships no localized art.
  static const String brandSplashPt = '${_brandPath}splash_pt.png';

  // Main screens
  static const String appLogo = brandLogo;
  static const String appSplash = brandSplash;
  static const String appSplashPt = brandSplashPt;
  static const String forgotPassword = '${_basePath}forgot_password.png';
  static const String oneStep = '${_basePath}one-step.png';

  //misc
  static const String noResults = '${_basePath}no-results.png';

}
