import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/i18n/app_locale_controller.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/firebase_options.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/theme/admin_theme.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/auth/admin_session.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/router/admin_router.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

/// Admin web entrypoint. One shared deployment serves every tenant: the
/// store an owner manages comes from their auth claim at login, so this
/// build needs NO --dart-define brand file.
///
/// Run: flutter run -d chrome -t lib/main_admin.dart
/// Build: flutter build web -t lib/main_admin.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  const useEmulators = bool.fromEnvironment('USE_EMULATORS');
  if (useEmulators) {
    const emulatorHost =
        String.fromEnvironment('EMULATOR_HOST', defaultValue: 'localhost');
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8085);
    await FirebaseStorage.instance.useStorageEmulator(emulatorHost, 9199);
  }

  await init();
  sl.registerLazySingleton<AdminSession>(() => AdminSession());
  await AppLocaleController.instance
      .restore()
      .timeout(const Duration(seconds: 3), onTimeout: () {})
      .catchError((_) {});

  runApp(AdminApp(router: buildAdminRouter()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppLocaleController.instance,
      builder: (context, _) => MaterialApp.router(
        title: 'Store Admin',
        debugShowCheckedModeBanner: false,
        theme: AdminTheme.light(),
        locale: AppLocaleController.instance.locale,
        supportedLocales: AppLocaleController.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }
}
