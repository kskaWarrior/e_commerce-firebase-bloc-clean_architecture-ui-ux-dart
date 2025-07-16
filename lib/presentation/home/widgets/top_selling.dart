import 'package:flutter/material.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';

class TopSellingCarousel extends StatefulWidget {
  final List<ProductEntity> products;
  final void Function(ProductEntity)? onTap;

  const TopSellingCarousel({
    super.key,
    required this.products,
    this.onTap,
  });

  @override
  State<TopSellingCarousel> createState() => _TopSellingCarouselState();
}

class _TopSellingCarouselState extends State<TopSellingCarousel> {
  // Track favorite state for each product by index
  late List<bool> _isFavorite;

  @override
  void initState() {
    super.initState();
    _isFavorite = List<bool>.filled(widget.products.length, false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return const Center(child: Text('No top selling products found'));
    }

    return SizedBox(
      height: 460,
      child: PageView.builder(
        itemCount: widget.products.length,
        controller: PageController(viewportFraction: 0.68),
        itemBuilder: (context, index) {
          final product = widget.products[index];
          final imageUrl = product.images.isNotEmpty ? product.images.first : '';
          return GestureDetector(
            onTap: () => widget.onTap?.call(product),
            child: Card(
              color: Theme.of(context).colorScheme.inversePrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Product Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  ImageDisplayHelper.generateProductImagePath(
                                      imageUrl),
                                  height: 310,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 140,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 60),
                                ),
                        ),
                        const SizedBox(height: 10),
                        // Product Title
                        Text(
                          product.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                          textAlign: TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // Align price and discounted price rows to the left
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Price: ',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 13,
                                  ),
                            ),
                            Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    decoration: product.discountedPrice < product.price
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: product.discountedPrice < product.price
                                        ? const Color.fromARGB(255, 255, 139, 139)
                                        : const Color.fromARGB(255, 255, 255, 255),
                                    decorationColor: Colors.white,
                                    fontSize: 14,
                                  ),
                            ),
                          ],
                        ),
                        if (product.discountedPrice < product.price)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Discounted: ',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                              ),
                              Text(
                                '\$${product.discountedPrice.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  // Favorite Icon Positioned
                  Positioned(
                    right: 15,
                    bottom: 23,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite[index]
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                          size: 30,
                        ),
                        onPressed: () {
                          setState(() {
                            _isFavorite[index] = !_isFavorite[index];
                          });
                        },
                        tooltip: 'Add to favorites',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}