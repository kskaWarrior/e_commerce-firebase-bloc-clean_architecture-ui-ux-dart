import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

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

}
