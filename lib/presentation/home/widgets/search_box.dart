import 'package:flutter/material.dart';

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: 6.0, vertical: 12.0),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(24),
        color: Color.fromARGB(255, 10, 32, 53),
        child: TextField(
          style: TextStyle(
            color: colorScheme.primary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: 'Search for your next buy buy here ;)',
            hintStyle: TextStyle(
              color: colorScheme.primary.withValues(alpha: 0.8),
            ),
            prefixIcon:
                Icon(Icons.search, color: colorScheme.primary),
            filled: true,
            fillColor: Color.fromARGB(255, 10, 32, 53),
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