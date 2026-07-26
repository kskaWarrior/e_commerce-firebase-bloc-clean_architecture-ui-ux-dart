import 'package:cached_network_image/cached_network_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/delete_category_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/categories/bloc/admin_categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class AdminCategoriesPage extends StatelessWidget {
  const AdminCategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminCategoriesCubit(
        getCategoriesUseCase: sl<GetCategoriesUseCase>(),
        deleteCategoryUseCase: sl<DeleteCategoryUseCase>(),
      )..load(),
      child: BlocBuilder<AdminCategoriesCubit, AdminCategoriesState>(
        builder: (context, state) {
          final s = S.of(context);
          return AdminPageScaffold(
            title: s.categories,
            subtitle: switch (state) {
              AdminCategoriesLoaded(:final categories) =>
                s.adminCategoriesCount(categories.length),
              _ => s.adminCategoriesSubtitle,
            },
            actions: [
              FilledButton.icon(
                onPressed: () async {
                  await context.push('/categories/new');
                  if (context.mounted) {
                    context.read<AdminCategoriesCubit>().load();
                  }
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.newCategory),
              ),
            ],
            scrollable: true,
            child: switch (state) {
              AdminCategoriesLoading() => const SizedBox(
                  height: 420,
                  child: Center(child: CircularProgressIndicator())),
              AdminCategoriesError(:final message) => SizedBox(
                  height: 420, child: Center(child: Text(message))),
              AdminCategoriesLoaded(:final categories) => categories.isEmpty
                  ? SizedBox(
                      height: 420,
                      child: Center(
                        child: Text(
                          s.adminCategoriesEmpty,
                          style: const TextStyle(
                              color: AdminColors.textSecondary),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          for (final category in categories)
                            _CategoryCard(
                              title: category.title,
                              image: category.image.isEmpty
                                  ? null
                                  : ImageDisplayHelper
                                      .generateCategoryImagePath(
                                          category.image),
                              onTap: () async {
                                await context
                                    .push('/categories/${category.id}');
                                if (context.mounted) {
                                  context
                                      .read<AdminCategoriesCubit>()
                                      .load();
                                }
                              },
                              onDelete: () async {
                                final cubit =
                                    context.read<AdminCategoriesCubit>();
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(S
                                        .of(dialogContext)
                                        .deleteCategory),
                                    content: Text(S
                                        .of(dialogContext)
                                        .deleteCategoryConfirm(
                                            category.title)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(
                                            dialogContext, false),
                                        child: Text(
                                            S.of(dialogContext).cancel),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor:
                                                AdminColors.danger),
                                        onPressed: () => Navigator.pop(
                                            dialogContext, true),
                                        child: Text(
                                            S.of(dialogContext).delete),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  final error =
                                      await cubit.delete(category.id);
                                  if (error != null && context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text(error)));
                                  }
                                }
                              },
                            ),
                        ],
                      ),
                    ),
              _ => const SizedBox.shrink(),
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.title,
    required this.image,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final String? image;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 200,
          decoration: BoxDecoration(
            color: _hovered ? AdminColors.surfaceTint : AdminColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered ? AdminColors.accent : AdminColors.border,
              width: _hovered ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: SizedBox(
                  height: 110,
                  width: double.infinity,
                  child: widget.image == null
                      ? Container(
                          color: AdminColors.surfaceTintStrong,
                          child: const Icon(Icons.category_outlined,
                              color: AdminColors.textSecondary, size: 30),
                        )
                      : CachedNetworkImage(
                          imageUrl: widget.image!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AdminColors.surfaceTintStrong,
                            child: const Icon(Icons.broken_image_outlined,
                                color: AdminColors.textSecondary,
                                size: 30),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: S.of(context).delete,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: AdminColors.textSecondary),
                      onPressed: widget.onDelete,
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
}
