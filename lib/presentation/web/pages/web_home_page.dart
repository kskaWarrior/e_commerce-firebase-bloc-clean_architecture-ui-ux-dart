import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/pages/web_browse_pages.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_product_rail.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Desktop-web storefront home in classic e-commerce proportions: a short
/// wide promotional banner, a category card row, then horizontal product
/// rails. Search and category navigation live in the site-wide header.
class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  final GlobalKey _railsKey = GlobalKey();

  Future<void> _toggleFavorite({
    required BuildContext context,
    required ProductEntity product,
    required Set<String> favoriteProductIds,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseSignInAddFavorites),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    }

    final favoritesCubit = context.read<FavoritesCubit>();
    if (favoriteProductIds.contains(product.id)) {
      await favoritesCubit.deleteFavorite(userId, product.id);
      if (!context.mounted) return;
      await favoritesCubit.loadFavoritesByUserId(userId);
      return;
    }

    await favoritesCubit.registerFavorite(FavoriteEntity(
      createdDate: Timestamp.now(),
      id: '',
      productId: product.id,
      userId: userId,
    ));
    if (!context.mounted) return;
    await favoritesCubit.loadFavoritesByUserId(userId);
  }

  void _openProduct(
      BuildContext context, ProductEntity product, List<ProductEntity> all) {
    AppNavigator.push(
      context,
      ProductPage(product: product, topSellingProducts: all),
    );
  }

  void _scrollToRails() {
    final railsContext = _railsKey.currentContext;
    if (railsContext == null) return;
    Scrollable.ensureVisible(
      railsContext,
      duration: const Duration(milliseconds: 480),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<CategoriesCubit>()..loadCategories(),
        ),
        BlocProvider(
          create: (context) => sl<NewInDisplayCubit>()..displayProducts(),
        ),
        BlocProvider(
          create: (context) => sl<ProductsDisplayCubit>()..displayProducts(),
        ),
        BlocProvider(
          create: (context) {
            final cubit = sl<FavoritesCubit>();
            if (userId != null && userId.isNotEmpty) {
              cubit.loadFavoritesByUserId(userId);
            }
            return cubit;
          },
        ),
      ],
      child: Builder(
        builder: (context) {
          return WebScaffold(
            section: WebSection.home,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: WebScaffold.headerHeight + 26),
                  WebMaxWidth(
                    child: _HeroBanner(onShopNow: _scrollToRails),
                  ),
                  const SizedBox(height: 44),
                  const _CategoryCardsSection(),
                  const SizedBox(height: 44),
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, favoritesState) {
                      final favoriteProductIds =
                          favoritesState is FavoritesLoaded
                              ? favoritesState.favorites
                                  .map((favorite) => favorite.productId)
                                  .toSet()
                              : <String>{};

                      return Column(
                        key: _railsKey,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _RailSection<ProductsDisplayCubit>(
                            titleBuilder: (s) => s.topSelling,
                            subtitleBuilder: (s) => s.topSellingSubtitle,
                            favoriteProductIds: favoriteProductIds,
                            onTap: _openProduct,
                            onFavorite: (product, ids) => _toggleFavorite(
                              context: context,
                              product: product,
                              favoriteProductIds: ids,
                            ),
                          ),
                          const SizedBox(height: 44),
                          _RailSection<NewInDisplayCubit>(
                            titleBuilder: (s) => s.newIn,
                            subtitleBuilder: (s) => s.newInSubtitle,
                            favoriteProductIds: favoriteProductIds,
                            onTap: _openProduct,
                            onFavorite: (product, ids) => _toggleFavorite(
                              context: context,
                              product: product,
                              favoriteProductIds: ids,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 64),
                  const WebFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Short, wide promotional banner — desktop hero proportions.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.onShopNow});

  final VoidCallback onShopNow;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Container(
      height: wide ? 320 : 380,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            brand.iconStrong,
            Color.lerp(brand.iconStrong, brand.info, 0.3) ??
                brand.iconStrong,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -110,
            top: -130,
            child: _glow(brand.primary.withOpacity(0.38), 400),
          ),
          Positioned(
            left: -90,
            bottom: -150,
            child: _glow(brand.secondary.withOpacity(0.26), 360),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: brand.primary.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: brand.primary.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          s.heroWelcome(BrandConfig.appName),
                          style: TextStyle(
                            color: brand.primary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.heroTitle,
                        style: TextStyle(
                          color: brand.textInverse,
                          fontSize: wide ? 36 : 28,
                          height: 1.12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        s.heroSubtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: brand.textInverse.withOpacity(0.72),
                          fontSize: 14.5,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 22),
                      FilledButton.icon(
                        onPressed: onShopNow,
                        icon: const Icon(Icons.storefront_outlined,
                            size: 19),
                        label: Text(s.shopNow),
                        style: FilledButton.styleFrom(
                          backgroundColor: brand.primary,
                          foregroundColor: brand.onPrimary,
                          minimumSize: const Size(0, 48),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 26),
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (wide) ...[
                  const SizedBox(width: 30),
                  Image.asset(
                    AppImages.appSplash,
                    height: 260,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
        ),
      ),
    );
  }
}

/// Horizontal row of category cards navigating to the category pages.
class _CategoryCardsSection extends StatelessWidget {
  const _CategoryCardsSection();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return WebMaxWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebSectionTitle(
            title: s.shopByCategory,
            subtitle: s.shopByCategorySubtitle,
          ),
          const SizedBox(height: 18),
          BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) {
              final brand = context.brand;

              if (state is CategoriesLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is CategoriesError) {
                return Text(
                  state.message,
                  style: TextStyle(color: brand.danger),
                );
              }
              if (state is! CategoriesLoaded || state.categories.isEmpty) {
                return Text(
                  s.noCategoriesYet,
                  style: TextStyle(color: brand.muted),
                );
              }

              return SizedBox(
                height: 150,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final category = state.categories[index];
                    return _CategoryCard(
                      title: category.title,
                      image: category.image,
                      onTap: () => AppNavigator.push(
                        context,
                        WebCategoryPage(category: category),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.title,
    required this.image,
    required this.onTap,
  });

  final String title;
  final String image;
  final VoidCallback onTap;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 148,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: brand.surfaceBright,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? brand.primary
                  : brand.iconStrong.withOpacity(0.08),
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: brand.iconStrong.withOpacity(_hovered ? 0.12 : 0.04),
                blurRadius: _hovered ? 20 : 10,
                offset: Offset(0, _hovered ? 8 : 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              WebCategoryAvatar(image: widget.image, radius: 34),
              const SizedBox(height: 12),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: brand.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _ProductTapCallback = void Function(
    BuildContext context, ProductEntity product, List<ProductEntity> all);
typedef _FavoriteCallback = void Function(
    ProductEntity product, Set<String> favoriteProductIds);

class _RailSection<C extends Cubit<ProductsDisplayState>>
    extends StatelessWidget {
  const _RailSection({
    super.key,
    required this.titleBuilder,
    required this.subtitleBuilder,
    required this.favoriteProductIds,
    required this.onTap,
    required this.onFavorite,
  });

  final String Function(AppStrings s) titleBuilder;
  final String Function(AppStrings s) subtitleBuilder;
  final Set<String> favoriteProductIds;
  final _ProductTapCallback onTap;
  final _FavoriteCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return WebMaxWidth(
      child: BlocBuilder<C, ProductsDisplayState>(
        builder: (context, state) {
          final brand = context.brand;

          if (state is ProductsDisplayLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state is ProductsDisplayError) {
            return Text(
              state.message,
              style: TextStyle(color: brand.danger),
            );
          }
          if (state is! ProductsDisplayLoaded || state.products.isEmpty) {
            return Text(
              s.noProductsFound,
              style: TextStyle(color: brand.muted),
            );
          }

          return WebProductRail(
            title: titleBuilder(s),
            subtitle: subtitleBuilder(s),
            products: state.products,
            favoriteProductIds: favoriteProductIds,
            onTap: (product) => onTap(context, product, state.products),
            onFavoritePressed: (product) =>
                onFavorite(product, favoriteProductIds),
          );
        },
      ),
    );
  }
}
