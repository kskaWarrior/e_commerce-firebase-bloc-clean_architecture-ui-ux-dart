import 'package:flutter/material.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/widgets/product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';

class TopSellingCarousel extends StatefulWidget {
  final List<ProductEntity> products;
  final void Function(ProductEntity)? onTap;
  final Set<String> favoriteProductIds;
  final void Function(ProductEntity)? onFavoritePressed;

  const TopSellingCarousel({
    super.key,
    required this.products,
    this.onTap,
    this.favoriteProductIds = const <String>{},
    this.onFavoritePressed,
  });

  @override
  State<TopSellingCarousel> createState() => _TopSellingCarouselState();
}

class _TopSellingCarouselState extends State<TopSellingCarousel> {
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
    if (widget.products.isEmpty) {
      return const Center(child: Text('No top selling products found'));
    }

    const carouselHeight = 346.0;

    return SizedBox(
      height: carouselHeight,
      child: PageView.builder(
        padEnds: false,
        itemCount: widget.products.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          final product = widget.products[index];
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