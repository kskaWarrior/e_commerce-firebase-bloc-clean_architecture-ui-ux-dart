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
      leading: IconButton(
        icon: const Icon(
          Icons.menu,
          size: 32,
          color: Color.fromARGB(255, 10, 32, 53),
        ),
        onPressed: onMenuTap,
        tooltip: 'Menu',
      ),
      title: SizedBox(
        height: 40,
        child: Image.asset(
          'assets/images/buy_buy_horizontal_text.png',
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.shopping_cart,
            size: 35,
            color: Color.fromARGB(255, 10, 32, 53),
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
