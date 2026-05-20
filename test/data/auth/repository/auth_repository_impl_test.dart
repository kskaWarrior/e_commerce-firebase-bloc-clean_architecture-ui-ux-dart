import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/repository/auth_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/source/firebase_service.dart';
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
}
