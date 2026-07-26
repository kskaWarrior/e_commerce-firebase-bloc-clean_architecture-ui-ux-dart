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
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Renders a filtered catalog gallery (search results or a category listing)
/// reading the AMBIENT [ProductsDisplayCubit], [NewInDisplayCubit] and
/// [FavoritesCubit] — so it must be mounted inside a subtree that already
/// provides them (the web home page does). It merges the top-selling and
/// new-in feeds into one deduped catalog, applies [filter], and shows a
/// [WebProductGrid] with an optional clear affordance.
class WebCatalogResults extends StatelessWidget {
  const WebCatalogResults({
    super.key,
    required this.title,
    required this.subtitleBuilder,
    required this.emptyMessage,
    required this.filter,
    this.onClear,
    this.clearTooltip,
    this.childAspectRatio = 0.70,
  });

  final String title;
  final String Function(BuildContext context, int count) subtitleBuilder;
  final String emptyMessage;
  final bool Function(ProductEntity product) filter;
  final VoidCallback? onClear;
  final String? clearTooltip;
  final double childAspectRatio;

  Future<void> _toggleFavorite(
    BuildContext context,
    ProductEntity product,
    Set<String> favoriteProductIds,
  ) async {
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
    return BlocBuilder<FavoritesCubit, FavoritesState>(
      builder: (context, favoritesState) {
        final favoriteProductIds = favoritesState is FavoritesLoaded
            ? favoritesState.favorites
                .map((favorite) => favorite.productId)
                .toSet()
            : <String>{};

        return BlocBuilder<ProductsDisplayCubit, ProductsDisplayState>(
          builder: (context, topState) {
            return BlocBuilder<NewInDisplayCubit, ProductsDisplayState>(
              builder: (context, newState) {
                final brand = context.brand;
                final isLoading = topState is ProductsDisplayLoading &&
                    newState is ProductsDisplayLoading;

                if (isLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 90),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final merged = <String, ProductEntity>{};
                if (topState is ProductsDisplayLoaded) {
                  for (final product in topState.products) {
                    merged[product.id] = product;
                  }
                }
                if (newState is ProductsDisplayLoaded) {
                  for (final product in newState.products) {
                    merged[product.id] = product;
                  }
                }
                final catalog = merged.values.toList(growable: false);
                final results = catalog.where(filter).toList(growable: false);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: WebSectionTitle(
                            title: title,
                            subtitle: subtitleBuilder(context, results.length),
                          ),
                        ),
                        if (onClear != null)
                          IconButton(
                            onPressed: onClear,
                            tooltip: clearTooltip ?? S.of(context).clearSearch,
                            icon: Icon(Icons.close, color: brand.iconStrong),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (results.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 56),
                        decoration: BoxDecoration(
                          color: brand.surfaceBright,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: brand.iconStrong.withOpacity(0.08),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.search_off, size: 38, color: brand.muted),
                            const SizedBox(height: 12),
                            Text(
                              emptyMessage,
                              style: TextStyle(
                                fontSize: 14.5,
                                color: brand.muted,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      WebProductGrid(
                        products: results,
                        favoriteProductIds: favoriteProductIds,
                        childAspectRatio: childAspectRatio,
                        onTap: (product) {
                          AppNavigator.push(
                            context,
                            ProductPage(
                              product: product,
                              topSellingProducts: catalog,
                            ),
                          );
                        },
                        onFavoritePressed: (product) =>
                            _toggleFavorite(context, product, favoriteProductIds),
                      ),
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
