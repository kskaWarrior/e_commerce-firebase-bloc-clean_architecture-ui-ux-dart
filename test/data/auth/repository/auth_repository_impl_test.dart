import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/repository/auth_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/source/firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/upload_profile_image.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseService extends Mock implements FirebaseService {}

void main() {
  late MockFirebaseService mockFirebaseService;
  late AuthRepositoryImpl repository;

  setUp(() {
    sl.reset();
    mockFirebaseService = MockFirebaseService();
    sl.registerSingleton<FirebaseService>(mockFirebaseService);
    repository = AuthRepositoryImpl();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('getUser maps UserModel to UserEntity', () async {
    final userModel = UserModel(
      id: 'u1',
      email: 'user@mail.com',
      address: 'Street 1',
      phone: '123',
      name: 'User',
      birthDate: DateTime(1995, 4, 10),
      gender: 'male',
      profileImageUrl: 'http://img',
    );

    when(() => mockFirebaseService.getUser())
        .thenAnswer((_) async => Right(userModel));

    final result = await repository.getUser();

    expect(result.isRight(), true);
    result.fold(
      (_) => fail('Expected Right but got Left'),
      (entity) {
        expect(entity.id, 'u1');
        expect(entity.email, 'user@mail.com');
        expect(entity.name, 'User');
        expect(entity.profileImageUrl, 'http://img');
      },
    );
    verify(() => mockFirebaseService.getUser()).called(1);
  });

  test('getUser forwards failure from firebase service', () async {
    final failure = Failure(error: 'permission-denied');

    when(() => mockFirebaseService.getUser())
        .thenAnswer((_) async => Left(failure));

    final result = await repository.getUser();

    expect(result.isLeft(), true);
    expect(result.fold((error) => error.error, (_) => ''), 'permission-denied');
    verify(() => mockFirebaseService.getUser()).called(1);
  });

  test('signIn delegates to firebase service', () async {
    final request = UserSigninReq(email: 'user@mail.com', password: 'secret');
    when(() => mockFirebaseService.signIn(request))
        .thenAnswer((_) async => const Right('signed in'));

    final result = await repository.signIn(request);

    expect(result.isRight(), true);
    expect(result.getOrElse(() => ''), 'signed in');
    verify(() => mockFirebaseService.signIn(request)).called(1);
  });

  test('signUp delegates to firebase service', () async {
    final request = UserCreationReq(
      email: 'new@mail.com',
      password: 'secret',
      name: 'New User',
    );
    when(() => mockFirebaseService.signUp(request))
        .thenAnswer((_) async => const Right('signed up'));

    final result = await repository.signUp(request);

    expect(result.isRight(), true);
    expect(result.getOrElse(() => ''), 'signed up');
    verify(() => mockFirebaseService.signUp(request)).called(1);
  });

  test('updateUser delegates to firebase service', () async {
    final request = UserCreationReq(
      id: 'u1',
      email: 'updated@mail.com',
      name: 'Updated User',
      phone: '123',
      address: 'Street',
      gender: 'male',
      birthDate: DateTime(2000, 1, 1),
    );
    when(() => mockFirebaseService.updateUser(request))
        .thenAnswer((_) async => const Right('updated'));

    final result = await repository.updateUser(request);

    expect(result.isRight(), true);
    expect(result.getOrElse(() => ''), 'updated');
    verify(() => mockFirebaseService.updateUser(request)).called(1);
  });

  test('signOut delegates to firebase service', () async {
    when(() => mockFirebaseService.signOut())
        .thenAnswer((_) async => const Right('signed out'));

    final result = await repository.signOut();

    expect(result.isRight(), true);
    expect(result.getOrElse(() => ''), 'signed out');
    verify(() => mockFirebaseService.signOut()).called(1);
  });

  test('sendPasswordEmailResetUseCase delegates to firebase service', () async {
    when(() =>
            mockFirebaseService.sendPasswordEmailResetUseCase('user@mail.com'))
        .thenAnswer((_) async => const Right('reset sent'));

    final result =
        await repository.sendPasswordEmailResetUseCase('user@mail.com');

    expect(result.isRight(), true);
    expect(result.getOrElse(() => ''), 'reset sent');
    verify(() =>
            mockFirebaseService.sendPasswordEmailResetUseCase('user@mail.com'))
        .called(1);
  });

  test('uploadProfileImage delegates to firebase service', () async {
    final params = UploadProfileImageParams(
      bytes: Uint8List.fromList(const <int>[1, 2, 3]),
      contentType: 'image/png',
    );
    when(() => mockFirebaseService.uploadProfileImage(params))
        .thenAnswer((_) async => const Right('uploaded'));

    final result = await repository.uploadProfileImage(params);

    expect(result.isRight(), true);
    expect(result.getOrElse(() => ''), 'uploaded');
    verify(() => mockFirebaseService.uploadProfileImage(params)).called(1);
  });

  test('isLoggedIn delegates to firebase service', () async {
    when(() => mockFirebaseService.isLoggedIn()).thenAnswer((_) async => true);

    final result = await repository.isLoggedIn();

    expect(result, isTrue);
    verify(() => mockFirebaseService.isLoggedIn()).called(1);
  });
}
