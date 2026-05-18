import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrapForTest(Widget child) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Signin shows snackbar when email is empty',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapForTest(const SigninPage()));

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter your email.'), findsOneWidget);
  });

  testWidgets('Signin shows snackbar when email format is invalid',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapForTest(const SigninPage()));

    await tester.enterText(find.byType(TextField).first, 'invalid-email');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });

  testWidgets('Signin navigates to PasswordPage with a valid email',
      (WidgetTester tester) async {
    await tester.pumpWidget(_wrapForTest(const SigninPage()));

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordPage), findsOneWidget);
  });

  testWidgets('PasswordPage recovers when sign-in request is missing',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(_wrapForTest(const PasswordPage(userSigninReq: null)));

    await tester.enterText(find.byType(TextField).first, '123456');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Sign-in session expired. Please try again.'),
        findsOneWidget);
    expect(find.byType(SigninPage), findsOneWidget);
  });
}
