import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: 'Home Page',
        hideBack: true,
      ),
      body: Center(
        child: Text(
          'Welcome to the Home Page!',
        ),
      ),
    );
  }
}