import 'dart:async';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/basic_reactive_button.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/send_password_reset_email.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final String _typewriterText = 'Please confirm your email here';
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _typewriterTimer;

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTypewriter();
  }

  void _startTypewriter() {
    _displayedText = '';
    _currentIndex = 0;
    _typewriterTimer?.cancel();
    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (_currentIndex < _typewriterText.length) {
        setState(() {
          _displayedText += _typewriterText[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(
        title: 'Forgot Password',
        hideBack: false,
      ),
      resizeToAvoidBottomInset: true,
      body: BlocProvider(
        create: (context) => ButtonCubit(),
        child: BlocListener<ButtonCubit, ButtonState>(
          listener: (context, state) {
            if (state is FailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
            if (state is SuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 10),
                ),
              );
              AppNavigator.pushReplacement(context, const SigninPage());
            }
          },
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.sizeOf(context).width;
                final formWidth =
                    (screenWidth - 32).clamp(280.0, 420.0).toDouble();
                final illustrationSize =
                    (screenWidth * 0.8).clamp(220.0, 360.0).toDouble();

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              'Don\'t worry, we will help you recover your password in a blink of an eye ;)',
                              style: TextStyle(
                                fontFamily: 'CircularStd',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: formWidth,
                            child: Image.asset(
                              AppImages.forgotPassword,
                              width: illustrationSize,
                              height: illustrationSize,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 55,
                            width: formWidth,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(16),
                              child: TextField(
                                controller: _emailController,
                                decoration: InputDecoration(
                                  hintText: _displayedText,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                  fontFamily: 'CircularStd',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 55,
                            width: formWidth,
                            child: Builder(
                              builder: (context) {
                                return BasicReactiveButton(
                                  text: 'Reset Password',
                                  onPressed: () {
                                    if (_emailController.text.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('Please enter your email'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } else {
                                      context.read<ButtonCubit>().execute(
                                          useCase: sl<
                                              SendPasswordEmailResetUseCase>(),
                                          params: _emailController.text.trim());
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
