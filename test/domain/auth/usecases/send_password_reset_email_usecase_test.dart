import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/send_password_reset_email.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SendPasswordEmailResetUseCase useCase;

  setUp(() async {
    await sl.reset();
    mockRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockRepository);
    useCase = SendPasswordEmailResetUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('returns success message when reset email succeeds', () async {
    const email = 'john@doe.com';

    when(() => mockRepository.sendPasswordEmailResetUseCase(email))
        .thenAnswer((_) async => const Right('Password reset email sent!'));

    final result = await useCase.call(email);

    expect(result.isRight(), true);
    expect(result.fold((_) => '', (value) => value), 'Password reset email sent!');
    verify(() => mockRepository.sendPasswordEmailResetUseCase(email)).called(1);
  });

  test('returns failure when reset email fails', () async {
    const email = 'john@doe.com';

    when(() => mockRepository.sendPasswordEmailResetUseCase(email))
        .thenAnswer((_) async => Left(Failure(error: 'User not found')));

    final result = await useCase.call(email);

    expect(result.isLeft(), true);
    expect(result.fold((failure) => failure.error, (_) => ''), 'User not found');
    verify(() => mockRepository.sendPasswordEmailResetUseCase(email)).called(1);
  });
}
