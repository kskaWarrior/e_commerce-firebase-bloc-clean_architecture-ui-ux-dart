import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_product_rail.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Desktop-web favorites: a clean grid of saved products, plus fresh
/// arrivals below. Same cubits/data assembly as the mobile page.
class WebFavoritesPage extends StatelessWidget {
  const WebFavoritesPage({super.key, this.userIdOverride});

  final String? userIdOverride;

  @override
  Widget build(BuildContext context) {
    final userId = userIdOverride ?? FirebaseAuth.instance.currentUser?.uid;

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = sl<FavoritesCubit>();
            if (userId != null && userId.isNotEmpty) {
              cubit.loadFavoritesByUserId(userId);
            }
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) => sl<ProductsDisplayCubit>()..displayProducts(),
        ),
        BlocProvider(
          create: (_) => sl<NewInDisplayCubit>()..displayProducts(),
        ),
      ],
      child: WebScaffold(
        section: WebSection.favorites,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: WebScaffold.headerHeight + 28),
              WebMaxWidth(
                child: userId == null || userId.isEmpty
                    ? const _SignedOutState()
                    : _FavoritesBody(userId: userId),
              ),
              const SizedBox(height: 64),
              const WebFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState();

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.lock_outline, size: 44, color: brand.muted),
            const SizedBox(height: 14),
            Text(
              s.pleaseSignIn,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              s.signInToViewFavorites,
              style: TextStyle(fontSize: 14.5, color: brand.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesBody extends StatelessWidget {
  const _FavoritesBody({required this.userId});

  final String userId;

  Future<void> _toggle(
    BuildContext context,
    ProductEntity product,
    Set<String> favoriteProductIds,
  ) async {
    final cubit = context.read<FavoritesCubit>();
    if (favoriteProductIds.contains(product.id)) {
      await cubit.deleteFavorite(userId, product.id);
    } else {
      await cubit.registerFavorite(FavoriteEntity(
        createdDate: Timestamp.now(),
        id: '',
        productId: product.id,
        userId: userId,
      ));
    }
    if (!context.mounted) return;
    await cubit.loadFavoritesByUserId(userId);
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);

    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, favoritesState) {
        if (favoritesState is FavoritesLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 80),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (favoritesState is FavoritesError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Center(
              child: Text(
                favoritesState.message,
                style: TextStyle(color: brand.danger),
              ),
            ),
          );
        }

        final favorites = favoritesState is FavoritesLoaded
            ? (List<FavoriteEntity>.from(favoritesState.favorites)
              ..sort((a, b) => b.createdDate.compareTo(a.createdDate)))
            : <FavoriteEntity>[];
        final favoriteProductIds =
            favorites.map((favorite) => favorite.productId).toSet();

        return BlocBuilder<ProductsDisplayCubit, ProductsDisplayState>(
          builder: (context, topSellingState) {
            return BlocBuilder<NewInDisplayCubit, ProductsDisplayState>(
              builder: (context, newInState) {
                final topSelling = topSellingState is ProductsDisplayLoaded
                    ? topSellingState.products
                    : <ProductEntity>[];
                final newIn = newInState is ProductsDisplayLoaded
                    ? newInState.products
                    : <ProductEntity>[];

                final catalogById = <String, ProductEntity>{};
                for (final product in [...topSelling, ...newIn]) {
                  catalogById[product.id] = product;
                }

                final favoriteProducts = <ProductEntity>[
                  for (final favorite in favorites)
                    if (catalogById[favorite.productId] != null)
                      catalogById[favorite.productId]!,
                ];

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WebSectionTitle(
                      title: s.myFavorites,
                      subtitle: favorites.isEmpty
                          ? s.favoritesEmptyHint
                          : s.savedProducts(favorites.length),
                    ),
                    const SizedBox(height: 20),
                    if (favoriteProducts.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        decoration: BoxDecoration(
                          color: brand.surfaceBright,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: brand.iconStrong.withOpacity(0.08)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.favorite_border,
                                size: 40, color: brand.secondary),
                            const SizedBox(height: 12),
                            Text(
                              s.favoritesEmptyWebHint,
                              style: TextStyle(
                                  fontSize: 14.5, color: brand.muted),
                            ),
                            const SizedBox(height: 22),
                            FilledButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .popUntil((route) => route.isFirst),
                              icon: const Icon(Icons.storefront_outlined,
                                  size: 19),
                              label: Text(s.continueShopping),
                              style: FilledButton.styleFrom(
                                backgroundColor: brand.primary,
                                foregroundColor: brand.onPrimary,
                                minimumSize: const Size(0, 48),
                                textStyle: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      WebProductGrid(
                        products: favoriteProducts,
                        favoriteProductIds: favoriteProductIds,
                        onTap: (product) {
                          AppNavigator.push(
                            context,
                            ProductPage(
                              product: product,
                              topSellingProducts: topSelling,
                            ),
                          );
                        },
                        onFavoritePressed: (product) =>
                            _toggle(context, product, favoriteProductIds),
                      ),
                    if (newIn.isNotEmpty) ...[
                      const SizedBox(height: 48),
                      WebProductRail(
                        title: s.newIn,
                        subtitle: s.youMightAlsoLike,
                        products: newIn,
                        favoriteProductIds: favoriteProductIds,
                        onTap: (product) {
                          AppNavigator.push(
                            context,
                            ProductPage(
                              product: product,
                              topSellingProducts: newIn,
                            ),
                          );
                        },
                        onFavoritePressed: (product) =>
                            _toggle(context, product, favoriteProductIds),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
