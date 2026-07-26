import 'dart:ui';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
