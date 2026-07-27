import 'dart:ui';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Branded full-bleed backdrop (cream base + gold/coral/blue glows) used
/// behind the web auth surfaces so the liquid-glass panels have something
/// to refract.
class WebBrandBackdrop extends StatelessWidget {
  const WebBrandBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Positioned.fill(
      child: Stack(
        children: [
          _glow(
            alignment: const Alignment(-1.1, -1.0),
            color: brand.primary.withOpacity(0.45),
            size: 620,
          ),
          _glow(
            alignment: const Alignment(1.2, -0.6),
            color: brand.surface.withOpacity(0.95),
            size: 640,
          ),
          _glow(
            alignment: const Alignment(0.9, 1.2),
            color: brand.secondary.withOpacity(0.22),
            size: 560,
          ),
          _glow(
            alignment: const Alignment(-0.8, 1.1),
            color: brand.primary.withOpacity(0.22),
            size: 500,
          ),
        ],
      ),
    );
  }

  Widget _glow({
    required Alignment alignment,
    required Color color,
    required double size,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0.0)],
          ),
        ),
      ),
    );
  }
}

/// Subtle gold liquid-glass panel used across the web auth surfaces.
class WebGoldGlassPanel extends StatelessWidget {
  const WebGoldGlassPanel({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 28,
  });

  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: brand.primary.withOpacity(0.13),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: brand.primary.withOpacity(0.45),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// On web, presents a mobile-designed page (auth flow, profile) as a
/// centered gold liquid-glass panel over a branded backdrop, instead of
/// stretching the phone layout across the whole desktop viewport.
///
/// The wrapped page keeps its exact mobile layout: the frame overrides
/// MediaQuery so the page believes it is running on a phone-sized canvas.
class WebAuthFrame extends StatelessWidget {
  const WebAuthFrame({super.key, required this.child});

  final Widget child;

  /// Returns [page] unchanged on mobile; frames it on web.
  static Widget wrap(Widget page) => kIsWeb ? WebAuthFrame(child: page) : page;

  static const double _panelWidth = 430;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final mediaQuery = MediaQuery.of(context);
    final screen = mediaQuery.size;

    // On narrow windows (mobile browsers) skip the frame entirely and show
    // the mobile layout full-bleed, exactly like the app.
    if (screen.width < 640) {
      return child;
    }

    final panelHeight =
        (screen.height - 56).clamp(560.0, 800.0).toDouble();

    return Scaffold(
      backgroundColor: brand.background,
      body: Stack(
        children: [
          const WebBrandBackdrop(),
          Center(
            child: WebGoldGlassPanel(
              width: _panelWidth,
              height: panelHeight,
              // The page reads MediaQuery for sizing; feed it the panel
              // size so it lays out exactly like on a phone. A transparent
              // scaffold lets the glass show through.
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  size: Size(_panelWidth, panelHeight),
                  padding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    scaffoldBackgroundColor: Colors.transparent,
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop shell shared by every web auth page: the branded backdrop with
/// the splash asset aligned horizontally beside the page's glass [card]
/// (stacking vertically on narrower windows). Mirrors the sign-in landing so
/// the whole flow reads as one storefront.
class WebAuthScaffold extends StatelessWidget {
  const WebAuthScaffold({
    super.key,
    required this.card,
    this.assetPath,
    this.assetScale = 1.0,
  });

  final Widget card;

  /// Overrides the hero art. When null, the locale-aware splash is used
  /// (Portuguese variant for pt, the default splash otherwise).
  final String? assetPath;

  /// Multiplies the computed hero size — lets a page show a larger asset.
  final double assetScale;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final size = MediaQuery.sizeOf(context);
    final twoColumns = size.width >= 1020;
    final assetSize = (twoColumns
            ? (size.width * 0.36).clamp(400.0, 600.0).toDouble()
            : (size.height * 0.4).clamp(260.0, 420.0).toDouble()) *
        assetScale;

    final isPt = Localizations.maybeLocaleOf(context)?.languageCode == 'pt';
    final resolved =
        assetPath ?? (isPt ? AppImages.appSplashPt : AppImages.appSplash);

    final heroAsset = Image.asset(
      resolved,
      width: assetSize,
      height: assetSize,
      // Fall back to the default splash if a localized/custom asset is
      // missing for this brand.
      errorBuilder: (_, __, ___) => Image.asset(
        assetPath ?? AppImages.appSplash,
        width: assetSize,
        height: assetSize,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );

    return Scaffold(
      backgroundColor: brand.background,
      body: Stack(
        children: [
          const WebBrandBackdrop(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: twoColumns
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        heroAsset,
                        const SizedBox(width: 64),
                        card,
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        heroAsset,
                        const SizedBox(height: 20),
                        card,
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Standard header for a web auth card: an optional back affordance, the
/// centered brand wordmark (falling back to the app name), a bold title and
/// an optional fixed-height subtitle (so typewriter hints don't shift the
/// layout as they type).
class WebAuthCardHeader extends StatelessWidget {
  const WebAuthCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.titleFirst = false,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;

  /// When true, the title reads above the brand wordmark (e.g. "Welcome back
  /// to" sitting over the "buy buy" mark). Otherwise the wordmark leads.
  final bool titleFirst;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    final wordmark = Center(
      child: Image.asset(
        AppImages.brandWordmark,
        height: 36,
        errorBuilder: (_, __, ___) => Text(
          BrandConfig.appName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: brand.iconStrong,
          ),
        ),
      ),
    );

    final titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: brand.iconStrong,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (onBack != null)
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.arrow_back, color: brand.iconStrong, size: 22),
            ),
          ),
        if (titleFirst) ...[
          titleWidget,
          const SizedBox(height: 14),
          wordmark,
        ] else ...[
          wordmark,
          const SizedBox(height: 26),
          titleWidget,
        ],
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            height: 22,
            child: Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: brand.textPrimary.withOpacity(0.65),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Consistent field styling for the web auth cards (soft filled pill,
/// brand-tinted, no visible border).
InputDecoration webAuthInputDecoration(
  BuildContext context, {
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final brand = context.brand;
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: brand.muted),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: brand.surfaceBright.withOpacity(0.9),
    contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}

/// Full-width navy primary button matching the sign-in "Continue" action.
/// Use for actions that only navigate (no async cubit state).
class WebAuthPrimaryButton extends StatelessWidget {
  const WebAuthPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: brand.iconStrong,
          foregroundColor: brand.textInverse,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

/// Same navy button, but reactive to [ButtonCubit] — shows a spinner and
/// disables itself while a request is in flight. Must sit under a
/// [BlocProvider] exposing a [ButtonCubit].
class WebAuthReactiveButton extends StatelessWidget {
  const WebAuthReactiveButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  final String text;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return BlocBuilder<ButtonCubit, ButtonState>(
      builder: (context, state) {
        final isLoading = state is LoadingState;
        return SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: brand.iconStrong,
              foregroundColor: brand.textInverse,
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(brand.textInverse),
                    ),
                  )
                : Text(text),
          ),
        );
      },
    );
  }
}
