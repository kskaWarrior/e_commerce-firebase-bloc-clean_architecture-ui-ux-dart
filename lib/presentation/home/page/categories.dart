import 'package:flutter/material.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final contentWidth =
                (constraints.maxWidth - 24).clamp(320.0, 860.0).toDouble();

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: const Center(
                  child: Text('Categories Page'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}