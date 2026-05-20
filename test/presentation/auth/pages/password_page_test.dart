import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders password page and sign in button', (tester) async {
    await tester.pumpWidget(
      wrap(
        PasswordPage(
          userSigninReq: UserSigninReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Welcome back to'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows validation when password is empty', (tester) async {
    await tester.pumpWidget(
      wrap(
        PasswordPage(
          userSigninReq: UserSigninReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Please enter your password'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('toggle password visibility works', (tester) async {
    await tester.pumpWidget(
      wrap(
        PasswordPage(
          userSigninReq: UserSigninReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    TextField field = tester.widget(find.byType(TextField));
    expect(field.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    field = tester.widget(find.byType(TextField));
    expect(field.obscureText, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows session expired message and returns to signin when request is null',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const PasswordPage(
          userSigninReq: null,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 150));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Sign-in session expired. Please try again.'), findsOneWidget);
    expect(find.byType(SigninPage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
