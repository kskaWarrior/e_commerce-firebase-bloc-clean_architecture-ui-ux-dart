/// Brand color palette, injected per-brand via --dart-define-from-file
/// (COLOR_* keys in `brands/<brand>/brand.json`). Defaults are the original
/// BuyBuy palette so a build without overrides is visually unchanged.
class BrandPalette {
  BrandPalette._();

  static int _parse(String hex, int fallback) {
    if (hex.isEmpty) return fallback;
    return int.tryParse(hex, radix: 16) ?? fallback;
  }

  // Light theme
  static final int primary =
      _parse(const String.fromEnvironment('COLOR_PRIMARY'), 0xFFFEBD2E);
  static final int primaryVariant = _parse(
      const String.fromEnvironment('COLOR_PRIMARY_VARIANT'), 0xFFF7A70C);
  static final int secondary =
      _parse(const String.fromEnvironment('COLOR_SECONDARY'), 0xFFE94B3C);
  static final int secondaryVariant = _parse(
      const String.fromEnvironment('COLOR_SECONDARY_VARIANT'), 0xFFB03028);
  static final int background =
      _parse(const String.fromEnvironment('COLOR_BACKGROUND'), 0xFFFFF9F0);
  static final int surface =
      _parse(const String.fromEnvironment('COLOR_SURFACE'), 0xFFE6F0F8);
  static final int error =
      _parse(const String.fromEnvironment('COLOR_ERROR'), 0xFFB00020);
  static final int onPrimary =
      _parse(const String.fromEnvironment('COLOR_ON_PRIMARY'), 0xFF000000);
  static final int onSecondary =
      _parse(const String.fromEnvironment('COLOR_ON_SECONDARY'), 0xFFFFFFFF);
  static final int onBackground =
      _parse(const String.fromEnvironment('COLOR_ON_BACKGROUND'), 0xFF000000);
  static final int onSurface =
      _parse(const String.fromEnvironment('COLOR_ON_SURFACE'), 0xFF000000);

  // Dark theme
  static final int darkPrimary =
      _parse(const String.fromEnvironment('COLOR_DARK_PRIMARY'), 0xFFFDC86E);
  static final int darkPrimaryVariant = _parse(
      const String.fromEnvironment('COLOR_DARK_PRIMARY_VARIANT'), 0xFFBF8C00);
  static final int darkSecondary =
      _parse(const String.fromEnvironment('COLOR_DARK_SECONDARY'), 0xFFFF7B6D);
  static final int darkSecondaryVariant = _parse(
      const String.fromEnvironment('COLOR_DARK_SECONDARY_VARIANT'),
      0xFFB24234);
  static final int darkBackground = _parse(
      const String.fromEnvironment('COLOR_DARK_BACKGROUND'), 0xFF121212);
  static final int darkSurface =
      _parse(const String.fromEnvironment('COLOR_DARK_SURFACE'), 0xFF1E1E1E);
  static final int darkError =
      _parse(const String.fromEnvironment('COLOR_DARK_ERROR'), 0xFFCF6679);
  static final int darkOnPrimary =
      _parse(const String.fromEnvironment('COLOR_DARK_ON_PRIMARY'), 0xFF000000);
  static final int darkOnSecondary = _parse(
      const String.fromEnvironment('COLOR_DARK_ON_SECONDARY'), 0xFF000000);
  static final int darkOnBackground = _parse(
      const String.fromEnvironment('COLOR_DARK_ON_BACKGROUND'), 0xFFFFFFFF);
  static final int darkOnSurface = _parse(
      const String.fromEnvironment('COLOR_DARK_ON_SURFACE'), 0xFFFFFFFF);
}
