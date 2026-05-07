import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:flutter/material.dart';

class SearchCarousel extends StatefulWidget {
	final String query;
	final List<ProductEntity> products;
	final void Function(ProductEntity)? onTap;
	final Set<String> favoriteProductIds;
	final void Function(ProductEntity)? onFavoritePressed;

	const SearchCarousel({
		super.key,
		required this.query,
		required this.products,
		this.onTap,
		this.favoriteProductIds = const <String>{},
		this.onFavoritePressed,
	});

	@override
	State<SearchCarousel> createState() => _SearchCarouselState();
}

class _SearchCarouselState extends State<SearchCarousel> {
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
		final query = widget.query.trim().toLowerCase();
		final filteredProducts = widget.products
				.where((product) => product.title.toLowerCase().contains(query))
				.toList(growable: false);

		if (filteredProducts.isEmpty) {
			return const Center(child: Text('No products match your search'));
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
