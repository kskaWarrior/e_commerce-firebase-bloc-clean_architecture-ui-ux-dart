import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/auth/admin_session.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Platform-owner (super) landing page: pick which store to manage.
/// Owners never see this — their store comes from the custom claim.
class SelectStorePage extends StatefulWidget {
  const SelectStorePage({super.key});

  @override
  State<SelectStorePage> createState() => _SelectStorePageState();
}

class _SelectStorePageState extends State<SelectStorePage> {
  final _storeIdController = TextEditingController();

  void _continue() {
    final storeId = _storeIdController.text.trim();
    if (storeId.isEmpty) return;
    sl<AdminSession>().selectStore(storeId);
    context.go('/orders');
  }

  @override
  void dispose() {
    _storeIdController.dispose();
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
                        TextField(
                          controller: _storeIdController,
                          decoration: InputDecoration(
                            labelText: s.storeIdLabel,
                            hintText: s.storeIdHint,
                            prefixIcon:
                                const Icon(Icons.storefront_outlined, size: 20),
                          ),
                          onSubmitted: (_) => _continue(),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _continue,
                          child: Text(s.continueLabel),
                        ),
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
}
