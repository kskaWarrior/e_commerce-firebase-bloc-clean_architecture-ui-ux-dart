import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/store_context.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/store_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/get_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/dashboard/embed/dashboard_embed.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Embeds the store's Looker Studio report (built on the `sales_analytics`
/// BigQuery dataset). The embed URL is per-store, saved on the store doc's
/// `branding` map from the Settings page. The current store is passed to the
/// report as a filter parameter so an owner sees only their own data.
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _loading = true;
  String _embedUrl = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<GetStoreUseCase>().call(null);
    if (!mounted) return;
    result.fold(
      // Unprovisioned/missing store doc → treat as "no dashboard configured".
      (_) => setState(() => _loading = false),
      (store) {
        final url = store is StoreEntity
            ? (store.branding['lookerEmbedUrl'] ?? '').toString().trim()
            : '';
        setState(() {
          _embedUrl = url;
          _loading = false;
        });
      },
    );
  }

  /// Appends the current store as a Looker Studio report parameter so the
  /// report defaults to this tenant's data. The report must expose a
  /// parameter named `storeId`. Note: this is a URL-level default filter, not
  /// a hard security boundary (see the dashboard plan's security note).
  String _urlForStore(String base) {
    final storeId = sl<StoreContext>().storeId;
    if (storeId.isEmpty) return base;
    final params = Uri.encodeComponent('{"storeId":"$storeId"}');
    final separator = base.contains('?') ? '&' : '?';
    return '$base${separator}params=$params';
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AdminPageScaffold(
      title: s.dashboard,
      subtitle: s.dashboardSubtitle,
      scrollable: true,
      child: _loading
          ? const SizedBox(
              height: 480,
              child: Center(child: CircularProgressIndicator()),
            )
          : _embedUrl.isEmpty
              ? _EmptyState(
                  onOpenSettings: () => context.go('/settings'),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      height: 760,
                      width: double.infinity,
                      child: buildDashboardEmbed(_urlForStore(_embedUrl)),
                    ),
                  ),
                ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SizedBox(
      height: 480,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AdminColors.surfaceTintStrong,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  size: 30,
                  color: AdminColors.accent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                s.dashboardEmptyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AdminColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                s.dashboardEmptyHint,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AdminColors.textSecondary,
                ),
              ),
              const SizedBox(height: 22),
              FilledButton.icon(
                onPressed: onOpenSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: Text(s.dashboardOpenSettings),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
