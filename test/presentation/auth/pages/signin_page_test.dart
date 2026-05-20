import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders signin page core widgets', (tester) async {
    await tester.pumpWidget(wrap(const SigninPage()));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(RichText), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows error when email is empty', (tester) async {
    await tester.pumpWidget(wrap(const SigninPage()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter your email.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows error when email is invalid', (tester) async {
    await tester.pumpWidget(wrap(const SigninPage()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'invalid-email');
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('prefills email when initialEmail is provided', (tester) async {
    await tester
        .pumpWidget(wrap(const SigninPage(initialEmail: 'john@doe.com')));
    await tester.pump(const Duration(milliseconds: 100));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'john@doe.com');
  });

  testWidgets('trims initialEmail before filling the field', (tester) async {
    await tester
        .pumpWidget(wrap(const SigninPage(initialEmail: '  john@doe.com  ')));
    await tester.pump(const Duration(milliseconds: 100));

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'john@doe.com');
  });

  testWidgets('shows lockout message when email is locked', (tester) async {
    final lockedUntil =
        DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;

    SharedPreferences.setMockInitialValues({
      'signin_failed_attempts_john@doe.com': 5,
      'signin_locked_until_john@doe.com': lockedUntil,
    });

    await tester.pumpWidget(wrap(const SigninPage()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'john@doe.com');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This email is temporarily locked.'),
        findsOneWidget);
  });

  testWidgets('navigates to password page when email is valid and unlocked',
      (tester) async {
    await tester.pumpWidget(wrap(const SigninPage()));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.enterText(find.byType(TextField), 'john@doe.com');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(PasswordPage), findsOneWidget);
  });

}
