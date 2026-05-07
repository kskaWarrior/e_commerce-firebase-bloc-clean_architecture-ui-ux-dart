import 'package:flutter/material.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';

class CategoryCarousel extends StatefulWidget {
  final String categoryId;
  final List<ProductEntity> products;
  final void Function(ProductEntity)? onTap;
  final Set<String> favoriteProductIds;
  final void Function(ProductEntity)? onFavoritePressed;

  const CategoryCarousel({
    super.key,
    required this.categoryId,
    required this.products,
    this.onTap,
    this.favoriteProductIds = const <String>{},
    this.onFavoritePressed,
  });

  @override
  State<CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<CategoryCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.62);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = widget.products
        .where((product) => product.categoryId == widget.categoryId)
        .toList(growable: false);

    if (filteredProducts.isEmpty) {
      return const Center(child: Text('No products found for this category'));
    }

    const carouselHeight = 346.0;

    return SizedBox(
      height: carouselHeight,
      child: PageView.builder(
        padEnds: false,
        itemCount: filteredProducts.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          final product = filteredProducts[index];
          return ProductCard(
            product: product,
            onTap: () => widget.onTap?.call(product),
            isFavorite: widget.favoriteProductIds.contains(product.id),
            onFavoritePressed: () => widget.onFavoritePressed?.call(product),
          );
        },
      ),
    );
  }
}