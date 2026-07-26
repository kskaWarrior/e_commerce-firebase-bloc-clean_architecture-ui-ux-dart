import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:flutter/material.dart';

/// Storefront product card for the web grid: white surface, square image,
/// hover lift, discount badge, favorite toggle.
class WebProductCard extends StatefulWidget {
  const WebProductCard({
    super.key,
    required this.product,
    this.isFavorite = false,
    this.onTap,
    this.onFavoritePressed,
  });

  final ProductEntity product;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritePressed;

  @override
  State<WebProductCard> createState() => _WebProductCardState();
}

class _WebProductCardState extends State<WebProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final product = widget.product;
    final imageUrl = product.images.isNotEmpty
        ? ImageDisplayHelper.generateProductImagePath(
            product.images.first.toString())
        : '';
    final hasDiscount =
        product.discountedPrice > 0 && product.discountedPrice < product.price;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          decoration: BoxDecoration(
            color: brand.surfaceBright,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? brand.primary
                  : brand.iconStrong.withOpacity(0.08),
              width: _hovered ? 1.4 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: brand.iconStrong.withOpacity(_hovered ? 0.14 : 0.05),
                blurRadius: _hovered ? 26 : 12,
                offset: Offset(0, _hovered ? 12 : 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(17)),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: imageUrl.isEmpty
                          ? _placeholder(brand)
                          : CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => _placeholder(brand),
                              errorWidget: (_, __, ___) =>
                                  _placeholder(brand),
                            ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      left: 10,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: brand.secondary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '-${product.currentDiscount}%',
                          style: TextStyle(
                            color: brand.textInverse,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  if (widget.onFavoritePressed != null)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Material(
                        color: brand.surfaceBright.withOpacity(0.9),
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: widget.onFavoritePressed,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Icon(
                              widget.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 19,
                              color: brand.danger,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: brand.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: brand.muted),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${(hasDiscount ? product.discountedPrice : product.price).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: brand.iconStrong,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: Text(
                              '\$${product.price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: brand.muted,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BrandTokens brand) {
    return Container(
      color: brand.mutedSoft.withOpacity(0.5),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 38, color: brand.muted),
    );
  }
}

/// Responsive product grid used across the web storefront.
class WebProductGrid extends StatelessWidget {
  const WebProductGrid({
    super.key,
    required this.products,
    this.favoriteProductIds = const <String>{},
    required this.onTap,
    this.onFavoritePressed,
    this.childAspectRatio = 0.70,
  });

  final List<ProductEntity> products;
  final Set<String> favoriteProductIds;
  final ValueChanged<ProductEntity> onTap;
  final ValueChanged<ProductEntity>? onFavoritePressed;

  /// Cell width:height ratio. Lower values give taller cards (used by the
  /// category-filter gallery); defaults to the standard grid proportion.
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final product = products[index];
        return WebProductCard(
          product: product,
          isFavorite: favoriteProductIds.contains(product.id),
          onTap: () => onTap(product),
          onFavoritePressed: onFavoritePressed == null
              ? null
              : () => onFavoritePressed!(product),
        );
      },
    );
  }
}
