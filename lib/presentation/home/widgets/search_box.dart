import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  final ValueChanged<String>? onChanged;

  const SearchBox({super.key, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 6.0, vertical: 12.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(24),
        color: context.brand.iconStrong,
        child: TextField(
          onChanged: onChanged,
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: S.of(context).searchProductsHint,
            hintStyle: TextStyle(
              color: colorScheme.primary.withOpacity(0.8),
            ),
            prefixIcon:
                Icon(Icons.search, color: colorScheme.primary),
            filled: true,
            fillColor: context.brand.iconStrong,
            contentPadding: const EdgeInsets.symmetric(
                vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}