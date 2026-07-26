import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/configs/brand/brand_config.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Per-brand [FirebaseOptions] for the shared Firebase project.
///
/// All brands live in ONE Firebase project; only the app registration
/// (appId/apiKey, one per applicationId/bundleId) differs per brand and is
/// injected via brand.json dart-defines. Project-level constants stay in the
/// generated [DefaultFirebaseOptions], which is also the fallback when no
/// brand defines are present (e.g. the admin web build).
class BrandFirebaseOptions {
  BrandFirebaseOptions._();

  static const String _projectId = 'ecommerceapp-auth-db-cleana';
  static const String _messagingSenderId = '502375403738';
  static const String _storageBucket =
      'ecommerceapp-auth-db-cleana.firebasestorage.app';

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return DefaultFirebaseOptions.currentPlatform;
    }
  }

  static FirebaseOptions get android {
    if (BrandConfig.firebaseAndroidAppId.isEmpty) {
      return DefaultFirebaseOptions.android;
    }
    return FirebaseOptions(
      apiKey: BrandConfig.firebaseAndroidApiKey,
      appId: BrandConfig.firebaseAndroidAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
    );
  }

  static FirebaseOptions get ios {
    if (BrandConfig.firebaseIosAppId.isEmpty) {
      return DefaultFirebaseOptions.ios;
    }
    return FirebaseOptions(
      apiKey: BrandConfig.firebaseIosApiKey,
      appId: BrandConfig.firebaseIosAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
      iosBundleId: const String.fromEnvironment('IOS_BUNDLE_ID'),
    );
  }

  static FirebaseOptions get web {
    if (BrandConfig.firebaseWebAppId.isEmpty) {
      return DefaultFirebaseOptions.web;
    }
    return FirebaseOptions(
      apiKey: BrandConfig.firebaseWebApiKey,
      appId: BrandConfig.firebaseWebAppId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket,
      authDomain: '$_projectId.firebaseapp.com',
    );
  }
}
