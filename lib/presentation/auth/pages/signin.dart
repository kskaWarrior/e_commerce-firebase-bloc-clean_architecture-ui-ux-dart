import 'dart:async';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/auth/signin_lockout_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_route_observer.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/assets/app_images.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/language_menu.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/brand_tokens.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_strings.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_auth_frame.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class SigninPage extends StatefulWidget {
  final String? initialEmail;

  const SigninPage({super.key, this.initialEmail});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage>
    with SingleTickerProviderStateMixin, RouteAware {
  String get _typewriterText => S.of(context).signInWithYourEmail;
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;
  ModalRoute<dynamic>? _currentRoute;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  Timer? _shakeTimer;
  final SigninLockoutStore _signinLockoutStore = SigninLockoutStore();

  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if ((widget.initialEmail ?? '').trim().isNotEmpty) {
      _emailController.text = widget.initialEmail!.trim();
    }
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
        _restartTypewriter();
      }
    }

    final route = ModalRoute.of(context);
    if (_currentRoute == route || route is! PageRoute) {
      return;
    }

    if (_currentRoute != null) {
      appRouteObserver.unsubscribe(this);
    }

    _currentRoute = route;
    appRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    _restartTypewriter();
  }

  void _restartTypewriter() {
    _timer?.cancel();
    if (!mounted) {
      return;
    }
    setState(() {
      _displayedText = '';
      _currentIndex = 0;
    });
    _startTypewriter();
  }

  void _startTypewriter() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    appRouteObserver.unsubscribe(this);
    _shakeController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Shared submit flow (validation + lockout check + navigation), used by
  /// both the mobile and the web layout.
  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseEnterEmail),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).pleaseEnterValidEmail),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    }

    final lockoutStatus = await _signinLockoutStore.getStatus(email);
    if (!mounted) return;

    if (lockoutStatus.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).emailTemporarilyLocked(
                formatLockoutRemaining(lockoutStatus.remaining)),
          ),
          backgroundColor: context.brand.danger,
        ),
      );
      return;
    }

    if (!mounted) return;
    AppNavigator.push(
      context,
      PasswordPage(userSigninReq: UserSigninReq(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Wide web gets a dedicated storefront-style landing (asset beside a
    // gold glass card); everything else keeps the mobile layout.
    if (kIsWeb && MediaQuery.sizeOf(context).width >= 760) {
      return _buildWebLayout(context);
    }
    return WebAuthFrame.wrap(_buildMobileLayout(context));
  }

  Widget _buildWebLayout(BuildContext context) {
    final brand = context.brand;
    final s = S.of(context);
    final size = MediaQuery.sizeOf(context);
    final twoColumns = size.width >= 1020;
    final assetSize = twoColumns
        ? (size.width * 0.36).clamp(400.0, 600.0).toDouble()
        : (size.height * 0.4).clamp(260.0, 420.0).toDouble();

    // Portuguese shoppers get the translated splash art; fall back to the
    // default (and then to nothing) if a brand ships no localized variant.
    final isPt = Localizations.maybeLocaleOf(context)?.languageCode == 'pt';
    final heroAsset = Image.asset(
      isPt ? AppImages.appSplashPt : AppImages.appSplash,
      width: assetSize,
      height: assetSize,
      errorBuilder: (_, __, ___) => Image.asset(
        AppImages.appSplash,
        width: assetSize,
        height: assetSize,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );

    final card = WebGoldGlassPanel(
      width: 460,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 40, 36, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Image.asset(
                AppImages.brandWordmark,
                height: 36,
                errorBuilder: (_, __, ___) => Text(
                  BrandConfig.appName,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: brand.iconStrong,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Text(
              s.heroWelcome(BrandConfig.appName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
                color: brand.iconStrong,
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 22,
              child: Text(
                _displayedText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.5,
                  color: brand.textPrimary.withOpacity(0.65),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _submitEmail(),
              style: const TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: s.email,
                hintStyle: TextStyle(color: brand.muted),
                prefixIcon:
                    Icon(Icons.email_outlined, color: brand.iconStrong),
                filled: true,
                fillColor: brand.surfaceBright.withOpacity(0.9),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 18, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _submitEmail,
                style: FilledButton.styleFrom(
                  backgroundColor: brand.iconStrong,
                  foregroundColor: brand.textInverse,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(s.continueLabel),
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: RichText(
                text: TextSpan(
                  text: s.dontHaveAccount,
                  style: TextStyle(
                    color: brand.textPrimary,
                    fontSize: 14.5,
                    fontFamily: 'BrandFont',
                  ),
                  children: [
                    TextSpan(
                      text: s.signUpExclamation,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: brand.secondaryVariant,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'BrandFont',
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          AppNavigator.push(context, const SignUpPage());
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Divider(color: brand.iconStrong.withOpacity(0.15), height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.language,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: brand.textPrimary.withOpacity(0.75),
                  ),
                ),
                const LanguageSelectorPill(),
              ],
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: brand.background,
      body: Stack(
        children: [
          const WebBrandBackdrop(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: twoColumns
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        heroAsset,
                        const SizedBox(width: 64),
                        card,
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        heroAsset,
                        const SizedBox(height: 20),
                        card,
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
            final isKeyboardOpen = keyboardInset > 0;
            final formWidth = (screenWidth - 32).clamp(280.0, 420.0).toDouble();
            final horizontalInset = (screenWidth - formWidth) / 2;
            final heroImageSize =
                (screenWidth * 0.9).clamp(260.0, 520.0).toDouble();

            return SingleChildScrollView(
              // This keeps the content at least viewport height, while allowing scroll when needed.
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Stack(
                  children: [
                Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                          SizedBox(height: 80),
                      Image.asset(
                        AppImages.appSplash,
                            width: heroImageSize,
                            height: heroImageSize,
                      ),
                    ],
                  ),
                ),
                Positioned(
                      left: horizontalInset,
                      right: horizontalInset,
                      bottom: isKeyboardOpen ? keyboardInset + 98 : 190,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(16),
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                    ),
                  ),
                ),
                Positioned(
                      left: horizontalInset,
                      right: horizontalInset,
                      bottom: isKeyboardOpen ? keyboardInset + 28 : 120,
                  height: 55,
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
                    onPressed: _submitEmail,
                    child: Text(S.of(context).continueLabel),
                  ),
                ),
                    if (!isKeyboardOpen)
                      Positioned(
                        left: horizontalInset,
                        right: horizontalInset,
                        bottom: 85,
                        child: AnimatedBuilder(
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
                              text: S.of(context).dontHaveAccount,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14.7,
                              ),
                              children: [
                                TextSpan(
                                  text: S.of(context).signUpExclamation,
                                  style: TextStyle(
                                    fontSize: 14.7,
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
                    Positioned(top: 4, right: 4, child: LanguageMenuButton()),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
