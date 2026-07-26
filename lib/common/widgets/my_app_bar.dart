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
      // Ellipsize a long (often longer in pt-BR) title instead of letting it
      // run under the back button or the actions.
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          title ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20, // Decreased font size
            fontWeight: FontWeight.w700,
          ),
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