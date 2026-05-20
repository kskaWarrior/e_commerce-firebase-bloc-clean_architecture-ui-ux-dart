import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/repository/auth_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/is_logged_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepository;
  late IsLoggedInUseCase useCase;

  setUp(() {
    sl.reset();
    mockRepository = MockAuthRepository();
    sl.registerSingleton<AuthRepository>(mockRepository);
    useCase = IsLoggedInUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('returns Right(true) when repository says logged in', () async {
    when(() => mockRepository.isLoggedIn()).thenAnswer((_) async => true);

    final result = await useCase.call(null);

    expect(result, const Right<Failure, bool>(true));
    verify(() => mockRepository.isLoggedIn()).called(1);
  });

  test('returns Left(Failure) when repository throws', () async {
    when(() => mockRepository.isLoggedIn()).thenThrow(Exception('crash'));

    final result = await useCase.call(null);

    expect(result.isLeft(), true);
    expect(
      result.fold((failure) => failure.toString(), (_) => ''),
      contains('Exception: crash'),
    );
    verify(() => mockRepository.isLoggedIn()).called(1);
  });
}
