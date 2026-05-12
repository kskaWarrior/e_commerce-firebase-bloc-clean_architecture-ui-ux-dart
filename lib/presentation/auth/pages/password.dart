import 'dart:async';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/basic_reactive_button.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/page/home.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password_forgot.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PasswordPage extends StatefulWidget {
  final UserSigninReq? userSigninReq;

  const PasswordPage({super.key, required this.userSigninReq});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isPasswordFieldFocused = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Typewriter effect variables
  final String _typewriterText = 'Type your password';
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _typewriterTimer;

  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _slideController.forward();

    _passwordFocusNode.addListener(() {
      if (!mounted) return;
      setState(() {
        _isPasswordFieldFocused = _passwordFocusNode.hasFocus;
      });
    });

    // Start typewriter effect
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
    _slideController.dispose();
    _typewriterTimer?.cancel();
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(
        title: 'Signing In',
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
            } else if (state is SuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.green,
                ),
              );
              AppNavigator.pushAndRemoveUntil(
                context,
                const HomePage(),
              );
            }
          },
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = MediaQuery.sizeOf(context).width;
                final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
                final isKeyboardOpen = keyboardInset > 0 || _isPasswordFieldFocused;
                final formWidth =
                    (screenWidth - 32).clamp(280.0, 420.0).toDouble();
                final logoSize =
                    (screenWidth * 0.55).clamp(150.0, 220.0).toDouble();

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(bottom: keyboardInset + 24),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Center(
                  child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                          SizedBox(height: isKeyboardOpen ? 24 : 60),
                      SlideTransition(
                        position: _slideAnimation,
                        child: const Text(
                          'Welcome back to',
                          style: TextStyle(
                            fontFamily: 'CircularStd',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: isKeyboardOpen ? 20 : 40),
                      SizedBox(
                            width: formWidth,
                        child: Image.asset(
                          AppImages.appLogo,
                              width: logoSize,
                              height: logoSize,
                        ),
                      ),
                      SizedBox(height: isKeyboardOpen ? 32 : 100),
                      SizedBox(
                        height: 55,
                            width: formWidth,
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(16),
                          child: TextField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            style: const TextStyle(
                              fontFamily: 'CircularStd',
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: _displayedText,
                              prefixIcon: const Icon(Icons.password_outlined),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 2,
                                    height: 24,
                                    color: Colors.grey.shade500,
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      _obscureText
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: _obscureText,
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
                              text: 'Sign In',
                              onPressed: () {
                                if (_passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your password'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                } else {
                                  widget.userSigninReq!.password = _passwordController.text;
                                  context.read<ButtonCubit>().execute(
                                    useCase: sl<SigninUseCase>(),
                                    params: widget.userSigninReq!
                                  );
                                }
                              },
                            );
                          }
                        ),
                      ),
                      SizedBox(height: isKeyboardOpen ? 8 : 20),
                          if (!isKeyboardOpen)
                            SizedBox(
                              width: formWidth,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Forgot your password? ',
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 14.7,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Click here!',
                                        style: TextStyle(
                                          fontFamily: 'CircularStd',
                                          fontSize: 14.7,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            AppNavigator.push(
                                              context,
                                              const ForgotPasswordPage(),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
