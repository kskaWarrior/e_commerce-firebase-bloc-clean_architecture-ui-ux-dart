import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/update_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late UpdateUserUseCase useCase;

  setUp(() async {
    await sl.reset();
    mockRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockRepository);
    useCase = UpdateUserUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('returns success message when update succeeds', () async {
    final req = UserCreationReq(
      email: 'john@doe.com',
      name: 'John',
      phone: '123',
      address: 'Street',
    );

    when(() => mockRepository.updateUser(req))
        .thenAnswer((_) async => const Right('Profile updated with success!'));

    final result = await useCase.call(req);

    expect(result.isRight(), true);
    expect(result.fold((_) => '', (value) => value), 'Profile updated with success!');
    verify(() => mockRepository.updateUser(req)).called(1);
  });

  test('returns failure when update fails', () async {
    final req = UserCreationReq(email: 'john@doe.com');

    when(() => mockRepository.updateUser(req))
        .thenAnswer((_) async => Left(Failure(error: 'User not logged in')));

    final result = await useCase.call(req);

    expect(result.isLeft(), true);
    expect(result.fold((failure) => failure.error, (_) => ''), 'User not logged in');
    verify(() => mockRepository.updateUser(req)).called(1);
  });
}
