import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/address/models/address_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/update_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/upload_profile_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/my_profile_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUserUseCase extends Mock implements GetUserUseCase {}

class MockUpdateUserUseCase extends Mock implements UpdateUserUseCase {}

class MockUploadProfileImageUseCase extends Mock implements UploadProfileImageUseCase {}

class FakeUserCreationReq extends Fake implements UserCreationReq {}

void main() {
  late MockGetUserUseCase mockGetUserUseCase;
  late MockUpdateUserUseCase mockUpdateUserUseCase;
  late MockUploadProfileImageUseCase mockUploadProfileImageUseCase;

  UserEntity buildUser() {
    return UserEntity(
      id: 'u1',
      email: 'john@doe.com',
      address: 'Street 1',
      addressData: const AddressModel(
        cep: '01310100',
        street: 'Avenida Paulista',
        number: '1000',
        neighborhood: 'Bela Vista',
        city: 'São Paulo',
        state: 'SP',
      ),
      phone: '999999',
      name: 'John',
      birthDate: DateTime(1995, 1, 10),
      gender: 'Male',
      profileImageUrl: '',
    );
  }

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  setUpAll(() {
    registerFallbackValue(FakeUserCreationReq());
  });

  setUp(() async {
    await sl.reset();
    mockGetUserUseCase = MockGetUserUseCase();
    mockUpdateUserUseCase = MockUpdateUserUseCase();
    mockUploadProfileImageUseCase = MockUploadProfileImageUseCase();

    sl.registerSingleton<GetUserUseCase>(mockGetUserUseCase);
    sl.registerSingleton<UpdateUserUseCase>(mockUpdateUserUseCase);
    sl.registerSingleton<UploadProfileImageUseCase>(mockUploadProfileImageUseCase);

    when(() => mockGetUserUseCase.call(null)).thenAnswer((_) async => Right(buildUser()));
    when(() => mockUpdateUserUseCase.call(any()))
        .thenAnswer((_) async => const Right('Profile updated with success!'));
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('loads user profile and shows Save changes button', (tester) async {
    await tester.pumpWidget(wrap(const MyProfilePage()));
    await tester.pumpAndSettle();

    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('john@doe.com'), findsOneWidget);
    expect(find.text('Tap to change photo'), findsOneWidget);
  });

  testWidgets('shows validation when editable fields are empty', (tester) async {
    await tester.pumpWidget(wrap(const MyProfilePage()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), '');
    await tester.enterText(fields.at(2), '');
    await tester.enterText(fields.at(4), '');

    await tester.dragUntilVisible(
      find.text('Save changes'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    expect(find.text('Please fill in all editable fields.'), findsOneWidget);
  });

  testWidgets('saves profile when fields are valid', (tester) async {
    await tester.pumpWidget(wrap(const MyProfilePage()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'John Updated');
    await tester.enterText(fields.at(2), '123456');

    await tester.dragUntilVisible(
      find.text('Save changes'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Save changes'));
    await tester.pump();

    verify(() => mockUpdateUserUseCase.call(any())).called(1);
  });

  testWidgets('toggles password visibility icon', (tester) async {
    await tester.pumpWidget(wrap(const MyProfilePage()));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });

  testWidgets('shows snackbar when loading profile fails', (tester) async {
    when(() => mockGetUserUseCase.call(null))
        .thenAnswer((_) async => Left(Failure(error: 'load failed')));

    await tester.pumpWidget(wrap(const MyProfilePage()));
    await tester.pumpAndSettle();

    expect(find.text('load failed'), findsOneWidget);
  });

  testWidgets('shows snackbar when update profile fails', (tester) async {
    when(() => mockUpdateUserUseCase.call(any()))
        .thenAnswer((_) async => Left(Failure(error: 'update failed')));

    await tester.pumpWidget(wrap(const MyProfilePage()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'John Updated');
    await tester.enterText(fields.at(2), '123456');

    await tester.dragUntilVisible(
      find.text('Save changes'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('update failed'), findsOneWidget);
  });

  testWidgets('sends selected gender and null password when password is empty',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    UserCreationReq? captured;
    when(() => mockUpdateUserUseCase.call(any()))
        .thenAnswer((invocation) async {
      captured = invocation.positionalArguments.first as UserCreationReq;
      return const Right('ok');
    });

    await tester.pumpWidget(wrap(const MyProfilePage()));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Female'));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Female'));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'Jane Updated');
    await tester.enterText(fields.at(2), '123456');
    await tester.enterText(fields.at(3), '');

    await tester.dragUntilVisible(
      find.text('Save changes'),
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.email, 'john@doe.com');
    expect(captured!.gender, 'Female');
    expect(captured!.password, isNull);
  });
}
