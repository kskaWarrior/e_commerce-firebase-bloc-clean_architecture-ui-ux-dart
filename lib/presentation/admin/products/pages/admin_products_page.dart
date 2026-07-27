import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/web_image_viewer.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/delete_product_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_all_products_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/products/bloc/admin_products_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminProductsPage extends StatelessWidget {
  const AdminProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminProductsCubit(
        getAllProductsUseCase: sl<GetAllProductsUseCase>(),
        deleteProductUseCase: sl<DeleteProductUseCase>(),
      )..load(),
      child: BlocBuilder<AdminProductsCubit, AdminProductsState>(
        builder: (context, state) {
          final s = S.of(context);
          return AdminPageScaffold(
            title: s.products,
            subtitle: switch (state) {
              AdminProductsLoaded(:final products) =>
                s.adminProductsCount(products.length),
              _ => s.adminProductsSubtitle,
            },
            actions: [
              FilledButton.icon(
                onPressed: () async {
                  await context.push('/products/new');
                  if (context.mounted) {
                    context.read<AdminProductsCubit>().load();
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.newProduct),
              ),
            ],
            scrollable: true,
            child: switch (state) {
              AdminProductsLoading() => const SizedBox(
                  height: 420,
                  child: Center(child: CircularProgressIndicator())),
              AdminProductsError(:final message) => SizedBox(
                  height: 420, child: Center(child: Text(message))),
              AdminProductsLoaded(:final products) => products.isEmpty
                  ? SizedBox(
                      height: 420,
                      child: Center(
                        child: Text(
                          s.adminProductsEmpty,
                          style: const TextStyle(
                              color: AdminColors.textSecondary),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final image = product.images.isNotEmpty
                            ? ImageDisplayHelper.generateProductImagePath(
                                product.images.first.toString())
                            : null;
                        return _ProductRow(
                          image: image,
                          title: product.title,
                          category: product.categoryName,
                          price: product.price,
                          discountedPrice: product.discountedPrice,
                          onTap: () async {
                            await context.push('/products/${product.id}');
                            if (context.mounted) {
                              context.read<AdminProductsCubit>().load();
                            }
                          },
                          onDelete: () async {
                            final cubit = context.read<AdminProductsCubit>();
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: Text(
                                    S.of(dialogContext).deleteProduct),
                                content: Text(S
                                    .of(dialogContext)
                                    .deleteProductConfirm(product.title)),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child:
                                        Text(S.of(dialogContext).cancel),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                        backgroundColor:
                                            AdminColors.danger),
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child:
                                        Text(S.of(dialogContext).delete),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) {
                              final error = await cubit.delete(product.id);
                              if (error != null && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)));
                              }
                            }
                          },
                        );
                      },
                    ),
              _ => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }
}

class _ProductRow extends StatefulWidget {
  const _ProductRow({
    required this.image,
    required this.title,
    required this.category,
    required this.price,
    required this.discountedPrice,
    required this.onTap,
    required this.onDelete,
  });

  final String? image;
  final String title;
  final String category;
  final num price;
  final num discountedPrice;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        widget.discountedPrice > 0 && widget.discountedPrice < widget.price;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered
              ? AdminColors.accent.withOpacity(0.05)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              MouseRegion(
                cursor: widget.image == null
                    ? MouseCursor.defer
                    : SystemMouseCursors.zoomIn,
                child: GestureDetector(
                  onTap: widget.image == null
                      ? null
                      : () => showWebImageViewer(
                            context,
                            imagePaths: [widget.image!],
                          ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: widget.image == null
                        ? Container(
                            width: 52,
                            height: 52,
                            color: AdminColors.surfaceTintStrong,
                            child: const Icon(Icons.image_outlined,
                                color: AdminColors.textSecondary, size: 22),
                          )
                        : CachedNetworkImage(
                            imageUrl: widget.image!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              width: 52,
                              height: 52,
                              color: AdminColors.surfaceTintStrong,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: AdminColors.textSecondary, size: 22),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.category,
                      style: const TextStyle(
                          fontSize: 13, color: AdminColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${(hasDiscount ? widget.discountedPrice : widget.price).toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700),
                  ),
                  if (hasDiscount)
                    Text(
                      '\$${widget.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AdminColors.textSecondary,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: S.of(context).delete,
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AdminColors.textSecondary),
                hoverColor: AdminColors.dangerSoft,
                onPressed: widget.onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
