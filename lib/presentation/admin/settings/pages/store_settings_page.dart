import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/tenant/store_context.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/store_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/get_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/shipping_config_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/update_store_branding.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/payment/usecases/set_store_payment_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/update_store_shipping.dart';
import 'package:flutter/services.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/widgets/admin_color_picker.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';

/// Branding settings stored on the store doc. Compile-time BrandConfig is
/// the source of truth for shipped builds; these values feed dashboards,
/// e-mails, and (later) runtime theming without a rebuild.
class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  final _nameController = TextEditingController();
  final _appTitleController = TextEditingController();
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _backgroundController = TextEditingController();
  final _dashboardUrlController = TextEditingController();
  final _thresholdController = TextEditingController();
  final List<_ZoneRow> _zoneRows = [];
  bool _pickupEnabled = false;
  final _mpTokenController = TextEditingController();
  final _mpSecretController = TextEditingController();
  bool _savingPayment = false;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<GetStoreUseCase>().call(null);
    if (!mounted) return;
    result.fold(
      (error) {
        if (error.toString() == 'Store not found.') {
          // The store doc hasn't been provisioned yet (e.g. a demo store
          // seeded with catalog only). Prefill defaults from the tenant id
          // so the owner can fill in and save — the save creates the doc.
          final storeId = sl<StoreContext>().storeId;
          _nameController.text = storeId;
          _appTitleController.text = storeId;
          setState(() => _loading = false);
        } else {
          setState(() {
            _error = error.toString();
            _loading = false;
          });
        }
      },
      (store) {
        final s = store as StoreEntity;
        _nameController.text = s.name;
        _appTitleController.text =
            (s.branding['appTitle'] ?? s.name).toString();
        _primaryController.text =
            (s.branding['primaryColorHex'] ?? '').toString();
        _secondaryController.text =
            (s.branding['secondaryColorHex'] ?? '').toString();
        _backgroundController.text =
            (s.branding['backgroundColorHex'] ?? '').toString();
        _dashboardUrlController.text =
            (s.branding['lookerEmbedUrl'] ?? '').toString();
        _pickupEnabled = s.shipping.pickupEnabled;
        _thresholdController.text = s.shipping.freeShippingThreshold == null
            ? ''
            : s.shipping.freeShippingThreshold!.toStringAsFixed(2);
        for (final zone in s.shipping.zones) {
          _zoneRows.add(_ZoneRow.fromZone(zone));
        }
        setState(() => _loading = false);
      },
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final result = await sl<UpdateStoreBrandingUseCase>().call(
      UpdateStoreBrandingParams(
        name: _nameController.text.trim(),
        branding: {
          'appTitle': _appTitleController.text.trim(),
          'primaryColorHex': _primaryController.text.trim(),
          'secondaryColorHex': _secondaryController.text.trim(),
          'backgroundColorHex': _backgroundController.text.trim(),
          'lookerEmbedUrl': _dashboardUrlController.text.trim(),
        },
      ),
    );
    if (!mounted) return;

    final shippingResult =
        await sl<UpdateStoreShippingUseCase>().call(_buildShippingConfig());
    if (!mounted) return;

    setState(() => _saving = false);
    final message = result.fold(
      (error) => error.toString(),
      (_) => shippingResult.fold(
        (error) => error.toString(),
        (success) => success.toString(),
      ),
    );
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _savePaymentConfig() async {
    final token = _mpTokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).enterAccessToken)));
      return;
    }
    setState(() => _savingPayment = true);
    final result = await sl<SetStorePaymentConfigUseCase>().call(
      SetStorePaymentConfigParams(
        storeId: sl<StoreContext>().storeId,
        mpAccessToken: token,
        mpWebhookSecret: _mpSecretController.text.trim().isEmpty
            ? null
            : _mpSecretController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _savingPayment = false);
    final message =
        result.fold((error) => error.toString(), (ok) => ok.toString());
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    // Never keep the secret in the form after a successful save.
    result.fold((_) {}, (_) {
      _mpTokenController.clear();
      _mpSecretController.clear();
    });
  }

  ShippingConfig _buildShippingConfig() {
    final threshold =
        double.tryParse(_thresholdController.text.trim().replaceAll(',', '.'));
    return ShippingConfig(
      pickupEnabled: _pickupEnabled,
      freeShippingThreshold: threshold,
      zones: _zoneRows
          .map((row) => row.toZone())
          .where((zone) =>
              zone.cepStart.length == 8 && zone.cepEnd.length == 8)
          .toList(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _appTitleController.dispose();
    _primaryController.dispose();
    _secondaryController.dispose();
    _backgroundController.dispose();
    _dashboardUrlController.dispose();
    _thresholdController.dispose();
    _mpTokenController.dispose();
    _mpSecretController.dispose();
    for (final row in _zoneRows) {
      row.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return AdminPageScaffold(
      title: s.settings,
      subtitle: s.settingsSubtitle,
      actions: [
        FilledButton.icon(
          onPressed: _saving || _loading ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check, size: 18),
          label: Text(_saving ? s.savingEllipsis : s.saveChanges),
        ),
      ],
      scrollable: true,
      child: _loading
          ? const SizedBox(
              height: 420,
              child: Center(child: CircularProgressIndicator()))
          : _error != null
              ? SizedBox(
                  height: 420, child: Center(child: Text(_error!)))
              : Padding(
                  padding: const EdgeInsets.all(28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: s.storeIdentity,
                          body: s.storeIdentityBody,
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                            label: s.storeName,
                            controller: _nameController),
                        const SizedBox(height: 14),
                        _LabeledField(
                            label: s.appTitle,
                            controller: _appTitleController),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: s.brandColors,
                          body: s.brandColorsBody,
                        ),
                        const SizedBox(height: 16),
                        _ColorField(
                          label: s.primaryColor,
                          hint: 'FFFEBD2E',
                          controller: _primaryController,
                        ),
                        const SizedBox(height: 14),
                        _ColorField(
                          label: s.secondaryColor,
                          hint: 'FFE94B3C',
                          controller: _secondaryController,
                        ),
                        const SizedBox(height: 14),
                        _ColorField(
                          label: s.backgroundColor,
                          hint: 'FFFFF9F0',
                          controller: _backgroundController,
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: s.dashboardSection,
                          body: s.dashboardSectionBody,
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: s.dashboardUrlLabel,
                          controller: _dashboardUrlController,
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: s.shippingSection,
                          body: s.shippingSectionBody,
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            s.pickupEnabledLabel,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          value: _pickupEnabled,
                          onChanged: (value) =>
                              setState(() => _pickupEnabled = value),
                        ),
                        const SizedBox(height: 8),
                        _LabeledField(
                          label: s.freeShippingThresholdLabel,
                          controller: _thresholdController,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          s.deliveryZonesLabel,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.deliveryZonesBody,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AdminColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < _zoneRows.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ZoneEditor(
                              row: _zoneRows[i],
                              onRemove: () => setState(() {
                                _zoneRows.removeAt(i).dispose();
                              }),
                            ),
                          ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              setState(() => _zoneRows.add(_ZoneRow())),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(s.addZone),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 24),
                        _SectionHeader(
                          title: s.paymentsSection,
                          body: s.paymentsSectionBody,
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: s.mpAccessTokenLabel,
                          controller: _mpTokenController,
                        ),
                        const SizedBox(height: 14),
                        _LabeledField(
                          label: s.mpWebhookSecretLabel,
                          controller: _mpSecretController,
                        ),
                        const SizedBox(height: 14),
                        OutlinedButton.icon(
                          onPressed:
                              _savingPayment ? null : _savePaymentConfig,
                          icon: _savingPayment
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.credit_card, size: 18),
                          label: Text(s.savePaymentSettings),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
              fontSize: 13, color: AdminColors.textSecondary),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.controller});

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        TextField(controller: controller),
      ],
    );
  }
}

class _ZoneRow {
  final label = TextEditingController();
  final cepStart = TextEditingController();
  final cepEnd = TextEditingController();
  final fee = TextEditingController();

  _ZoneRow();

  factory _ZoneRow.fromZone(ShippingZone zone) {
    final row = _ZoneRow();
    row.label.text = zone.label;
    row.cepStart.text = zone.cepStart;
    row.cepEnd.text = zone.cepEnd;
    row.fee.text = zone.fee.toStringAsFixed(2);
    return row;
  }

  ShippingZone toZone() {
    return ShippingZone(
      label: label.text.trim(),
      cepStart: cepStart.text.trim(),
      cepEnd: cepEnd.text.trim(),
      fee: double.tryParse(fee.text.trim().replaceAll(',', '.')) ?? 0,
    );
  }

  void dispose() {
    label.dispose();
    cepStart.dispose();
    cepEnd.dispose();
    fee.dispose();
  }
}

class _ZoneEditor extends StatelessWidget {
  const _ZoneEditor({required this.row, required this.onRemove});

  final _ZoneRow row;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final cepFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(8),
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AdminColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.label,
              decoration: InputDecoration(labelText: s.zoneLabelField),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.cepStart,
              inputFormatters: cepFormatters,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.cepStartLabel),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TextField(
              controller: row.cepEnd,
              inputFormatters: cepFormatters,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: s.cepEndLabel),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.fee,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: s.zoneFeeLabel),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            tooltip: s.removeZone,
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}

class _ColorField extends StatefulWidget {
  const _ColorField({
    required this.label,
    required this.hint,
    required this.controller,
  });

  final String label;
  final String hint;
  final TextEditingController controller;

  @override
  State<_ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<_ColorField> {
  Color? _parse(String hex) {
    final cleaned = hex.trim().replaceFirst('#', '');
    if (cleaned.length != 8) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(value);
  }

  Future<void> _openPicker() async {
    final current = widget.controller.text.trim();
    final result = await showAdminColorPicker(
      context,
      title: S.of(context).pickColor,
      withName: false,
      initialHex: current.isEmpty ? widget.hint : current,
    );
    if (result == null || !mounted) return;
    // Store colors are 8-digit ARGB; keep them opaque.
    setState(() => widget.controller.text = 'FF${result.hex}');
  }

  @override
  Widget build(BuildContext context) {
    final color = _parse(widget.controller.text);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _openPicker,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color ?? AdminColors.surfaceTintStrong,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminColors.border),
                  ),
                  child: Icon(
                    Icons.colorize,
                    size: 16,
                    color: color == null
                        ? AdminColors.textSecondary
                        : (color.computeLuminance() > 0.5
                            ? Colors.black.withOpacity(0.55)
                            : Colors.white.withOpacity(0.85)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: widget.controller,
                decoration: InputDecoration(hintText: widget.hint),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
