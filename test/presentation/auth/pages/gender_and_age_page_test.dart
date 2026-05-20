import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/gender_and_age.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignupUseCase extends Mock implements SignupUseCase {}

class FakeUserCreationReq extends Fake implements UserCreationReq {}

void main() {
  late MockSignupUseCase mockSignupUseCase;

  setUpAll(() {
    registerFallbackValue(FakeUserCreationReq());
  });

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  setUp(() {
    sl.reset();
    mockSignupUseCase = MockSignupUseCase();
    sl.registerSingleton<SignupUseCase>(mockSignupUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders gender and age page core UI', (tester) async {
    await tester.pumpWidget(
      wrap(
        GenderAndAgePage(
          userCreationReq: UserCreationReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2. Just one step away from the best offers!'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows validation when address is empty', (tester) async {
    await tester.pumpWidget(
      wrap(
        GenderAndAgePage(
          userCreationReq: UserCreationReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('Please enter your address.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('gender chip selection changes selected chip', (tester) async {
    await tester.pumpWidget(
      wrap(
        GenderAndAgePage(
          userCreationReq: UserCreationReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    ChoiceChip femaleBefore = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Female'),
    );
    expect(femaleBefore.selected, isFalse);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Female'));
    await tester.pump();

    ChoiceChip femaleAfter = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Female'),
    );
    expect(femaleAfter.selected, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows error snackbar when signup usecase fails', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockSignupUseCase.call(any()))
        .thenAnswer((_) async => Left(Failure(error: 'signup failed')));

    await tester.pumpWidget(
      wrap(
        GenderAndAgePage(
          userCreationReq: UserCreationReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'Main Street 1');
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.text('signup failed'), findsOneWidget);
  });

  testWidgets('navigates to signin page when signup succeeds', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockSignupUseCase.call(any()))
        .thenAnswer((_) async => const Right('Profile created'));

    await tester.pumpWidget(
      wrap(
        GenderAndAgePage(
          userCreationReq: UserCreationReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(find.byType(TextField), 'Main Street 1');
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    expect(find.byType(SigninPage), findsOneWidget);
  });
}
