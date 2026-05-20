import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/gender_and_age.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  Future<void> waitTypewriterToFinish(WidgetTester tester) async {
    // Name(4), Phone(5), Email(5), Password(8) at 50ms each + delayed steps.
    await tester.pump(const Duration(seconds: 3));
  }

  testWidgets('renders signup page fields and button', (tester) async {
    await tester.pumpWidget(wrap(const SignUpPage()));
    await waitTypewriterToFinish(tester);

    expect(find.byType(TextField), findsNWidgets(4));
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Only two steps!'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows validation when name is empty', (tester) async {
    await tester.pumpWidget(wrap(const SignUpPage()));
    await waitTypewriterToFinish(tester);

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter your name.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows validation when phone is empty', (tester) async {
    await tester.pumpWidget(wrap(const SignUpPage()));
    await waitTypewriterToFinish(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'John');

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter your phone number.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows validation when email is empty', (tester) async {
    await tester.pumpWidget(wrap(const SignUpPage()));
    await waitTypewriterToFinish(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'John');
    await tester.enterText(fields.at(1), '999999');

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter your email.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows validation when password is empty', (tester) async {
    await tester.pumpWidget(wrap(const SignUpPage()));
    await waitTypewriterToFinish(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'John');
    await tester.enterText(fields.at(1), '999999');
    await tester.enterText(fields.at(2), 'john@doe.com');

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Please enter your password.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('toggle password visibility works', (tester) async {
    await tester.pumpWidget(wrap(const SignUpPage()));
    await waitTypewriterToFinish(tester);

    final passwordField = tester.widgetList<TextField>(find.byType(TextField)).last;
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    final passwordFieldAfter = tester.widgetList<TextField>(find.byType(TextField)).last;
    expect(passwordFieldAfter.obscureText, isFalse);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('navigates to gender and age page when all fields are valid',
      (tester) async {
    await tester.pumpWidget(wrap(const SignUpPage()));
    await waitTypewriterToFinish(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'John');
    await tester.enterText(fields.at(1), '999999');
    await tester.enterText(fields.at(2), 'john@doe.com');
    await tester.enterText(fields.at(3), '123456');

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(GenderAndAgePage), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
