import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onFavoritePressed;
  final bool compactInfo;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.isFavorite = false,
    this.onFavoritePressed,
    this.compactInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.images.isNotEmpty ? product.images.first : '';
    final hasDiscount =
        product.discountedPrice > 0 && product.discountedPrice < product.price;
    final colorDots = product.colors.take(5).toList(growable: false);
    final hiddenColorsCount = product.colors.length - colorDots.length;
    final titleFontSize = compactInfo ? 12.0 : 14.0;
    final infoFontSize = compactInfo ? 10.0 : 12.0;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: const Color.fromARGB(255, 10, 32, 53),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        shadowColor: Colors.black.withValues(alpha: 0.22),
        elevation: 9,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            ImageDisplayHelper.generateProductImagePath(imageUrl),
                            height: 232,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _imagePlaceholder();
                            },
                          )
                        : _imagePlaceholder(),
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onFavoritePressed,
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 39,
                          height: 39,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.07),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (colorDots.isNotEmpty)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...colorDots.map(
                            (colorOption) => Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Container(
                                width: 21,
                                height: 21,
                                decoration: BoxDecoration(
                                  color: _parseColor(colorOption.hexCode),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                          if (hiddenColorsCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 1),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '+$hiddenColorsCount',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                product.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: titleFontSize,
                    ),
                textAlign: TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Price: ',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: infoFontSize,
                        ),
                  ),
                  Text(
                    '\$${product.price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          decoration:
                              hasDiscount ? TextDecoration.lineThrough : null,
                          color: hasDiscount
                              ? const Color.fromARGB(255, 255, 139, 139)
                              : Theme.of(context).colorScheme.primary,
                          decorationColor: Colors.white,
                          fontSize: infoFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              if (hasDiscount)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Discounted: ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                            fontSize: infoFontSize,
                          ),
                    ),
                    Text(
                      '\$${product.discountedPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: infoFontSize,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 232,
      width: double.infinity,
      color: Colors.grey[300],
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, size: 48),
    );
  }

  Color _parseColor(String hexCode) {
    final normalized = hexCode.replaceAll('#', '').trim();

    if (normalized.length == 6) {
      final intColor = int.tryParse('FF$normalized', radix: 16);
      if (intColor != null) {
        return Color(intColor);
      }
    }

    if (normalized.length == 8) {
      final intColor = int.tryParse(normalized, radix: 16);
      if (intColor != null) {
        return Color(intColor);
      }
    }

    return Colors.grey;
  }
}