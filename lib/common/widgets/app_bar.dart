import 'package:flutter/material.dart';

class MyAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final bool hideBack;

  const MyAppBar({
    super.key,
    this.title,
    this.actions,
    this.backgroundColor,
    required this.hideBack,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: hideBack
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new),
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Back',
            ),
      title: Text(
        title ?? '',
        style: const TextStyle(
          fontFamily: 'CircularStd',
          fontSize: 20, // Decreased font size
          fontWeight: FontWeight.w700,
        ),
      ),
      actions: actions,
      centerTitle: true,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}