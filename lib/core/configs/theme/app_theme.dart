import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const String light = 'light';
  static const String dark = 'dark';
  static const String system = 'system';

  static const List<String> themes = [light, dark, system];

  static String get defaultTheme => light;

  /// Neutral per-brand font family. The actual font files are registered in
  /// pubspec under this name so swapping a brand's font never touches code.
  static const String fontFamily = 'BrandFont';

  static ThemeData _build(BrandTokens tokens, Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      fontFamily: fontFamily,
      primaryColor: tokens.primary,
      primaryColorDark: tokens.primaryVariant,
      extensions: [tokens],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: tokens.primary,
        onPrimary: tokens.onPrimary,
        secondary: tokens.secondary,
        onSecondary: tokens.onSecondary,
        surface: tokens.surface,
        onSurface: tokens.onSurface,
        error: tokens.error,
        onError: brightness == Brightness.light ? Colors.white : Colors.black,
      ),
      scaffoldBackgroundColor: tokens.background,
      appBarTheme: AppBarTheme(
        backgroundColor: tokens.primary,
        foregroundColor: tokens.onPrimary,
        elevation: 0,
      ),
    );
  }

  /// Builds a light theme from runtime tokens (used by [ThemeController] so a
  /// store's saved branding themes the app without a rebuild).
  static ThemeData buildLight(BrandTokens tokens) =>
      _build(tokens, Brightness.light);

  static final ThemeData lightTheme =
      _build(BrandTokens.light(), Brightness.light);

  static final ThemeData darkTheme =
      _build(BrandTokens.dark(), Brightness.dark);

  static ThemeData getTheme(String theme) {
    switch (theme) {
      case dark:
        return darkTheme;
      case light:
        return lightTheme;
      default:
        return lightTheme;
    }
  }
}
