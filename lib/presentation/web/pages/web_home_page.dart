import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Desktop-web storefront home: hero, category rail, curated product grids.
/// Reuses the exact cubits/usecases the mobile home is built on.
class WebHomePage extends StatefulWidget {
  const WebHomePage({super.key});

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedCategoryTitle;

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

    final favorite = FavoriteEntity(
      createdDate: Timestamp.now(),
      id: '',
      productId: product.id,
      userId: userId,
    );

    await favoritesCubit.registerFavorite(favorite);
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
          final s = S.of(context);
          return WebScaffold(
            section: WebSection.home,
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroBanner(
                    searchQuery: _searchQuery,
                    onSearchChanged: (value) =>
                        setState(() => _searchQuery = value),
                  ),
                  const SizedBox(height: 48),
                  BlocBuilder<FavoritesCubit, FavoritesState>(
                    builder: (context, favoritesState) {
                      final favoriteProductIds =
                          favoritesState is FavoritesLoaded
                              ? favoritesState.favorites
                                  .map((e) => e.productId)
                                  .toSet()
                              : <String>{};

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_searchQuery.trim().isNotEmpty) ...[
                            _SearchResults(
                              query: _searchQuery,
                              favoriteProductIds: favoriteProductIds,
                              onTap: _openProduct,
                              onFavorite: (product, ids) => _toggleFavorite(
                                context: context,
                                product: product,
                                favoriteProductIds: ids,
                              ),
                            ),
                            const SizedBox(height: 48),
                          ],
                          _CategoriesSection(
                            selectedCategoryId: _selectedCategoryId,
                            onCategoryTap: (category) {
                              setState(() {
                                if (_selectedCategoryId == category.id) {
                                  _selectedCategoryId = null;
                                  _selectedCategoryTitle = null;
                                } else {
                                  _selectedCategoryId = category.id;
                                  _selectedCategoryTitle = category.title;
                                }
                              });
                            },
                          ),
                          if (_selectedCategoryId != null) ...[
                            const SizedBox(height: 36),
                            _CategoryProducts(
                              categoryId: _selectedCategoryId!,
                              categoryTitle:
                                  _selectedCategoryTitle ?? s.categories,
                              favoriteProductIds: favoriteProductIds,
                              onTap: _openProduct,
                              onFavorite: (product, ids) => _toggleFavorite(
                                context: context,
                                product: product,
                                favoriteProductIds: ids,
                              ),
                            ),
                          ],
                          const SizedBox(height: 48),
                          _ProductsSection<ProductsDisplayCubit>(
                            title: s.topSelling,
                            subtitle: s.topSellingSubtitle,
                            favoriteProductIds: favoriteProductIds,
                            onTap: _openProduct,
                            onFavorite: (product, ids) => _toggleFavorite(
                              context: context,
                              product: product,
                              favoriteProductIds: ids,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _ProductsSection<NewInDisplayCubit>(
                            title: s.newIn,
                            subtitle: s.newInSubtitle,
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

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.searchQuery,
    required this.onSearchChanged,
  });

  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 980;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brand.iconStrong,
            Color.lerp(brand.iconStrong, brand.info, 0.25) ??
                brand.iconStrong,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Warm glows echoing the brand palette.
          Positioned(
            right: -120,
            top: -140,
            child: _glow(brand.primary.withOpacity(0.35), 420),
          ),
          Positioned(
            left: -100,
            bottom: -160,
            child: _glow(brand.secondary.withOpacity(0.28), 380),
          ),
          WebMaxWidth(
            child: Padding(
              padding: EdgeInsets.only(
                top: WebScaffold.headerHeight + (wide ? 48 : 36),
                bottom: wide ? 56 : 40,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
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
                        const SizedBox(height: 18),
                        Text(
                          s.heroTitle,
                          style: TextStyle(
                            color: brand.textInverse,
                            fontSize: wide ? 42 : 32,
                            height: 1.12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.heroSubtitle,
                          style: TextStyle(
                            color: brand.textInverse.withOpacity(0.72),
                            fontSize: 15.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 26),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: TextField(
                            onChanged: onSearchChanged,
                            style: TextStyle(
                              color: brand.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: s.searchProductsHint,
                              hintStyle: TextStyle(color: brand.muted),
                              prefixIcon:
                                  Icon(Icons.search, color: brand.iconStrong),
                              filled: true,
                              fillColor: brand.surfaceBright,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: 40),
                    Image.asset(
                      AppImages.appSplash,
                      height: 320,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
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

class _CategoriesSection extends StatelessWidget {
  const _CategoriesSection({
    required this.selectedCategoryId,
    required this.onCategoryTap,
  });

  final String? selectedCategoryId;
  final ValueChanged<CategoriesEntity> onCategoryTap;

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
          const SizedBox(height: 20),
          BlocBuilder<CategoriesCubit, CategoriesState>(
            builder: (context, state) {
              if (state is CategoriesLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is CategoriesError) {
                return Text(
                  state.message,
                  style: TextStyle(color: context.brand.danger),
                );
              }
              if (state is! CategoriesLoaded || state.categories.isEmpty) {
                return Text(
                  s.noCategoriesYet,
                  style: TextStyle(color: context.brand.muted),
                );
              }
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final category in state.categories)
                    _CategoryChip(
                      category: category,
                      selected: category.id == selectedCategoryId,
                      onTap: () => onCategoryTap(category),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoriesEntity category;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final emphasized = widget.selected || _hovered;
    final image = widget.category.image.trim().isEmpty
        ? null
        : ImageDisplayHelper.generateCategoryImagePath(widget.category.image);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.fromLTRB(8, 8, 18, 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? brand.primary.withOpacity(0.16)
                : brand.surfaceBright,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: emphasized
                  ? brand.primary
                  : brand.iconStrong.withOpacity(0.1),
              width: emphasized ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: brand.mutedSoft.withOpacity(0.6),
                backgroundImage:
                    image == null ? null : CachedNetworkImageProvider(image),
                child: image == null
                    ? Icon(Icons.category_outlined,
                        size: 18, color: brand.muted)
                    : null,
              ),
              const SizedBox(width: 10),
              Text(
                widget.category.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      widget.selected ? FontWeight.w800 : FontWeight.w600,
                  color: brand.textPrimary,
                ),
              ),
              if (widget.selected) ...[
                const SizedBox(width: 8),
                Icon(Icons.close, size: 15, color: brand.muted),
              ],
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

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.favoriteProductIds,
    required this.onTap,
    required this.onFavorite,
  });

  final String query;
  final Set<String> favoriteProductIds;
  final _ProductTapCallback onTap;
  final _FavoriteCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return WebMaxWidth(
      child: BlocBuilder<ProductsDisplayCubit, ProductsDisplayState>(
        builder: (context, state) {
          if (state is! ProductsDisplayLoaded) {
            return const SizedBox.shrink();
          }
          final normalized = query.trim().toLowerCase();
          final results = state.products
              .where((product) =>
                  product.title.toLowerCase().contains(normalized) ||
                  product.categoryName.toLowerCase().contains(normalized))
              .toList(growable: false);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebSectionTitle(
                title: s.resultsFor(query.trim()),
                subtitle: s.productsFound(results.length),
              ),
              const SizedBox(height: 20),
              if (results.isEmpty)
                Text(
                  s.nothingMatchedSearch,
                  style: TextStyle(color: context.brand.muted),
                )
              else
                WebProductGrid(
                  products: results,
                  favoriteProductIds: favoriteProductIds,
                  onTap: (product) => onTap(context, product, state.products),
                  onFavoritePressed: (product) =>
                      onFavorite(product, favoriteProductIds),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CategoryProducts extends StatelessWidget {
  const _CategoryProducts({
    required this.categoryId,
    required this.categoryTitle,
    required this.favoriteProductIds,
    required this.onTap,
    required this.onFavorite,
  });

  final String categoryId;
  final String categoryTitle;
  final Set<String> favoriteProductIds;
  final _ProductTapCallback onTap;
  final _FavoriteCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return WebMaxWidth(
      child: BlocBuilder<ProductsDisplayCubit, ProductsDisplayState>(
        builder: (context, state) {
          if (state is! ProductsDisplayLoaded) {
            return const SizedBox.shrink();
          }
          final products = state.products
              .where((product) => product.categoryId == categoryId)
              .toList(growable: false);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WebSectionTitle(
                title: categoryTitle,
                subtitle: s.productsInCategory(products.length),
              ),
              const SizedBox(height: 20),
              if (products.isEmpty)
                Text(
                  s.noProductsInCategory,
                  style: TextStyle(color: context.brand.muted),
                )
              else
                WebProductGrid(
                  products: products,
                  favoriteProductIds: favoriteProductIds,
                  onTap: (product) => onTap(context, product, state.products),
                  onFavoritePressed: (product) =>
                      onFavorite(product, favoriteProductIds),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductsSection<C extends Cubit<ProductsDisplayState>>
    extends StatelessWidget {
  const _ProductsSection({
    super.key,
    required this.title,
    required this.subtitle,
    required this.favoriteProductIds,
    required this.onTap,
    required this.onFavorite,
  });

  final String title;
  final String subtitle;
  final Set<String> favoriteProductIds;
  final _ProductTapCallback onTap;
  final _FavoriteCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    return WebMaxWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebSectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 20),
          BlocBuilder<C, ProductsDisplayState>(
            builder: (context, state) {
              if (state is ProductsDisplayLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (state is ProductsDisplayError) {
                return Text(
                  state.message,
                  style: TextStyle(color: context.brand.danger),
                );
              }
              if (state is! ProductsDisplayLoaded ||
                  state.products.isEmpty) {
                return Text(
                  S.of(context).noProductsFound,
                  style: TextStyle(color: context.brand.muted),
                );
              }
              return WebProductGrid(
                products: state.products,
                favoriteProductIds: favoriteProductIds,
                onTap: (product) => onTap(context, product, state.products),
                onFavoritePressed: (product) =>
                    onFavorite(product, favoriteProductIds),
              );
            },
          ),
        ],
      ),
    );
  }
}
