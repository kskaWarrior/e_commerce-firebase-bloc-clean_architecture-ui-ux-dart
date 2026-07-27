import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onCartTap;
  final bool isLoggingOut;

  const HomeHeader({
    super.key,
    required this.onMenuTap,
    required this.onCartTap,
    this.isLoggingOut = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      // Keep the icons matched in size and give the centered wordmark room so
      // the three top elements never crowd each other on narrow phones.
      titleSpacing: 4,
      leadingWidth: 52,
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          size: 26,
          color: context.brand.iconStrong,
        ),
        onPressed: onMenuTap,
        tooltip: 'Menu',
      ),
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 34,
          child: BrandConfig.hasWordmark
              ? Image.asset(
                  AppImages.brandWordmark,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const _BrandNameTitle(),
                )
              : const _BrandNameTitle(),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.shopping_cart,
            size: 26,
            color: context.brand.iconStrong,
          ),
          onPressed: onCartTap,
          tooltip: 'Cart',
        ),
      ],
      centerTitle: true,
      backgroundColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BrandNameTitle extends StatelessWidget {
  const _BrandNameTitle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        BrandConfig.appName,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}
