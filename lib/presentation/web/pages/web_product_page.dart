import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/color_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/cart_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_product_card.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Desktop-web product detail: gallery + purchase panel side by side,
/// related products below. Mirrors the mobile page's add-to-cart contract.
class WebProductPage extends StatefulWidget {
  const WebProductPage({
    super.key,
    required this.product,
    this.relatedProducts = const <ProductEntity>[],
  });

  final ProductEntity product;
  final List<ProductEntity> relatedProducts;

  @override
  State<WebProductPage> createState() => _WebProductPageState();
}

class _WebProductPageState extends State<WebProductPage> {
  late final FavoritesCubit _favoritesCubit;
  Set<String> _favoriteProductIds = <String>{};
  int _imageIndex = 0;
  String? _selectedSize;
  String? _selectedColorKey;
  String? _selectedColorTitle;
  String? _selectedColorHex;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _favoritesCubit = sl<FavoritesCubit>();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null && userId.isNotEmpty) {
      _favoritesCubit.loadFavoritesByUserId(userId);
    }

    final sizes = widget.product.sizes
        .map((size) => size.toString().trim())
        .where((size) => size.isNotEmpty)
        .toList(growable: false);
    if (sizes.length == 1) {
      _selectedSize = sizes.first;
    }
    final colors = widget.product.colors
        .where((color) =>
            color.title.trim().isNotEmpty || color.hexCode.trim().isNotEmpty)
        .toList(growable: false);
    if (colors.length == 1) {
      _selectColor(colors.first);
    }
  }

  @override
  void dispose() {
    _favoritesCubit.close();
    super.dispose();
  }

  void _selectColor(ProductColorEntity color) {
    _selectedColorTitle = color.title;
    _selectedColorHex = color.hexCode;
    _selectedColorKey = '${color.title}_${color.hexCode}';
  }

  void _snack(String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), backgroundColor: color),
      );
  }

  Future<void> _toggleFavorite(ProductEntity product) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || userId.isEmpty) {
      _snack(S.of(context).pleaseSignInFavorites, context.brand.danger);
      return;
    }

    if (_favoriteProductIds.contains(product.id)) {
      await _favoritesCubit.deleteFavorite(userId, product.id);
    } else {
      await _favoritesCubit.registerFavorite(FavoriteEntity(
        createdDate: Timestamp.now(),
        id: '',
        productId: product.id,
        userId: userId,
      ));
    }
    await _favoritesCubit.loadFavoritesByUserId(userId);
  }

  Future<void> _addToCart() async {
    final product = widget.product;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final hasDiscount =
        product.discountedPrice > 0 && product.discountedPrice < product.price;

    final s = S.of(context);
    if (userId == null || userId.isEmpty) {
      _snack(s.pleaseSignInAddToCart, context.brand.danger);
      return;
    }
    if (product.sizes.isNotEmpty && _selectedSize == null) {
      _snack(s.pleaseSelectSize, context.brand.danger);
      return;
    }
    if (product.colors.isNotEmpty && _selectedColorKey == null) {
      _snack(s.pleaseSelectColor, context.brand.danger);
      return;
    }

    final double unitPrice = product.price.toDouble();
    final double unitDiscountedPrice =
        (hasDiscount ? product.discountedPrice : product.price).toDouble();
    final double multipliedPrice = unitPrice * _quantity;
    final double multipliedDiscountedPrice = unitDiscountedPrice * _quantity;

    final sale = SalesEntity(
      createdDate: Timestamp.now(),
      discountedPrice: multipliedDiscountedPrice,
      freight: 0,
      id: '',
      installmentsNumber: 1,
      paymentMethod: 'cart',
      price: multipliedPrice,
      productsList: <Map<String, dynamic>>[
        <String, dynamic>{
          'id': product.id,
          'title': product.title,
          'productId': product.productId,
          'categoryName': product.categoryName,
          'size': _selectedSize ?? 'N/A',
          'color': _selectedColorTitle ?? 'N/A',
          'colorHex': _selectedColorHex ?? '',
          'unitPrice': unitPrice,
          'unitDiscounted': unitDiscountedPrice,
          'quantity': _quantity.toDouble(),
          'totalPrice': multipliedDiscountedPrice,
        },
      ],
      totalPrice: multipliedDiscountedPrice,
      userBirthDate: Timestamp.fromDate(DateTime(1970, 1, 1)),
      userGender: '',
      userId: userId,
      userName: '',
    );

    CartDraftStore.instance.addDraft(sale);
    if (!mounted) return;
    _snack(
      S.of(context).addedToCart(CartDraftStore.instance.itemsCount),
      context.brand.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final product = widget.product;
    final hasDiscount =
        product.discountedPrice > 0 && product.discountedPrice < product.price;
    final imagePaths = product.images
        .map((image) => image.toString())
        .where((image) => image.trim().isNotEmpty)
        .toList(growable: false);
    final related = widget.relatedProducts
        .where((item) => item.id != product.id)
        .toList(growable: false);

    return BlocListener<FavoritesCubit, FavoritesState>(
      bloc: _favoritesCubit,
      listener: (context, state) {
        if (state is FavoritesLoaded) {
          setState(() {
            _favoriteProductIds =
                state.favorites.map((favorite) => favorite.productId).toSet();
          });
        } else if (state is FavoritesError) {
          _snack(state.message, brand.danger);
        }
      },
      child: WebScaffold(
        section: WebSection.none,
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: WebScaffold.headerHeight + 28),
              WebMaxWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Breadcrumb(product: product),
                    const SizedBox(height: 22),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final twoColumns = constraints.maxWidth >= 860;
                        final gallery = _Gallery(
                          imagePaths: imagePaths,
                          imageIndex: _imageIndex,
                          onSelect: (index) =>
                              setState(() => _imageIndex = index),
                        );
                        final details = _details(brand, product, hasDiscount);

                        if (!twoColumns) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              gallery,
                              const SizedBox(height: 28),
                              details,
                            ],
                          );
                        }
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: gallery),
                            const SizedBox(width: 44),
                            Expanded(flex: 6, child: details),
                          ],
                        );
                      },
                    ),
                    if (related.isNotEmpty) ...[
                      const SizedBox(height: 60),
                      WebSectionTitle(
                        title: S.of(context).youMayAlsoLike,
                        subtitle: S.of(context).youMayAlsoLikeSubtitle,
                      ),
                      const SizedBox(height: 20),
                      WebProductGrid(
                        products: related,
                        favoriteProductIds: _favoriteProductIds,
                        onTap: (selected) {
                          AppNavigator.push(
                            context,
                            ProductPage(
                              product: selected,
                              topSellingProducts: widget.relatedProducts,
                            ),
                          );
                        },
                        onFavoritePressed: _toggleFavorite,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 64),
              const WebFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _details(
      BrandTokens brand, ProductEntity product, bool hasDiscount) {
    final s = S.of(context);
    final isFavorite = _favoriteProductIds.contains(product.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.categoryName.toUpperCase(),
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: brand.muted,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                product.title,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  height: 1.15,
                  color: brand.iconStrong,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: brand.surfaceBright,
              shape: CircleBorder(
                side: BorderSide(color: brand.iconStrong.withOpacity(0.12)),
              ),
              child: InkWell(
                onTap: () => _toggleFavorite(product),
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: brand.danger,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${(hasDiscount ? product.discountedPrice : product.price).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: brand.iconStrong,
              ),
            ),
            if (hasDiscount) ...[
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: brand.muted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: brand.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  s.percentOff(product.currentDiscount),
                  style: TextStyle(
                    color: brand.secondaryVariant,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          s.soldAndCode(product.salesNumber, product.productId),
          style: TextStyle(fontSize: 13, color: brand.muted),
        ),
        const SizedBox(height: 20),
        Text(
          product.description,
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: brand.textPrimary.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 24),
        if (product.sizes.isNotEmpty) ...[
          _OptionLabel(label: s.size, value: _selectedSize),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final size in product.sizes
                  .map((size) => size.toString().trim())
                  .where((size) => size.isNotEmpty))
                _SizeChip(
                  label: size,
                  selected: _selectedSize == size,
                  onTap: () => setState(() {
                    _selectedSize = _selectedSize == size ? null : size;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        if (product.colors.isNotEmpty) ...[
          _OptionLabel(label: s.color, value: _selectedColorTitle),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final color in product.colors)
                _ColorChip(
                  color: color,
                  selected:
                      _selectedColorKey == '${color.title}_${color.hexCode}',
                  onTap: () => setState(() {
                    final key = '${color.title}_${color.hexCode}';
                    if (_selectedColorKey == key) {
                      _selectedColorKey = null;
                      _selectedColorTitle = null;
                      _selectedColorHex = null;
                    } else {
                      _selectColor(color);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],
        _OptionLabel(label: s.quantity, value: null),
        const SizedBox(height: 10),
        Row(
          children: [
            _QuantityButton(
              icon: Icons.remove,
              onTap: _quantity > 1
                  ? () => setState(() => _quantity--)
                  : null,
            ),
            Container(
              width: 58,
              height: 42,
              alignment: Alignment.center,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: brand.surfaceBright,
                borderRadius: BorderRadius.circular(10),
                border:
                    Border.all(color: brand.iconStrong.withOpacity(0.15)),
              ),
              child: Text(
                '$_quantity',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            _QuantityButton(
              icon: Icons.add,
              onTap: () => setState(() => _quantity++),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_bag_outlined, size: 20),
                label: Text(s.addToCart),
                style: FilledButton.styleFrom(
                  backgroundColor: brand.primary,
                  foregroundColor: brand.onPrimary,
                  minimumSize: const Size(0, 52),
                  textStyle: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    AppNavigator.push(context, const CartPage()),
                icon: const Icon(Icons.shopping_cart_checkout, size: 20),
                label: Text(s.goToCart),
                style: OutlinedButton.styleFrom(
                  foregroundColor: brand.iconStrong,
                  minimumSize: const Size(0, 52),
                  side: BorderSide(
                      color: brand.iconStrong.withOpacity(0.3), width: 1.4),
                  textStyle: const TextStyle(
                      fontSize: 15.5, fontWeight: FontWeight.w700),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final muted = TextStyle(fontSize: 13, color: brand.muted);

    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text(S.of(context).home,
                style: muted.copyWith(fontWeight: FontWeight.w600)),
          ),
        ),
        Text('  /  ', style: muted),
        Text(product.categoryName, style: muted),
        Text('  /  ', style: muted),
        Flexible(
          child: Text(
            product.title,
            overflow: TextOverflow.ellipsis,
            style: muted.copyWith(
              color: brand.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _Gallery extends StatelessWidget {
  const _Gallery({
    required this.imagePaths,
    required this.imageIndex,
    required this.onSelect,
  });

  final List<String> imagePaths;
  final int imageIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final current = imagePaths.isEmpty
        ? null
        : ImageDisplayHelper.generateProductImagePath(
            imagePaths[imageIndex.clamp(0, imagePaths.length - 1)]);

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: brand.surfaceBright,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: brand.iconStrong.withOpacity(0.08)),
          ),
          clipBehavior: Clip.antiAlias,
          child: AspectRatio(
            aspectRatio: 1,
            child: current == null
                ? _placeholder(brand)
                : CachedNetworkImage(
                    imageUrl: current,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(brand),
                    errorWidget: (_, __, ___) => _placeholder(brand),
                  ),
          ),
        ),
        if (imagePaths.length > 1) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final selected = index == imageIndex;
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => onSelect(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      width: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? brand.primary
                              : brand.iconStrong.withOpacity(0.1),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        imageUrl: ImageDisplayHelper
                            .generateProductImagePath(imagePaths[index]),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(brand),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _placeholder(BrandTokens brand) {
    return Container(
      color: brand.mutedSoft.withOpacity(0.5),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 44, color: brand.muted),
    );
  }
}

class _OptionLabel extends StatelessWidget {
  const _OptionLabel({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: brand.textPrimary,
          ),
        ),
        if (value != null && value!.trim().isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            value!,
            style: TextStyle(fontSize: 13.5, color: brand.muted),
          ),
        ],
      ],
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? brand.iconStrong
                : brand.surfaceBright,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? brand.iconStrong
                  : brand.iconStrong.withOpacity(0.18),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: selected ? brand.textInverse : brand.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final ProductColorEntity color;
  final bool selected;
  final VoidCallback onTap;

  Color? _parse(String hexCode) {
    final normalized = hexCode.replaceAll('#', '').trim();
    if (normalized.length == 6) {
      final value = int.tryParse('FF$normalized', radix: 16);
      if (value != null) return Color(value); // tripwire-allow: product swatch data
    }
    if (normalized.length == 8) {
      final value = int.tryParse(normalized, radix: 16);
      if (value != null) return Color(value); // tripwire-allow: product swatch data
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final swatch = _parse(color.hexCode) ?? brand.muted;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: brand.surfaceBright,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? brand.primary
                  : brand.iconStrong.withOpacity(0.15),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: swatch,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: brand.iconStrong.withOpacity(0.2)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                color.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: brand.textPrimary,
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 15, color: brand.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;

    return Material(
      color: onTap == null
          ? brand.mutedSoft.withOpacity(0.4)
          : brand.surfaceBright,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: brand.iconStrong.withOpacity(0.15)),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onTap == null ? brand.muted : brand.iconStrong,
          ),
        ),
      ),
    );
  }
}
