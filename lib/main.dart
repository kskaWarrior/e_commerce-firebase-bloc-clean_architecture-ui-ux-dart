import 'dart:async';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/theme/app_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_locale_controller.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/firebase_brand_options.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_route_observer.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/pages/splash.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      BrandConfig.requireStoreId();
      await Firebase.initializeApp(
          options: BrandFirebaseOptions.currentPlatform);

      // Local development against the Firebase Emulator Suite:
      // --dart-define=USE_EMULATORS=true (and EMULATOR_HOST=10.0.2.2 on the
      // Android emulator).
      const useEmulators = bool.fromEnvironment('USE_EMULATORS');
      if (useEmulators) {
        const emulatorHost =
            String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
        await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
        FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8085);
        await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
      }

      // Keep app launch path lean to avoid startup stalls/ANR on CI devices.
      unawaited(
        FirebasePerformance.instance
            .setPerformanceCollectionEnabled(!kDebugMode)
            .timeout(const Duration(seconds: 3))
            .catchError((_) {}),
      );

      if (!kDebugMode) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      await init();
      await AppLocaleController.instance
          .restore()
          .timeout(const Duration(seconds: 3), onTimeout: () {})
          .catchError((_) {});
      runApp(const MyApp());

      unawaited(
        CartDraftStore.instance
            .restore()
            .timeout(const Duration(seconds: 3), onTimeout: () {})
            .catchError((_) {}),
      );
    },
    (error, stack) {
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        Zone.current.handleUncaughtError(error, stack);
      }
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<SplashCubit>()..appStarted(),
      child: AnimatedBuilder(
        animation: AppLocaleController.instance,
        builder: (context, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(AppTheme.defaultTheme),
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          locale: AppLocaleController.instance.locale,
          supportedLocales: AppLocaleController.supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          navigatorObservers: [appRouteObserver],
          home: const SplashPage(),
        ),
      ),
    );
  }
}
