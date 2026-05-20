import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_signin_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;
  late SigninUseCase useCase;

  setUp(() {
    sl.reset();
    mockAuthRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockAuthRepository);
    useCase = SigninUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('returns success message when sign in succeeds', () async {
    final params = UserSigninReq(email: 'john@doe.com', password: 'pass1234');

    when(() => mockAuthRepository.signIn(params))
        .thenAnswer((_) async => const Right('Login with success!'));

    final result = await useCase(params);

    expect(result, isA<Right<Failure, String>>());
    expect(result.fold((_) => '', (data) => data), 'Login with success!');
    verify(() => mockAuthRepository.signIn(params)).called(1);
  });

  test('returns Failure when sign in fails', () async {
    final params = UserSigninReq(email: 'john@doe.com', password: 'wrong');
    final failure = Failure(error: 'invalid-credential');

    when(() => mockAuthRepository.signIn(params))
        .thenAnswer((_) async => Left(failure));

    final result = await useCase(params);

    expect(result, isA<Left<Failure, String>>());
    expect(result.fold((error) => error.error, (_) => ''), 'invalid-credential');
    verify(() => mockAuthRepository.signIn(params)).called(1);
  });
}
