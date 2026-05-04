import 'package:flutter/material.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';

class NewInCarousel extends StatefulWidget {
  final List<ProductEntity> products;
  final void Function(ProductEntity)? onTap;

  const NewInCarousel({
    super.key,
    required this.products,
    this.onTap,
  });

  @override
  State<NewInCarousel> createState() => _NewInCarouselState();
}

class _NewInCarouselState extends State<NewInCarousel> {
  late final PageController _pageController;
  late List<bool> _isFavorite;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.68);
    _isFavorite = List<bool>.filled(widget.products.length, false);
  }

  @override
  void didUpdateWidget(covariant NewInCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products.length != widget.products.length) {
      final updated = List<bool>.filled(widget.products.length, false);
      for (var index = 0;
          index < updated.length && index < _isFavorite.length;
          index++) {
        updated[index] = _isFavorite[index];
      }
      _isFavorite = updated;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const Center(child: Text('No new products found'));
    }

    final carouselHeight = (MediaQuery.sizeOf(context).height * 0.58)
        .clamp(340.0, 500.0)
        .toDouble();

    return SizedBox(
      height: carouselHeight,
      child: PageView.builder(
        itemCount: widget.products.length,
        controller: _pageController,
        itemBuilder: (context, index) {
          final product = widget.products[index];
          return ProductCard(
            product: product,
            onTap: () => widget.onTap?.call(product),
            isFavorite: _isFavorite[index],
            onFavoritePressed: () {
              setState(() {
                _isFavorite[index] = !_isFavorite[index];
              });
            },
          );
        },
      ),
    );
  }
}