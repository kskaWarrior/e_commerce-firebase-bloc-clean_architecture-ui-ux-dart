import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/password.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSigninUseCase extends Mock implements SigninUseCase {}

class FakeUserSigninReq extends Fake implements UserSigninReq {}

void main() {
  late MockSigninUseCase mockSigninUseCase;

  setUpAll(() {
    registerFallbackValue(FakeUserSigninReq());
  });

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await sl.reset();
    mockSigninUseCase = MockSigninUseCase();
    sl.registerSingleton<SigninUseCase>(mockSigninUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

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

  testWidgets('shows forgot password prompt rich text', (tester) async {
    await tester.pumpWidget(
      wrap(
        PasswordPage(
          userSigninReq: UserSigninReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RichText), findsWidgets);
  });

  testWidgets('shows attempts left message for invalid credentials',
      (tester) async {
    when(() => mockSigninUseCase.call(any()))
        .thenAnswer((_) async => Left(Failure(error: 'invalid-credential')));

    await tester.pumpWidget(
      wrap(
        PasswordPage(
          userSigninReq: UserSigninReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Attempts left before lock: 4.'), findsOneWidget);
  });

  testWidgets('shows lock message and navigates when email is already locked',
      (tester) async {
    final lockedUntil =
        DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch;

    SharedPreferences.setMockInitialValues({
      'signin_failed_attempts_john@doe.com': 5,
      'signin_locked_until_john@doe.com': lockedUntil,
    });

    await tester.pumpWidget(
      wrap(
        PasswordPage(
          userSigninReq: UserSigninReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.textContaining('This email is locked. Try again in'),
        findsOneWidget);
    expect(find.byType(SigninPage), findsOneWidget);
  });

  testWidgets('shows generic error for non-credential failures',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockSigninUseCase.call(any()))
        .thenAnswer((_) async => Left(Failure(error: 'service unavailable')));

    await tester.pumpWidget(
      wrap(
        PasswordPage(
          userSigninReq: UserSigninReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('error: service unavailable'), findsOneWidget);
  });

  testWidgets('locks email after threshold invalid credentials and navigates',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    SharedPreferences.setMockInitialValues({
      'signin_failed_attempts_john@doe.com': 4,
    });

    when(() => mockSigninUseCase.call(any()))
        .thenAnswer((_) async => Left(Failure(error: 'invalid-credential')));

    await tester.pumpWidget(
      wrap(
        PasswordPage(
          userSigninReq: UserSigninReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '123456');
    await tester.ensureVisible(find.text('Sign In'));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining(
          'Too many invalid attempts. This email is locked for'),
      findsOneWidget,
    );
    expect(find.byType(SigninPage), findsOneWidget);
  });
}
