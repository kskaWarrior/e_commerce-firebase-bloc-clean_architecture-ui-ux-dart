import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:flutter/material.dart';

/// Holds the shopper app's active [BrandTokens] and lets them be swapped at
/// runtime — the store owner's saved branding (from the admin Settings page,
/// persisted on the store doc) overrides the compile-time palette without a
/// rebuild. Modelled on the singleton `AppLocaleController` pattern.
///
/// The admin console has its own fixed theme and does not use this.
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  BrandTokens _tokens = BrandTokens.light();

  /// The tokens the app should currently theme with.
  BrandTokens get tokens => _tokens;

  /// Applies a store `branding` map (hex color strings) on top of the
  /// compile-time brand palette. Blank/invalid entries are ignored so the
  /// brand's own default colour stands. Accepts 6- or 8-digit hex (with or
  /// without `#`); colours are forced opaque.
  void applyBranding(Map<String, dynamic>? branding) {
    final base = BrandTokens.light();
    if (branding == null || branding.isEmpty) {
      _set(base);
      return;
    }

    Color? parse(String key) {
      final raw = (branding[key] ?? '').toString().replaceAll('#', '').trim();
      if (raw.isEmpty) return null;
      final value = int.tryParse(raw, radix: 16);
      if (value == null) return null;
      return Color(0xFF000000 | (value & 0xFFFFFF));
    }

    _set(base.copyWith(
      primary: parse('primaryColorHex'),
      secondary: parse('secondaryColorHex'),
      background: parse('backgroundColorHex'),
    ));
  }

  /// Restores the compile-time brand palette.
  void reset() => _set(BrandTokens.light());

  void _set(BrandTokens tokens) {
    _tokens = tokens;
    notifyListeners();
  }
}
