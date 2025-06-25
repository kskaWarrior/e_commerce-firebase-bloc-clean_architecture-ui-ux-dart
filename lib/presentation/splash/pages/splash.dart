import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/page/home.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashCubit, SplashState>(
      listener: (context, state) {
        
        if (state is UnAuthenticated) {
          AppNavigator.pushReplacement(context, const SigninPage());

        } else if (state is Authenticated) {
          AppNavigator.pushReplacement(context, const HomePage());
        }
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 55, 45, 30),
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
