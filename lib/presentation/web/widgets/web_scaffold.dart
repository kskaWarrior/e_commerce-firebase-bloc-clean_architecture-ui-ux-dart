import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
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
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/cart_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/my_purchases_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/pages/web_browse_pages.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Sections used to highlight the active control in the web top navigation.
enum WebSection { home, favorites, orders, cart, none }

/// Desktop-web storefront chrome, following the classic e-commerce pattern:
/// a main bar (logo · prominent search · language / favorites / account /
/// cart) with a navy category strip underneath, site-wide. Pages provide
/// their own scroll view and should start their content with
/// [WebScaffold.headerHeight] of top spacing.
class WebScaffold extends StatelessWidget {
  const WebScaffold({
    super.key,
    required this.body,
    this.section = WebSection.none,
  });

  final Widget body;
  final WebSection section;

  static const double mainBarHeight = 74;
  static const double categoryStripHeight = 46;
  static const double headerHeight = mainBarHeight + categoryStripHeight;
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

class _WebHeader extends StatefulWidget {
  const _WebHeader({required this.section});

  final WebSection section;

  @override
  State<_WebHeader> createState() => _WebHeaderState();
}

class _WebHeaderState extends State<_WebHeader> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    _searchController.clear();
    AppNavigator.push(context, WebSearchPage(query: query));
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(dialogContext).confirmLogoutTitle),
        content: Text(S.of(dialogContext).confirmLogoutBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(S.of(dialogContext).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(S.of(dialogContext).logout),
          ),
        ],
      ),
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ------------------------------------------------------- main bar
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: WebScaffold.mainBarHeight,
              decoration: BoxDecoration(
                color: brand.surfaceBright.withOpacity(0.85),
                border: Border(
                  bottom: BorderSide(
                    color: brand.iconStrong.withOpacity(0.06),
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
                          height: 32,
                          errorBuilder: (_, __, ___) => Text(
                            BrandConfig.appName,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: brand.iconStrong,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 28),
                    // ------------------------------- prominent search bar
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: SizedBox(
                          height: 44,
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (_) => _submitSearch(),
                            textInputAction: TextInputAction.search,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: s.searchProductsHint,
                              hintStyle: TextStyle(
                                  color: brand.muted, fontSize: 14),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              filled: true,
                              fillColor:
                                  brand.background.withOpacity(0.85),
                              suffixIcon: Padding(
                                padding: const EdgeInsets.all(5),
                                child: Material(
                                  color: brand.primary,
                                  borderRadius: BorderRadius.circular(9),
                                  child: InkWell(
                                    onTap: _submitSearch,
                                    borderRadius:
                                        BorderRadius.circular(9),
                                    child: SizedBox(
                                      width: 46,
                                      child: Icon(Icons.search,
                                          size: 21,
                                          color: brand.onPrimary),
                                    ),
                                  ),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color:
                                      brand.iconStrong.withOpacity(0.14),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: brand.iconStrong, width: 1.4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 18),
                    // ------------------------------------- right cluster
                    LanguageMenuButton(
                        iconColor: brand.iconStrong, showLabel: true),
                    const SizedBox(width: 8),
                    _HeaderIconButton(
                      icon: Icons.favorite_border,
                      tooltip: s.favorites,
                      active: widget.section == WebSection.favorites,
                      onTap: widget.section == WebSection.favorites
                          ? () {}
                          : () => AppNavigator.push(
                              context, const FavoritesPage()),
                    ),
                    _HeaderIconButton(
                      icon: Icons.receipt_long_outlined,
                      tooltip: s.myOrders,
                      active: widget.section == WebSection.orders,
                      onTap: widget.section == WebSection.orders
                          ? () {}
                          : () => AppNavigator.push(
                              context, const MyPurchasesPage()),
                    ),
                    _CartButton(
                      active: widget.section == WebSection.cart,
                      onTap: widget.section == WebSection.cart
                          ? () {}
                          : () =>
                              AppNavigator.push(context, const CartPage()),
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
                            AppNavigator.push(
                                context, const MyProfilePage());
                          case 'orders':
                            AppNavigator.push(
                                context, const MyPurchasesPage());
                          case 'signout':
                            _signOut(context);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          enabled: false,
                          child: Text(
                            user?.email ?? S.of(context).signedInUser,
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
                          child:
                              _MenuRow(icon: Icons.logout, label: s.signOut),
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
        ),
        // -------------------------------------------- category nav strip
        const _CategoryStrip(),
      ],
    );
  }

  String _initial(User? user) {
    final source = (user?.displayName ?? '').trim().isNotEmpty
        ? user!.displayName!.trim()
        : (user?.email ?? '').trim();
    return source.isEmpty ? '?' : source[0].toUpperCase();
  }
}

/// Site-wide navy category navigation strip.
class _CategoryStrip extends StatefulWidget {
  const _CategoryStrip();

  @override
  State<_CategoryStrip> createState() => _CategoryStripState();
}

class _CategoryStripState extends State<_CategoryStrip> {
  late final CategoriesCubit _categoriesCubit;

  @override
  void initState() {
    super.initState();
    _categoriesCubit = sl<CategoriesCubit>()..loadCategories();
  }

  @override
  void dispose() {
    _categoriesCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);

    return Container(
      height: WebScaffold.categoryStripHeight,
      color: brand.iconStrong,
      child: WebMaxWidth(
        child: BlocBuilder<CategoriesCubit, CategoriesState>(
          bloc: _categoriesCubit,
          builder: (context, state) {
            final categories =
                state is CategoriesLoaded ? state.categories : null;

            return Row(
              children: [
                Icon(Icons.menu, size: 17,
                    color: brand.textInverse.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(
                  s.allCategories,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: brand.textInverse.withOpacity(0.9),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1,
                  height: 18,
                  color: brand.textInverse.withOpacity(0.2),
                ),
                const SizedBox(width: 4),
                if (categories != null)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final category in categories)
                            _StripLink(
                              label: category.title,
                              onTap: () => AppNavigator.push(
                                context,
                                WebCategoryPage(category: category),
                              ),
                            ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StripLink extends StatefulWidget {
  const _StripLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_StripLink> createState() => _StripLinkState();
}

class _StripLinkState extends State<_StripLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          height: WebScaffold.categoryStripHeight,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 4),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _hovered
                      ? brand.primary
                      : brand.textInverse.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                height: 2,
                width: _hovered ? 16 : 0,
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

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: active
                  ? brand.primary.withOpacity(0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 23, color: brand.iconStrong),
          ),
        ),
      ),
    );
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

        return Tooltip(
          message: S.of(context).myCart,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: active
                      ? brand.primary.withOpacity(0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.shopping_bag_outlined,
                        size: 23, color: brand.iconStrong),
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

/// Multi-column storefront footer in the brand navy.
class WebFooter extends StatelessWidget {
  const WebFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);

    return Container(
      width: double.infinity,
      color: brand.iconStrong,
      padding: const EdgeInsets.only(top: 48, bottom: 24),
      child: WebMaxWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        BrandConfig.appName,
                        style: TextStyle(
                          color: brand.textInverse,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        s.footerTagline,
                        style: TextStyle(
                          color: brand.textInverse.withOpacity(0.6),
                          fontSize: 13.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Icon(Icons.verified_user_outlined,
                              size: 16,
                              color: brand.primary.withOpacity(0.9)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              s.demoCheckoutNote,
                              style: TextStyle(
                                color: brand.textInverse.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 3,
                  child: _FooterColumn(
                    title: s.footerShop,
                    links: [
                      (
                        label: s.home,
                        onTap: () => Navigator.of(context)
                            .popUntil((route) => route.isFirst)
                      ),
                      (
                        label: s.favorites,
                        onTap: () => AppNavigator.push(
                            context, const FavoritesPage())
                      ),
                      (
                        label: s.myCart,
                        onTap: () =>
                            AppNavigator.push(context, const CartPage())
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _FooterColumn(
                    title: s.footerAccount,
                    links: [
                      (
                        label: s.myProfile,
                        onTap: () => AppNavigator.push(
                            context, const MyProfilePage())
                      ),
                      (
                        label: s.myPurchases,
                        onTap: () => AppNavigator.push(
                            context, const MyPurchasesPage())
                      ),
                      (
                        label: s.myOrders,
                        onTap: () => AppNavigator.push(
                            context, const MyPurchasesPage())
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            Divider(color: brand.textInverse.withOpacity(0.12), height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    s.allRightsReserved(
                        DateTime.now().year, BrandConfig.appName),
                    style: TextStyle(
                      color: brand.textInverse.withOpacity(0.45),
                      fontSize: 12.5,
                    ),
                  ),
                ),
                Icon(Icons.credit_card,
                    size: 20, color: brand.textInverse.withOpacity(0.35)),
                const SizedBox(width: 10),
                Icon(Icons.payments_outlined,
                    size: 20, color: brand.textInverse.withOpacity(0.35)),
                const SizedBox(width: 10),
                Icon(Icons.pix,
                    size: 20, color: brand.textInverse.withOpacity(0.35)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.links});

  final String title;
  final List<({String label, VoidCallback onTap})> links;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            color: brand.textInverse.withOpacity(0.55),
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        for (final link in links)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: link.onTap,
                child: Text(
                  link.label,
                  style: TextStyle(
                    color: brand.textInverse.withOpacity(0.8),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small circular category avatar used by the strip/home. Exposed here so
/// multiple pages can share it.
class WebCategoryAvatar extends StatelessWidget {
  const WebCategoryAvatar({super.key, required this.image, this.radius = 19});

  final String image;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final resolved = image.trim().isEmpty
        ? null
        : ImageDisplayHelper.generateCategoryImagePath(image);

    return CircleAvatar(
      radius: radius,
      backgroundColor: brand.mutedSoft.withOpacity(0.6),
      backgroundImage:
          resolved == null ? null : CachedNetworkImageProvider(resolved),
      child: resolved == null
          ? Icon(Icons.category_outlined,
              size: radius * 0.9, color: brand.muted)
          : null,
    );
  }
}
