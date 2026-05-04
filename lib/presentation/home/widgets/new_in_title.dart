import 'package:flutter/material.dart';

class NewInTitle extends StatelessWidget {
  const NewInTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'New In',
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(1, 3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(
              'New In',
              style:
                  Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontStyle: FontStyle.italic,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(1, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          Text(
            'New In',
            style:
                Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.inversePrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontStyle: FontStyle.italic,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(1, 3),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}