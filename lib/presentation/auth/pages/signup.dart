import 'dart:async';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/gender_and_age.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_auth_frame.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool _obscureText = true;

  // Add controllers for each TextField
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Typewriter state for each field
  List<String> get _typewriterTexts => [
        S.of(context).name,
        S.of(context).phone,
        S.of(context).email,
        S.of(context).password,
      ];
  final List<String> _displayedTexts = ['', '', '', ''];
  // ignore: unused_field
  int _currentField = 0;
  int _currentChar = 0;
  Timer? _typewriterTimer;

  @override
  void initState() {
    super.initState();
    _startTypewriter(0);
  }

  void _startTypewriter(int fieldIndex) {
    _typewriterTimer?.cancel();
    _currentField = fieldIndex;
    _currentChar = 0;
    _displayedTexts[fieldIndex] = '';
    _typewriterTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_currentChar < _typewriterTexts[fieldIndex].length) {
        setState(() {
          _displayedTexts[fieldIndex] +=
              _typewriterTexts[fieldIndex][_currentChar];
          _currentChar++;
        });
      } else {
        timer.cancel();
        if (fieldIndex + 1 < _typewriterTexts.length) {
          Future.delayed(const Duration(milliseconds: 200), () {
            _startTypewriter(fieldIndex + 1);
          });
        }
      }
    });
  }

  Locale? _typewriterLocale;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Restart the typewriter sequence when the language changes, otherwise
    // the already-typed hints stay in the previous language.
    final locale = Localizations.maybeLocaleOf(context);
    if (_typewriterLocale != locale) {
      final isFirstResolution = _typewriterLocale == null;
      _typewriterLocale = locale;
      if (!isFirstResolution) {
        for (var i = 0; i < _displayedTexts.length; i++) {
          _displayedTexts[i] = '';
        }
        _startTypewriter(0);
      }
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  /// Validates the profile fields, then advances to the gender/age step.
  /// Shared by both layouts.
  void _submitSignup(BuildContext context) {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseEnterName),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    } else if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseEnterPhone),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    } else if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseEnterEmail),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    } else if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseEnterPasswordPeriod),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    }
    AppNavigator.push(
      context,
      BlocProvider(
        create: (context) => ButtonCubit(),
        child: GenderAndAgePage(
          userCreationReq: UserCreationReq(
            name: _nameController.text,
            phone: _phoneController.text,
            email: _emailController.text,
            password: _passwordController.text,
          ),
        ),
      ),
    );
  }

  Widget _buildWebLayout(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);

    return WebAuthScaffold(
      card: WebGoldGlassPanel(
        width: 480,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 30, 36, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WebAuthCardHeader(
                title: s.onlyTwoSteps,
                subtitle: s.fillProfileBelow,
                onBack: Navigator.of(context).canPop()
                    ? () => Navigator.of(context).pop()
                    : null,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                style:
                    const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                decoration: webAuthInputDecoration(
                  context,
                  hintText: _displayedTexts[0].isEmpty ? s.name : _displayedTexts[0],
                  prefixIcon:
                      Icon(Icons.person_outline, color: brand.iconStrong),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                style:
                    const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                decoration: webAuthInputDecoration(
                  context,
                  hintText:
                      _displayedTexts[1].isEmpty ? s.phone : _displayedTexts[1],
                  prefixIcon:
                      Icon(Icons.phone_outlined, color: brand.iconStrong),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style:
                    const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                decoration: webAuthInputDecoration(
                  context,
                  hintText:
                      _displayedTexts[2].isEmpty ? s.email : _displayedTexts[2],
                  prefixIcon:
                      Icon(Icons.email_outlined, color: brand.iconStrong),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                obscureText: _obscureText,
                keyboardType: TextInputType.visiblePassword,
                onSubmitted: (_) => _submitSignup(context),
                style:
                    const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600),
                decoration: webAuthInputDecoration(
                  context,
                  hintText: _displayedTexts[3].isEmpty
                      ? s.password
                      : _displayedTexts[3],
                  prefixIcon:
                      Icon(Icons.password_outlined, color: brand.iconStrong),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: brand.muted,
                    ),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              WebAuthPrimaryButton(
                text: s.continueLabel,
                onPressed: () => _submitSignup(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: S.of(context).signingUp,
        hideBack: false,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final formWidth = (MediaQuery.sizeOf(context).width - 32)
                .clamp(280.0, 420.0)
                .toDouble();

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                          S.of(context).onlyTwoSteps,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                          S.of(context).fillProfileBelow,
                      style: const TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Name
                  SizedBox(
                    height: 55,
                        width: formWidth,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: _displayedTexts[0],
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: context.brand.surfaceBright,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.name,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Phone
                  SizedBox(
                    height: 55,
                        width: formWidth,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: _phoneController,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: _displayedTexts[1],
                          prefixIcon: const Icon(Icons.phone_outlined),
                          filled: true,
                          fillColor: context.brand.surfaceBright,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 20, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Email
                  SizedBox(
                    height: 55,
                        width: formWidth,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: _emailController,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: _displayedTexts[2],
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Password
                  SizedBox(
                    height: 55,
                        width: formWidth,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: _passwordController,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: _displayedTexts[3],
                          prefixIcon: const Icon(Icons.password_outlined),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 2,
                                height: 24,
                                color: context.brand.muted,
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
                          fillColor: context.brand.surfaceBright,
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
                  const SizedBox(height: 60),
                  SizedBox(
                    height: 55,
                        width: formWidth,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: context.brand.textInverse,
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
                        if (_nameController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(S.of(context).pleaseEnterName),
                              backgroundColor: context.brand.danger,
                            ),
                          );
                          return;
                        } else if (_phoneController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(S.of(context).pleaseEnterPhone),
                              backgroundColor: context.brand.danger,
                            ),
                          );
                          return;
                        } else if (_emailController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(S.of(context).pleaseEnterEmail),
                              backgroundColor: context.brand.danger,
                            ),
                          );
                          return;
                        } else if (_passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  S.of(context).pleaseEnterPasswordPeriod),
                              backgroundColor: context.brand.danger,
                            ),
                          );
                          return;
                        }
                        return AppNavigator.push(
                          context,
                          BlocProvider(
                            create: (context) => ButtonCubit(),
                            child: GenderAndAgePage(
                              userCreationReq: UserCreationReq(
                                name: _nameController.text,
                                phone: _phoneController.text,
                                email: _emailController.text,
                                password: _passwordController.text,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Text(S.of(context).continueLabel),
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
    );
  }
}
