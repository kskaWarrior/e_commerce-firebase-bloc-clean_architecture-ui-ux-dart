import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/is_logged_in.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIsLoggedInUseCase extends Mock implements IsLoggedInUseCase {}

void main() {
  late MockIsLoggedInUseCase mockUseCase;

  setUp(() async {
    await sl.reset();
    mockUseCase = MockIsLoggedInUseCase();
    sl.registerSingleton<IsLoggedInUseCase>(mockUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  blocTest<SplashCubit, SplashState>(
    'emits [Authenticated] when user is logged in',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => const Right(true));
      return SplashCubit();
    },
    act: (cubit) => cubit.appStarted(),
    expect: () => [
      isA<Authenticated>(),
    ],
  );

  blocTest<SplashCubit, SplashState>(
    'emits [UnAuthenticated] when user is not logged in',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => const Right(false));
      return SplashCubit();
    },
    act: (cubit) => cubit.appStarted(),
    expect: () => [
      isA<UnAuthenticated>(),
    ],
  );

  blocTest<SplashCubit, SplashState>(
    'emits [UnAuthenticated] when use case returns failure',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => Left(Failure(error: 'error')));
      return SplashCubit();
    },
    act: (cubit) => cubit.appStarted(),
    expect: () => [
      isA<UnAuthenticated>(),
    ],
  );
}
