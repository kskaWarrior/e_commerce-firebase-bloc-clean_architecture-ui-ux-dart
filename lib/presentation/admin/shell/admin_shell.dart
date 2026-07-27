import 'dart:ui';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/language_menu.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/store_context.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/auth/admin_session.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static final _destinations = <({
    String route,
    IconData icon,
    String Function(AppStrings) label,
  })>[
    (
      route: '/dashboard',
      icon: Icons.insights_outlined,
      label: (s) => s.dashboard,
    ),
    (
      route: '/orders',
      icon: Icons.receipt_long_outlined,
      label: (s) => s.orders,
    ),
    (
      route: '/products',
      icon: Icons.inventory_2_outlined,
      label: (s) => s.products,
    ),
    (
      route: '/categories',
      icon: Icons.category_outlined,
      label: (s) => s.categories,
    ),
    (
      route: '/settings',
      icon: Icons.settings_outlined,
      label: (s) => s.settings,
    ),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final index =
        _destinations.indexWhere((d) => location.startsWith(d.route));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final storeId = sl<StoreContext>().storeId;
    final selected = _selectedIndex(context);
    final s = S.of(context);

    return Scaffold(
      body: Stack(
        children: [
          const AdminBackdrop(),
          Row(
            children: [
              // --------------------------------------- frosted navy sidebar
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    width: 248,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AdminColors.sidebar.withOpacity(0.92),
                          AdminColors.accent.withOpacity(0.82),
                        ],
                      ),
                      border: Border(
                        right: BorderSide(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AdminColors.highlight,
                                  borderRadius: BorderRadius.circular(9),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AdminColors.highlight
                                          .withOpacity(0.35),
                                      blurRadius: 14,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.storefront,
                                    color: AdminColors.accentStrong,
                                    size: 19),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                s.storeAdmin,
                                style: const TextStyle(
                                  color: AdminColors.sidebarTextActive,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: Text(
                              storeId,
                              style: const TextStyle(
                                color: AdminColors.sidebarText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 24, bottom: 10),
                          child: Text(
                            s.manage,
                            style: TextStyle(
                              color: AdminColors.sidebarText.withOpacity(0.6),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        for (var i = 0; i < _destinations.length; i++)
                          _SidebarItem(
                            icon: _destinations[i].icon,
                            label: _destinations[i].label(s),
                            selected: i == selected,
                            onTap: () => context.go(_destinations[i].route),
                          ),
                        const Spacer(),
                        _SidebarItem(
                          icon: Icons.language,
                          label: s.language,
                          selected: false,
                          onTap: () => showLanguagePicker(context),
                        ),
                        Divider(
                            color: Colors.white.withOpacity(0.10), height: 1),
                        _SidebarItem(
                          icon: Icons.logout,
                          label: s.signOut,
                          selected: false,
                          onTap: () async {
                            await sl<AdminSession>().signOut();
                            if (context.mounted) {
                              context.go('/login');
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
              // ------------------------------------------------ content area
              Expanded(child: child),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final background = widget.selected
        ? Colors.white.withOpacity(0.12)
        : _hovered
            ? Colors.white.withOpacity(0.06)
            : Colors.transparent;
    final foreground = widget.selected || _hovered
        ? AdminColors.sidebarTextActive
        : AdminColors.sidebarText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: widget.selected ? null : background,
              gradient: widget.selected
                  ? LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.17),
                        Colors.white.withOpacity(0.05),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.selected
                    ? Colors.white.withOpacity(0.16)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                if (widget.selected)
                  Container(
                    width: 3,
                    height: 16,
                    margin: const EdgeInsets.only(right: 11),
                    decoration: BoxDecoration(
                      color: AdminColors.highlight,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: AdminColors.highlight.withOpacity(0.7),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  )
                else
                  const SizedBox(width: 14),
                Icon(widget.icon, size: 19, color: foreground),
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    fontWeight:
                        widget.selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
