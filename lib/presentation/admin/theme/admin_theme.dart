import 'dart:ui';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:flutter/material.dart';

/// Design system for the admin dashboard.
///
/// The admin shares the mobile app's brand palette (warm cream, gold, coral,
/// deep navy) but leads with a DIFFERENT color than the shopper app: the
/// shopper app leads with the gold primary, the admin leads with the deep
/// navy (`iconStrong` in the brand tokens). Gold appears only as a highlight
/// (active indicators, logo mark), keeping the two products visibly related
/// yet distinct.
class AdminColors {
  AdminColors._();

  // Warm neutrals straight from the brand's cream background family.
  static const canvas = Color(0xFFFAF4E8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceTint = Color(0xFFFBF7EF);
  static const surfaceTintStrong = Color(0xFFF1E9DB);
  static const border = Color(0xFFEDE3D2);

  // Deep navy lead color (brand iconStrong family).
  static const accent = Color(0xFF123B5C);
  static const accentStrong = Color(0xFF0A2035);
  static const accentSoft = Color(0xFFE6F0F8); // brand surface

  // Brand gold, used sparingly as the highlight color.
  static const highlight = Color(0xFFFEBD2E);

  // Coral from the brand secondary, for backdrop glows.
  static const coral = Color(0xFFE94B3C);

  // Sidebar (frosted navy glass).
  static const sidebar = Color(0xFF0A2035);
  static const sidebarHover = Color(0xFF1B3A55);
  static const sidebarText = Color(0xFF9DB4C6);
  static const sidebarTextActive = Color(0xFFF6FAFD);

  static const textPrimary = Color(0xFF1C2430);
  static const textSecondary = Color(0xFF6E6A5E);

  // Brand secondaryVariant doubles as the danger color.
  static const danger = Color(0xFFB03028);
  static const dangerSoft = Color(0xFFF9E4E1);

  // Order status accents (chip text on tinted chip background).
  static const pending = Color(0xFFB45309);
  static const pendingSoft = Color(0xFFFCEFD4);
  static const paid = Color(0xFF175A8E);
  static const paidSoft = Color(0xFFE1EEF8);
  static const shipped = Color(0xFF6D28D9);
  static const shippedSoft = Color(0xFFEDE9FE);
  static const delivered = Color(0xFF2E7D46);
  static const deliveredSoft = Color(0xFFDEF2E3);
  static const cancelled = Color(0xFFB03028);
  static const cancelledSoft = Color(0xFFF9E4E1);

  static Color statusColor(String status) {
    switch (status) {
      case 'paid':
        return paid;
      case 'shipped':
        return shipped;
      case 'delivered':
        return delivered;
      case 'cancelled':
        return cancelled;
      default:
        return pending;
    }
  }

  static Color statusSoft(String status) {
    switch (status) {
      case 'paid':
        return paidSoft;
      case 'shipped':
        return shippedSoft;
      case 'delivered':
        return deliveredSoft;
      case 'cancelled':
        return cancelledSoft;
      default:
        return pendingSoft;
    }
  }
}

class AdminTheme {
  AdminTheme._();

  static ThemeData light() {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AdminColors.accent,
      onPrimary: Colors.white,
      secondary: AdminColors.highlight,
      onSecondary: AdminColors.accentStrong,
      surface: AdminColors.surface,
      onSurface: AdminColors.textPrimary,
      error: AdminColors.danger,
      onError: Colors.white,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'BrandFont',
      scaffoldBackgroundColor: AdminColors.canvas,
      // Keep the shopper token extension available so shared widgets keep
      // resolving; admin-specific chrome uses AdminColors directly.
      extensions: [BrandTokens.light()],
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AdminColors.textPrimary,
        displayColor: AdminColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AdminColors.surface,
        foregroundColor: AdminColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: AdminColors.border)),
        titleTextStyle: TextStyle(
          fontFamily: 'BrandFont',
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AdminColors.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFCF6),
        hintStyle: const TextStyle(color: AdminColors.textSecondary),
        labelStyle: const TextStyle(color: AdminColors.textSecondary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.accent, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AdminColors.accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 46),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'BrandFont',
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.textPrimary,
          minimumSize: const Size(0, 44),
          side: const BorderSide(color: AdminColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'BrandFont',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AdminColors.accent,
          textStyle: const TextStyle(
            fontFamily: 'BrandFont',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dataTableTheme: DataTableThemeData(
        headingTextStyle: const TextStyle(
          fontFamily: 'BrandFont',
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AdminColors.textSecondary,
        ),
        dataTextStyle: const TextStyle(
          fontFamily: 'BrandFont',
          fontSize: 14,
          color: AdminColors.textPrimary,
        ),
        headingRowColor: WidgetStateProperty.all(AdminColors.surfaceTint),
        dividerThickness: 1,
        horizontalMargin: 20,
        columnSpacing: 28,
        headingRowHeight: 46,
        dataRowMinHeight: 56,
        dataRowMaxHeight: 56,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AdminColors.accentStrong,
        contentTextStyle:
            const TextStyle(fontFamily: 'BrandFont', color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AdminColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// Warm brand backdrop with soft color glows; sits behind the glass
/// surfaces (sidebar, auth cards) so their blur has something to refract.
class AdminBackdrop extends StatelessWidget {
  const AdminBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AdminColors.canvas),
        child: Stack(
          children: [
            _glow(
              alignment: const Alignment(-1.2, -1.1),
              color: AdminColors.highlight.withOpacity(0.38),
              size: 560,
            ),
            _glow(
              alignment: const Alignment(-0.9, 1.3),
              color: AdminColors.coral.withOpacity(0.20),
              size: 520,
            ),
            _glow(
              alignment: const Alignment(1.25, -0.4),
              color: AdminColors.accentSoft.withOpacity(0.9),
              size: 640,
            ),
            _glow(
              alignment: const Alignment(0.7, 1.25),
              color: AdminColors.highlight.withOpacity(0.22),
              size: 480,
            ),
          ],
        ),
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

/// Frosted "liquid glass" panel: blurs whatever the [AdminBackdrop] renders
/// behind it and adds the translucent fill + hairline highlight border.
class AdminGlassPanel extends StatelessWidget {
  const AdminGlassPanel({
    super.key,
    required this.child,
    this.borderRadius = BorderRadius.zero,
    this.fillColor,
    this.borderColor,
    this.blur = 26,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final Color? fillColor;
  final Color? borderColor;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: fillColor ?? Colors.white.withOpacity(0.55),
            borderRadius: borderRadius,
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.65),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Shared page scaffold: header row (title, subtitle, actions) above a
/// white content card, with consistent paddings across admin pages.
class AdminPageScaffold extends StatelessWidget {
  const AdminPageScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    required this.child,
    this.scrollable = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = Card(
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AdminColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: scrollable
                ? SingleChildScrollView(child: content)
                : content,
          ),
        ],
      ),
    );
  }
}

class AdminStatusChip extends StatelessWidget {
  const AdminStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = AdminColors.statusColor(status);
    final soft = AdminColors.statusSoft(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            S.of(context).statusLabel(status),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
