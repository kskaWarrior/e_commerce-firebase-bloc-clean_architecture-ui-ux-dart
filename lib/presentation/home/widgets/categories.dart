import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/images/image_display_helper.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:flutter/material.dart';

class CategoriesWidget extends StatelessWidget {
  final List<CategoriesEntity> categories;
  final void Function(CategoriesEntity)? onTap;

  const CategoriesWidget({
    super.key,
    required this.categories,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: () => onTap?.call(category),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(
                        ImageDisplayHelper.generateCategoryImagePath(
                        category.image)
                        ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    category.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}