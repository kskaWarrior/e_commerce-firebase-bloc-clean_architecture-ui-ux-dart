import 'dart:async';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/basic_reactive_button.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/send_password_reset_email.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_auth_frame.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  String get _typewriterText => S.of(context).pleaseConfirmEmailHere;
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

  Locale? _typewriterLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restart the typewriter when the language changes, otherwise the
    // already-typed text stays in the previous language.
    final locale = Localizations.maybeLocaleOf(context);
    if (_typewriterLocale != locale) {
      final isFirstResolution = _typewriterLocale == null;
      _typewriterLocale = locale;
      if (!isFirstResolution) {
        _startTypewriter();
      }
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wide web gets the storefront-style split layout (asset beside a glass
    // card); everything else keeps the mobile layout, framed on web.
    if (kIsWeb && MediaQuery.sizeOf(context).width >= 760) {
      return _buildWebLayout(context);
    }
    return WebAuthFrame.wrap(_buildMobileLayout(context));
  }

  /// Shared reaction to the reset-email [ButtonCubit] result.
  void _handleButtonState(BuildContext context, ButtonState state) {
    if (state is FailureState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error),
          backgroundColor: context.brand.danger,
        ),
      );
    }
    if (state is SuccessState) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: context.brand.success,
          duration: const Duration(seconds: 10),
        ),
      );
      AppNavigator.pushReplacement(context, const SigninPage());
    }
  }

  void _submitReset(BuildContext context) {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseEnterEmailShort),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    }
    context.read<ButtonCubit>().execute(
          useCase: sl<SendPasswordEmailResetUseCase>(),
          params: _emailController.text.trim(),
        );
  }

  Widget _buildWebLayout(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);

    return BlocProvider(
      create: (context) => ButtonCubit(),
      child: BlocListener<ButtonCubit, ButtonState>(
        listener: _handleButtonState,
        child: WebAuthScaffold(
          card: WebGoldGlassPanel(
            width: 460,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(36, 30, 36, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  WebAuthCardHeader(
                    title: s.forgotPassword,
                    subtitle: _displayedText,
                    onBack: Navigator.of(context).canPop()
                        ? () => Navigator.of(context).pop()
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.forgotPasswordSubtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.4,
                      color: brand.textPrimary.withOpacity(0.75),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    onSubmitted: (_) => _submitReset(context),
                    style: const TextStyle(
                        fontSize: 15.5, fontWeight: FontWeight.w600),
                    decoration: webAuthInputDecoration(
                      context,
                      hintText: s.email,
                      prefixIcon:
                          Icon(Icons.email_outlined, color: brand.iconStrong),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) => WebAuthReactiveButton(
                      text: s.resetPassword,
                      onPressed: () => _submitReset(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: S.of(context).forgotPassword,
        hideBack: false,
      ),
      resizeToAvoidBottomInset: true,
      body: BlocProvider(
        create: (context) => ButtonCubit(),
        child: BlocListener<ButtonCubit, ButtonState>(
          listener: _handleButtonState,
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
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 32.0),
                            child: Text(
                              S.of(context).forgotPasswordSubtitle,
                              style: const TextStyle(
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
                                  fillColor: context.brand.surfaceBright,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 20, horizontal: 16),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
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
                                  text: S.of(context).resetPassword,
                                  onPressed: () {
                                    if (_emailController.text.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(S
                                              .of(context)
                                              .pleaseEnterEmailShort),
                                          backgroundColor:
                                              context.brand.danger,
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
