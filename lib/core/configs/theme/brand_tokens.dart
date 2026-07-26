import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_palette.dart';
import 'package:flutter/material.dart';

/// Semantic color tokens for white-label theming.
///
/// Widgets must use `context.brand.<token>` instead of hardcoded
/// `Color(...)`/`Colors.*` so every brand's palette flows through the app.
/// Palette tokens come from [BrandPalette] (per-brand dart-defines);
/// semantic neutrals (success/danger/muted/...) are shared across brands
/// unless a future brand key overrides them.
///
/// [BrandTokens.fromPalette] is the seam for later runtime theming: a
/// ThemeCubit could rebuild the ThemeData from the Firestore store doc
/// without touching any widget.
@immutable
class BrandTokens extends ThemeExtension<BrandTokens> {
  const BrandTokens({
    required this.primary,
    required this.onPrimary,
    required this.primaryVariant,
    required this.secondary,
    required this.secondaryVariant,
    required this.onSecondary,
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.textPrimary,
    required this.textInverse,
    required this.iconStrong,
    required this.success,
    required this.successStrong,
    required this.danger,
    required this.dangerStrong,
    required this.dangerSoft,
    required this.warning,
    required this.info,
    required this.shipped,
    required this.muted,
    required this.mutedSoft,
    required this.surfaceBright,
    required this.splashBackground,
  });

  final Color primary;
  final Color onPrimary;
  final Color primaryVariant;
  final Color secondary;
  final Color secondaryVariant;
  final Color onSecondary;
  final Color background;
  final Color surface;
  final Color onSurface;
  final Color error;

  /// Default text/icon color on light surfaces.
  final Color textPrimary;

  /// Text/icon color on dark or colored surfaces.
  final Color textInverse;

  /// Strong accent for icons (originally the BuyBuy navy).
  final Color iconStrong;

  final Color success;
  final Color successStrong;
  final Color danger;
  final Color dangerStrong;
  final Color dangerSoft;
  final Color warning;
  final Color info;

  /// Order-status accent for "shipped".
  final Color shipped;

  final Color muted;
  final Color mutedSoft;

  /// Bright card/sheet background (white in the default brand).
  final Color surfaceBright;

  final Color splashBackground;

  factory BrandTokens.fromPalette(Map<String, int> palette) {
    Color pick(String key, int fallback) =>
        Color(palette[key] ?? fallback);
    return BrandTokens(
      primary: pick('primary', 0xFFFEBD2E),
      onPrimary: pick('onPrimary', 0xFF000000),
      primaryVariant: pick('primaryVariant', 0xFFF7A70C),
      secondary: pick('secondary', 0xFFE94B3C),
      secondaryVariant: pick('secondaryVariant', 0xFFB03028),
      onSecondary: pick('onSecondary', 0xFFFFFFFF),
      background: pick('background', 0xFFFFF9F0),
      surface: pick('surface', 0xFFE6F0F8),
      onSurface: pick('onSurface', 0xFF000000),
      error: pick('error', 0xFFB00020),
      textPrimary: pick('textPrimary', 0xFF000000),
      textInverse: pick('textInverse', 0xFFFFFFFF),
      iconStrong: pick('iconStrong', 0xFF0A2035),
      success: pick('success', 0xFF4CAF50),
      successStrong: pick('successStrong', 0xFF388E3C),
      danger: pick('danger', 0xFFF44336),
      dangerStrong: pick('dangerStrong', 0xFFD32F2F),
      dangerSoft: pick('dangerSoft', 0xFFFF8B8B),
      warning: pick('warning', 0xFFEF6C00),
      info: pick('info', 0xFF1976D2),
      shipped: pick('shipped', 0xFF5E35B1),
      muted: pick('muted', 0xFF9E9E9E),
      mutedSoft: pick('mutedSoft', 0xFFE0E0E0),
      surfaceBright: pick('surfaceBright', 0xFFFFFFFF),
      splashBackground: pick('splashBackground', 0xFF372D1E),
    );
  }

  factory BrandTokens.light() => BrandTokens.fromPalette({
        'primary': BrandPalette.primary,
        'onPrimary': BrandPalette.onPrimary,
        'primaryVariant': BrandPalette.primaryVariant,
        'secondary': BrandPalette.secondary,
        'secondaryVariant': BrandPalette.secondaryVariant,
        'onSecondary': BrandPalette.onSecondary,
        'background': BrandPalette.background,
        'surface': BrandPalette.surface,
        'onSurface': BrandPalette.onSurface,
        'error': BrandPalette.error,
        'textPrimary': BrandPalette.onBackground,
      });

  factory BrandTokens.dark() => BrandTokens.fromPalette({
        'primary': BrandPalette.darkPrimary,
        'onPrimary': BrandPalette.darkOnPrimary,
        'primaryVariant': BrandPalette.darkPrimaryVariant,
        'secondary': BrandPalette.darkSecondary,
        'secondaryVariant': BrandPalette.darkSecondaryVariant,
        'onSecondary': BrandPalette.darkOnSecondary,
        'background': BrandPalette.darkBackground,
        'surface': BrandPalette.darkSurface,
        'onSurface': BrandPalette.darkOnSurface,
        'error': BrandPalette.darkError,
        'textPrimary': BrandPalette.darkOnBackground,
        'textInverse': 0xFF000000,
        'surfaceBright': BrandPalette.darkSurface,
        'splashBackground': BrandPalette.darkBackground,
      });

  @override
  BrandTokens copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryVariant,
    Color? secondary,
    Color? secondaryVariant,
    Color? onSecondary,
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? error,
    Color? textPrimary,
    Color? textInverse,
    Color? iconStrong,
    Color? success,
    Color? successStrong,
    Color? danger,
    Color? dangerStrong,
    Color? dangerSoft,
    Color? warning,
    Color? info,
    Color? shipped,
    Color? muted,
    Color? mutedSoft,
    Color? surfaceBright,
    Color? splashBackground,
  }) {
    return BrandTokens(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryVariant: primaryVariant ?? this.primaryVariant,
      secondary: secondary ?? this.secondary,
      secondaryVariant: secondaryVariant ?? this.secondaryVariant,
      onSecondary: onSecondary ?? this.onSecondary,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      onSurface: onSurface ?? this.onSurface,
      error: error ?? this.error,
      textPrimary: textPrimary ?? this.textPrimary,
      textInverse: textInverse ?? this.textInverse,
      iconStrong: iconStrong ?? this.iconStrong,
      success: success ?? this.success,
      successStrong: successStrong ?? this.successStrong,
      danger: danger ?? this.danger,
      dangerStrong: dangerStrong ?? this.dangerStrong,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      shipped: shipped ?? this.shipped,
      muted: muted ?? this.muted,
      mutedSoft: mutedSoft ?? this.mutedSoft,
      surfaceBright: surfaceBright ?? this.surfaceBright,
      splashBackground: splashBackground ?? this.splashBackground,
    );
  }

  @override
  BrandTokens lerp(ThemeExtension<BrandTokens>? other, double t) {
    if (other is! BrandTokens) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? b;
    return BrandTokens(
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primaryVariant: mix(primaryVariant, other.primaryVariant),
      secondary: mix(secondary, other.secondary),
      secondaryVariant: mix(secondaryVariant, other.secondaryVariant),
      onSecondary: mix(onSecondary, other.onSecondary),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      onSurface: mix(onSurface, other.onSurface),
      error: mix(error, other.error),
      textPrimary: mix(textPrimary, other.textPrimary),
      textInverse: mix(textInverse, other.textInverse),
      iconStrong: mix(iconStrong, other.iconStrong),
      success: mix(success, other.success),
      successStrong: mix(successStrong, other.successStrong),
      danger: mix(danger, other.danger),
      dangerStrong: mix(dangerStrong, other.dangerStrong),
      dangerSoft: mix(dangerSoft, other.dangerSoft),
      warning: mix(warning, other.warning),
      info: mix(info, other.info),
      shipped: mix(shipped, other.shipped),
      muted: mix(muted, other.muted),
      mutedSoft: mix(mutedSoft, other.mutedSoft),
      surfaceBright: mix(surfaceBright, other.surfaceBright),
      splashBackground: mix(splashBackground, other.splashBackground),
    );
  }
}

final BrandTokens _fallbackTokens = BrandTokens.light();

extension BrandThemeX on BuildContext {
  /// Shorthand for the brand token set of the active theme.
  ///
  /// Falls back to the default light tokens when the surrounding Theme was
  /// not built through AppTheme (widget tests pumping bare MaterialApps).
  BrandTokens get brand =>
      Theme.of(this).extension<BrandTokens>() ?? _fallbackTokens;
}
