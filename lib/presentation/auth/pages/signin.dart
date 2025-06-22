import 'dart:async';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/bloc/button/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signup.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage>
    with SingleTickerProviderStateMixin {
  final String _typewriterText = 'Sign in with your email';
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _shakeTimer;

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTypewriter();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(
          milliseconds: 700), // Longer duration for floaty effect
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -4.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: -4.0, end: 4.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: 4.0, end: -3.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: -3.0, end: 2.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: 2.0, end: -1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 2),
      TweenSequenceItem(
          tween: Tween(begin: -1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1),
    ]).animate(_shakeController);

    // Start shake every 5 seconds
    _shakeTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _shakeController.forward(from: 0);
    });
  }

  void _startTypewriter() {
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (_currentIndex < _typewriterText.length) {
        setState(() {
          _displayedText += _typewriterText[_currentIndex];
          _currentIndex++;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeTimer?.cancel();
    _shakeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Ensures the body resizes when keyboard appears
      body: SafeArea(
        child: SingleChildScrollView(
          // This prevents overflow by allowing scrolling when keyboard is open
          child: SizedBox(
            height: MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppImages.appSplash,
                        width: 520,
                        height: 520,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 30,
                  right: 30,
                  bottom: 190,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(
                        fontFamily: 'CircularStd',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                    ),
                  ),
                ),
                Positioned(
                  left: 30,
                  right: 30,
                  bottom: 120,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onPressed: () {
                      if (_emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Please enter your email.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      AppNavigator.push(
                        context,
                        BlocProvider(
                          create: (context) => ButtonCubit(),
                          child: PasswordPage(
                            userSigninReq: UserSigninReq(
                              email: _emailController.text,
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Continue'),
                  ),
                ),
                Positioned(
                  left: 32,
                  right: 30,
                  bottom: 85,
                  // ignore: unnecessary_null_comparison
                  child: (_shakeController == null)
                      ? const SizedBox.shrink()
                      : AnimatedBuilder(
                          animation: _shakeController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(
                                  _shakeController.isAnimating
                                      ? (_shakeAnimation.value *
                                          ((_shakeController.value < 0.5)
                                              ? 1
                                              : -1))
                                      : 0,
                                  0),
                              child: child,
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              text: 'Don\'t have an account? ',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign Up!',
                                  style: TextStyle(
                                    fontFamily: 'CircularStd',
                                    fontSize: 16,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      AppNavigator.push(
                                        context,
                                        const SignUpPage(),
                                      );
                                    },
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
