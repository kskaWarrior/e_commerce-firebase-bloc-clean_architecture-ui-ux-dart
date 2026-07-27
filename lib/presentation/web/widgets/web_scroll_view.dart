import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:flutter/material.dart';

/// Scroll body for web storefront pages that keeps the [WebFooter] pinned to
/// the bottom of the viewport on short pages while letting it flow naturally
/// when the content is taller than the screen.
///
/// [children] is the page content ABOVE the footer (rendered in a stretched
/// column). The footer is appended in a [SliverFillRemaining] whose leftover
/// space pushes it down via a [Spacer].
class WebScrollView extends StatelessWidget {
  const WebScrollView({
    super.key,
    required this.children,
    this.footer = const WebFooter(),
  });

  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            children: [
              const Spacer(),
              footer,
            ],
          ),
        ),
      ],
    );
  }
}
