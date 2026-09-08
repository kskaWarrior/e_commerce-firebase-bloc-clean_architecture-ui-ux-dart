import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/store_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/list_stores.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/auth/admin_session.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Platform-owner (super) landing page: pick which store to manage.
/// Owners never see this — their store comes from the custom claim.
///
/// The list is the primary control; the store-id field remains as a fallback
/// for when the listing fails (it needs the `super` claim to have propagated)
/// or when a store exists that the query did not return.
class SelectStorePage extends StatefulWidget {
  const SelectStorePage({super.key});

  @override
  State<SelectStorePage> createState() => _SelectStorePageState();
}

class _SelectStorePageState extends State<SelectStorePage> {
  final _storeIdController = TextEditingController();
  final _searchController = TextEditingController();

  List<StoreEntity>? _stores;
  String? _loadError;
  bool _manualEntry = false;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _stores = null;
      _loadError = null;
    });

    final result = await sl<ListStoresUseCase>().call(null);
    if (!mounted) return;

    result.fold(
      (error) => setState(() {
        _loadError = error.toString();
        // Nothing to pick from, so open the fallback rather than stranding
        // the platform owner on an error card.
        _manualEntry = true;
      }),
      (stores) => setState(() => _stores = List<StoreEntity>.from(stores)),
    );
  }

  void _select(String storeId) {
    final id = storeId.trim();
    if (id.isEmpty) return;
    sl<AdminSession>().selectStore(id);
    context.go('/orders');
  }

  List<StoreEntity> get _visibleStores {
    final all = _stores ?? const <StoreEntity>[];
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return all;
    return all
        .where((store) =>
            store.name.toLowerCase().contains(query) ||
            store.id.toLowerCase().contains(query))
        .toList();
  }

  @override
  void dispose() {
    _storeIdController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Scaffold(
      body: Stack(
        children: [
          const AdminBackdrop(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AdminGlassPanel(
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AdminColors.accentSoft,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.swap_horiz,
                                color: AdminColors.accent, size: 28),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          s.selectStore,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.signedInAsPlatformOwner,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14.5,
                            color: AdminColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                        if (_manualEntry) ..._manualEntryControls(s) else
                          ..._storeListControls(s),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _storeListControls(AppStrings s) {
    if (_stores == null) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    final stores = _visibleStores;
    return [
      if ((_stores ?? const []).length > 6) ...[
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: s.searchStores,
            prefixIcon: const Icon(Icons.search, size: 20),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 14),
      ],
      if (stores.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            s.storesEmpty,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminColors.textSecondary),
          ),
        )
      else
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final store = stores[index];
              return _StoreTile(
                store: store,
                onTap: () => _select(store.id),
              );
            },
          ),
        ),
      const SizedBox(height: 16),
      TextButton(
        onPressed: () => setState(() => _manualEntry = true),
        child: Text(s.enterStoreIdInstead),
      ),
    ];
  }

  List<Widget> _manualEntryControls(AppStrings s) {
    return [
      if (_loadError != null) ...[
        Text(
          s.storesLoadFailed,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AdminColors.danger, fontSize: 13.5),
        ),
        const SizedBox(height: 14),
      ],
      TextField(
        controller: _storeIdController,
        autofocus: true,
        decoration: InputDecoration(
          labelText: s.storeIdLabel,
          hintText: s.storeIdHint,
          prefixIcon: const Icon(Icons.storefront_outlined, size: 20),
        ),
        onSubmitted: _select,
      ),
      const SizedBox(height: 20),
      FilledButton(
        onPressed: () => _select(_storeIdController.text),
        child: Text(s.continueLabel),
      ),
      const SizedBox(height: 4),
      TextButton(
        onPressed: () {
          setState(() => _manualEntry = false);
          if (_stores == null) _loadStores();
        },
        child: Text(s.selectStore),
      ),
    ];
  }
}

class _StoreTile extends StatelessWidget {
  const _StoreTile({required this.store, required this.onTap});

  final StoreEntity store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // A seeded store has its id as its name until someone saves the settings
    // form, so showing both is not as redundant as it looks.
    final name = store.name.trim().isEmpty ? store.id : store.name;
    final inactive = store.status != 'active';

    return Material(
      color: AdminColors.surfaceTintStrong,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 20, color: AdminColors.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      inactive ? '${store.id} · ${store.status}' : store.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: inactive
                            ? AdminColors.danger
                            : AdminColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 20, color: AdminColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
