import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/app_colors.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/home.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password_forgot.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/pages/bloc/splash_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/pages/bloc/splash_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        if (state is UnAuthenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SigninPage()),
          );
        } else if (state is Authenticated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(AppColors.lightBackground),
        body: Center(
          child: Image.asset(
            AppImages.appLogo,
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}
