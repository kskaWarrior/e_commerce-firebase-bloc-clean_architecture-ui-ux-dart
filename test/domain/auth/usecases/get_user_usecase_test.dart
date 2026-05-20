import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late GetUserUseCase useCase;

  setUp(() async {
    await sl.reset();
    mockRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockRepository);
    useCase = GetUserUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('returns user when repository succeeds', () async {
    final user = UserEntity(
      id: 'u1',
      email: 'john@doe.com',
      address: 'Street',
      phone: '123',
      name: 'John',
      birthDate: DateTime(1990, 1, 1),
      gender: 'male',
      profileImageUrl: 'img',
    );

    when(() => mockRepository.getUser()).thenAnswer((_) async => Right(user));

    final result = await useCase.call(null);

    expect(result.isRight(), true);
    expect(result.fold((_) => null, (value) => value.id), 'u1');
    verify(() => mockRepository.getUser()).called(1);
  });

  test('returns failure when repository fails', () async {
    when(() => mockRepository.getUser())
        .thenAnswer((_) async => Left(Failure(error: 'permission-denied')));

    final result = await useCase.call(null);

    expect(result.isLeft(), true);
    expect(result.fold((failure) => failure.error, (_) => ''), 'permission-denied');
    verify(() => mockRepository.getUser()).called(1);
  });
}
