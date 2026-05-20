import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password_forgot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders forgot password page core widgets', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    
    await tester.pumpWidget(wrap(const ForgotPasswordPage()));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('recover your password'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows validation when email is empty', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(wrap(const ForgotPasswordPage()));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.ensureVisible(find.text('Reset Password'));
    await tester.tap(find.text('Reset Password'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
