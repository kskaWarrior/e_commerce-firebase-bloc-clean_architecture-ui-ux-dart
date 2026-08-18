import 'dart:async';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/entities/address_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/address/usecases/lookup_cep.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Owns the text controllers for a structured address so host pages can
/// read/write the value without rebuilding the form widget.
class AddressFormController {
  final cep = TextEditingController();
  final street = TextEditingController();
  final number = TextEditingController();
  final complement = TextEditingController();
  final neighborhood = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();

  AddressEntity toEntity() {
    return AddressEntity(
      cep: AddressEntity.normalizeCep(cep.text),
      street: street.text.trim(),
      number: number.text.trim(),
      complement: complement.text.trim(),
      neighborhood: neighborhood.text.trim(),
      city: city.text.trim(),
      state: state.text.trim().toUpperCase(),
    );
  }

  void setFromEntity(AddressEntity? entity) {
    if (entity == null) return;
    cep.text = entity.cep;
    street.text = entity.street;
    number.text = entity.number;
    complement.text = entity.complement;
    neighborhood.text = entity.neighborhood;
    city.text = entity.city;
    state.text = entity.state;
  }

  bool get isComplete => toEntity().isComplete;

  void dispose() {
    cep.dispose();
    street.dispose();
    number.dispose();
    complement.dispose();
    neighborhood.dispose();
    city.dispose();
    state.dispose();
  }
}

/// Structured address form with ViaCEP autofill on the CEP field.
class AddressForm extends StatefulWidget {
  const AddressForm({
    super.key,
    required this.controller,
    this.decorationBuilder,
    this.onChanged,
  });

  final AddressFormController controller;

  /// Lets host pages keep their own visual identity; defaults to a plain
  /// outlined field.
  final InputDecoration Function(String label, IconData icon)?
      decorationBuilder;
  final VoidCallback? onChanged;

  @override
  State<AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<AddressForm> {
  Timer? _debounce;
  bool _lookingUp = false;
  String? _lastLookedUpCep;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onCepChanged(String value) {
    widget.onChanged?.call();
    final normalized = AddressEntity.normalizeCep(value);
    if (normalized.length != 8 || normalized == _lastLookedUpCep) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      _lastLookedUpCep = normalized;
      setState(() => _lookingUp = true);
      final result = await sl<LookupCepUseCase>().call(normalized);
      if (!mounted) return;
      setState(() => _lookingUp = false);
      result.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).cepNotFound)),
          );
        },
        (address) {
          final c = widget.controller;
          final found = address as AddressEntity;
          if (found.street.isNotEmpty) c.street.text = found.street;
          if (found.neighborhood.isNotEmpty) {
            c.neighborhood.text = found.neighborhood;
          }
          if (found.city.isNotEmpty) c.city.text = found.city;
          if (found.state.isNotEmpty) c.state.text = found.state;
          widget.onChanged?.call();
        },
      );
    });
  }

  InputDecoration _decoration(String label, IconData icon) {
    final builder = widget.decorationBuilder;
    if (builder != null) return builder(label, icon);
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final c = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: c.cep,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: _decoration(s.cepLabel, Icons.local_post_office_outlined)
              .copyWith(
            suffixIcon: _lookingUp
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: _onCepChanged,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: c.street,
          keyboardType: TextInputType.streetAddress,
          decoration: _decoration(s.streetLabel, Icons.location_on_outlined),
          onChanged: (_) => widget.onChanged?.call(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: c.number,
                keyboardType: TextInputType.text,
                decoration: _decoration(s.numberLabel, Icons.tag_outlined),
                onChanged: (_) => widget.onChanged?.call(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: c.complement,
                decoration:
                    _decoration(s.complementLabel, Icons.home_work_outlined),
                onChanged: (_) => widget.onChanged?.call(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: c.neighborhood,
          decoration:
              _decoration(s.neighborhoodLabel, Icons.holiday_village_outlined),
          onChanged: (_) => widget.onChanged?.call(),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: c.city,
                decoration: _decoration(s.cityLabel, Icons.location_city_outlined),
                onChanged: (_) => widget.onChanged?.call(),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: TextFormField(
                controller: c.state,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [LengthLimitingTextInputFormatter(2)],
                decoration: _decoration(s.stateLabel, Icons.map_outlined),
                onChanged: (_) => widget.onChanged?.call(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
