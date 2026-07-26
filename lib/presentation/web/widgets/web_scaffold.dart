import 'dart:ui';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/language_menu.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/my_profile_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/page/favorites_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/cart_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/my_purchases_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Sections used to highlight the active link in the web top navigation.
enum WebSection { home, favorites, orders, cart, none }

/// Desktop-web storefront chrome: a frosted-glass top navigation bar
/// floating over the page content, sharing the mobile app's brand palette
/// and assets. Pages provide their own scroll view and should start their
/// content with [WebScaffold.headerHeight] of top spacing (the home hero
/// intentionally flows underneath the glass bar instead).
class WebScaffold extends StatelessWidget {
  const WebScaffold({
    super.key,
    required this.body,
    this.section = WebSection.none,
  });

  final Widget body;
  final WebSection section;

  static const double headerHeight = 68;
  static const double contentMaxWidth = 1200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.brand.background,
      body: Stack(
        children: [
          Positioned.fill(child: body),
          Align(
            alignment: Alignment.topCenter,
            child: _WebHeader(section: section),
          ),
        ],
      ),
    );
  }
}

/// Centers content on the web canvas at the storefront's max width.
class WebMaxWidth extends StatelessWidget {
  const WebMaxWidth({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: WebScaffold.contentMaxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _WebHeader extends StatelessWidget {
  const _WebHeader({required this.section});

  final WebSection section;

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final s = S.of(dialogContext);
        return AlertDialog(
          title: Text(s.confirmLogoutTitle),
          content: Text(s.confirmLogoutBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(s.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(s.logout),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    await sl<SignOutUseCase>().call(null);
    if (!context.mounted) return;
    AppNavigator.pushAndRemoveUntil(context, const SigninPage());
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final user = FirebaseAuth.instance.currentUser;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          height: WebScaffold.headerHeight,
          decoration: BoxDecoration(
            color: brand.surfaceBright.withOpacity(0.72),
            border: Border(
              bottom: BorderSide(
                color: brand.iconStrong.withOpacity(0.08),
              ),
            ),
          ),
          child: WebMaxWidth(
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _goHome(context),
                    child: Image.asset(
                      AppImages.brandWordmark,
                      height: 30,
                      errorBuilder: (_, __, ___) => Text(
                        BrandConfig.appName,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: brand.iconStrong,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 36),
                _NavLink(
                  label: s.home,
                  active: section == WebSection.home,
                  onTap: () => _goHome(context),
                ),
                _NavLink(
                  label: s.favorites,
                  active: section == WebSection.favorites,
                  onTap: section == WebSection.favorites
                      ? () {}
                      : () =>
                          AppNavigator.push(context, const FavoritesPage()),
                ),
                _NavLink(
                  label: s.myOrders,
                  active: section == WebSection.orders,
                  onTap: section == WebSection.orders
                      ? () {}
                      : () =>
                          AppNavigator.push(context, const MyPurchasesPage()),
                ),
                const Spacer(),
                LanguageMenuButton(
                    iconColor: brand.iconStrong, showLabel: true),
                const SizedBox(width: 10),
                _CartButton(
                  active: section == WebSection.cart,
                  onTap: section == WebSection.cart
                      ? () {}
                      : () => AppNavigator.push(context, const CartPage()),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  tooltip: user?.email ?? S.of(context).account,
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  color: brand.surfaceBright,
                  onSelected: (value) {
                    switch (value) {
                      case 'profile':
                        AppNavigator.push(context, const MyProfilePage());
                      case 'orders':
                        AppNavigator.push(context, const MyPurchasesPage());
                      case 'signout':
                        _signOut(context);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      enabled: false,
                      child: Text(
                        user?.email ?? s.signedInUser,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: brand.muted,
                        ),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: _MenuRow(
                          icon: Icons.account_circle_outlined,
                          label: s.myProfile),
                    ),
                    PopupMenuItem<String>(
                      value: 'orders',
                      child: _MenuRow(
                          icon: Icons.shopping_bag_outlined,
                          label: s.myPurchases),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'signout',
                      child: _MenuRow(icon: Icons.logout, label: s.signOut),
                    ),
                  ],
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: brand.iconStrong,
                    child: Text(
                      _initial(user),
                      style: TextStyle(
                        color: brand.textInverse,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _initial(User? user) {
    final source = (user?.displayName ?? '').trim().isNotEmpty
        ? user!.displayName!.trim()
        : (user?.email ?? '').trim();
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: context.brand.iconStrong),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  const _NavLink({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final emphasized = widget.active || _hovered;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight:
                      widget.active ? FontWeight.w800 : FontWeight.w600,
                  color: emphasized
                      ? brand.iconStrong
                      : brand.iconStrong.withOpacity(0.62),
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 2.5,
                width: widget.active ? 22 : (_hovered ? 14 : 0),
                decoration: BoxDecoration(
                  color: brand.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return AnimatedBuilder(
      animation: CartDraftStore.instance,
      builder: (context, _) {
        final count = CartDraftStore.instance.itemsCount;

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: active
                    ? brand.primary.withOpacity(0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.shopping_bag_outlined,
                      size: 24, color: brand.iconStrong),
                  if (count > 0)
                    Positioned(
                      right: -7,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: brand.secondary,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color: brand.surfaceBright, width: 1.4),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            color: brand.textInverse,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Section heading with the brand's gold accent bar.
class WebSectionTitle extends StatelessWidget {
  const WebSectionTitle({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 4,
          decoration: BoxDecoration(
            color: brand.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: brand.iconStrong,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(fontSize: 14, color: brand.muted),
          ),
        ],
      ],
    );
  }
}

/// Storefront footer in the brand navy.
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);

    return Container(
      width: double.infinity,
      color: brand.iconStrong,
      padding: const EdgeInsets.symmetric(vertical: 44),
      child: WebMaxWidth(
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
                        BrandConfig.appName,
                        style: TextStyle(
                          color: brand.textInverse,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.footerTagline,
                        style: TextStyle(
                          color: brand.textInverse.withOpacity(0.65),
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
                _FooterLink(
                  label: s.home,
                  onTap: () => Navigator.of(context)
                      .popUntil((route) => route.isFirst),
                ),
                _FooterLink(
                  label: s.favorites,
                  onTap: () =>
                      AppNavigator.push(context, const FavoritesPage()),
                ),
                _FooterLink(
                  label: s.myOrders,
                  onTap: () =>
                      AppNavigator.push(context, const MyPurchasesPage()),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Divider(color: brand.textInverse.withOpacity(0.12), height: 1),
            const SizedBox(height: 18),
            Text(
              s.allRightsReserved(DateTime.now().year, BrandConfig.appName),
              style: TextStyle(
                color: brand.textInverse.withOpacity(0.45),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 28),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: context.brand.textInverse.withOpacity(0.8),
          textStyle:
              const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
