import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_product_card.dart';
import 'package:flutter/material.dart';

/// Horizontal product rail with arrow paging — the desktop e-commerce
/// pattern for curated sections (instead of tall grids).
class WebProductRail extends StatefulWidget {
  const WebProductRail({
    super.key,
    required this.title,
    this.subtitle,
    required this.products,
    this.favoriteProductIds = const <String>{},
    required this.onTap,
    this.onFavoritePressed,
  });

  final String title;
  final String? subtitle;
  final List<ProductEntity> products;
  final Set<String> favoriteProductIds;
  final ValueChanged<ProductEntity> onTap;
  final ValueChanged<ProductEntity>? onFavoritePressed;

  @override
  State<WebProductRail> createState() => _WebProductRailState();
}

class _WebProductRailState extends State<WebProductRail> {
  final ScrollController _controller = ScrollController();

  static const double _cardWidth = 232;
  static const double _cardSpacing = 18;
  static const double _railHeight = 356;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _page(double direction) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + direction * (_cardWidth + _cardSpacing) * 3)
        .clamp(0.0, _controller.position.maxScrollExtent);
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(
                      color: brand.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: brand.iconStrong,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle!,
                      style: TextStyle(fontSize: 14, color: brand.muted),
                    ),
                  ],
                ],
              ),
            ),
            _ArrowButton(icon: Icons.chevron_left, onTap: () => _page(-1)),
            const SizedBox(width: 8),
            _ArrowButton(icon: Icons.chevron_right, onTap: () => _page(1)),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: _railHeight,
          child: ListView.separated(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 8, right: 2, left: 2),
            itemCount: widget.products.length,
            separatorBuilder: (_, __) => const SizedBox(width: _cardSpacing),
            itemBuilder: (context, index) {
              final product = widget.products[index];
              return SizedBox(
                width: _cardWidth,
                child: WebProductCard(
                  product: product,
                  isFavorite: widget.favoriteProductIds.contains(product.id),
                  onTap: () => widget.onTap(product),
                  onFavoritePressed: widget.onFavoritePressed == null
                      ? null
                      : () => widget.onFavoritePressed!(product),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Material(
      color: brand.surfaceBright,
      shape: CircleBorder(
        side: BorderSide(color: brand.iconStrong.withOpacity(0.15)),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: brand.iconStrong),
        ),
      ),
    );
  }
}
