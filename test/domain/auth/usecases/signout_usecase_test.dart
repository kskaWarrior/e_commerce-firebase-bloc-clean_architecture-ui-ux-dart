import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignOutUseCase useCase;

  setUp(() async {
    await sl.reset();
    mockRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockRepository);
    useCase = SignOutUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('returns success message when sign out succeeds', () async {
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => const Right('Logout successful!'));

    final result = await useCase.call(null);

    expect(result, const Right<Failure, String>('Logout successful!'));
    verify(() => mockRepository.signOut()).called(1);
  });

  test('returns failure when sign out fails', () async {
    when(() => mockRepository.signOut())
        .thenAnswer((_) async => Left(Failure(error: 'Unknown error')));

    final result = await useCase.call(null);

    expect(result.isLeft(), true);
    expect(result.fold((failure) => failure.error, (_) => ''), 'Unknown error');
    verify(() => mockRepository.signOut()).called(1);
  });
}
