import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogoutTap;
  final bool isLoggingOut;

  const HomeHeader({
    super.key,
    required this.onLogoutTap,
    this.isLoggingOut = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: isLoggingOut
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(
                Icons.logout,
                size: 32,
                color: Color.fromARGB(255, 10, 32, 53),
              ),
        onPressed: isLoggingOut ? null : onLogoutTap,
        tooltip: 'Logout',
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
          icon: const Icon(Icons.shopping_cart, size: 42, color: Color.fromARGB(255, 10, 32, 53),),
          onPressed: () {
            // TODO: Add cart navigation
          },
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