import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart'
  as firebase_core_test;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _authChannel = MethodChannel('plugins.flutter.io/firebase_auth');
const MethodChannel _authChannelAlt =
  MethodChannel('plugins.flutter.io/firebase_auth/firebase_auth');
bool _firebaseInitialized = false;

const FirebaseOptions _testOptions = FirebaseOptions(
  apiKey: 'test-api-key',
  appId: '1:1234567890:android:testappid',
  messagingSenderId: '1234567890',
  projectId: 'test-project',
);

Future<void> setupFirebaseCoreMocks() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  firebase_core_test.setupFirebaseCoreMocks();

  if (!_firebaseInitialized) {
    try {
      await Firebase.initializeApp(options: _testOptions);
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        rethrow;
      }
    }
    _firebaseInitialized = true;
  }
}

Future<void> setupFirebaseAuthMocks({
  required String? uid,
  String email = 'john@doe.com',
  String displayName = 'John',
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<dynamic> authHandler(MethodCall methodCall) async {
    switch (methodCall.method) {
      case 'Auth#registerAuthStateListener':
      case 'Auth#registerIdTokenListener':
      case 'Auth#registerStateListener':
        return 'test-listener';
      case 'Auth#unregisterListener':
      case 'Auth#setLanguageCode':
      case 'Auth#useEmulator':
      case 'Auth#signOut':
        return null;
      case 'Auth#currentUser':
      case 'Auth#getCurrentUser':
        if (uid == null || uid.isEmpty) {
          return null;
        }
        return {
          'uid': uid,
          'email': email,
          'displayName': displayName,
          'isAnonymous': false,
          'isEmailVerified': true,
          'metadata': {
            'creationTime': 0,
            'lastSignInTime': 0,
          },
          'providerData': <Map<String, dynamic>>[],
          'refreshToken': 'test-refresh-token',
          'tenantId': null,
          'phoneNumber': null,
          'photoURL': null,
        };
      default:
        return null;
    }
  }

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_authChannel, authHandler);

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_authChannelAlt, authHandler);
}
