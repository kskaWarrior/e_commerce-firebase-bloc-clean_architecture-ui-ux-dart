import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/app_colors.dart';
import 'package:flutter/material.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(AppColors.lightBackground),
      body: Center(
        child: Image.asset(
          AppImages.appLogo, // Ensure this path is correct
          width: 200, // Adjust the width as needed
          height: 200, // Adjust the height as needed
        ),
      ),
    );
  }
}