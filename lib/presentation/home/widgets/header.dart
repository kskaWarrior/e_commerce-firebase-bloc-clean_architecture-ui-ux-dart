import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget implements PreferredSizeWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(
          Icons.account_circle,
          size: 42,
          color: Color.fromARGB(255, 10, 32, 53), // Ocean dark blue
        ),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Soon you will be able to update your profile!"),
              duration: const Duration(seconds: 7),
            ),
          );
        },
        tooltip: 'Profile',
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