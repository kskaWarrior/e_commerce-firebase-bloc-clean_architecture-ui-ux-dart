import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signup.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late SignupUseCase useCase;

  setUp(() async {
    await sl.reset();
    mockRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockRepository);
    useCase = SignupUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('returns success when sign up succeeds', () async {
    final req = UserCreationReq(email: 'john@doe.com', password: 'pass1234');

    when(() => mockRepository.signUp(req))
        .thenAnswer((_) async => const Right('Created user with success!'));

    final result = await useCase.call(req);

    expect(result, isA<Right<Failure, String>>());
    expect(result.fold((_) => '', (value) => value), 'Created user with success!');
    verify(() => mockRepository.signUp(req)).called(1);
  });

  test('returns failure when sign up fails', () async {
    final req = UserCreationReq(email: 'john@doe.com', password: 'weak');

    when(() => mockRepository.signUp(req))
        .thenAnswer((_) async => Left(Failure(error: 'Weak password')));

    final result = await useCase.call(req);

    expect(result.isLeft(), true);
    expect(result.fold((failure) => failure.error, (_) => ''), 'Weak password');
    verify(() => mockRepository.signUp(req)).called(1);
  });
}
