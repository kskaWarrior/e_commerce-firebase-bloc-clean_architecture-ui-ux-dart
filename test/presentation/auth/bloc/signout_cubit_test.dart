import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  late MockSignOutUseCase mockUseCase;

  setUp(() async {
    await sl.reset();
    mockUseCase = MockSignOutUseCase();
    sl.registerSingleton<SignOutUseCase>(mockUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  blocTest<SignOutCubit, SignOutState>(
    'emits [SignOutLoading, SignOutSuccess] when sign out succeeds',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => const Right('Logout successful!'));
      return SignOutCubit();
    },
    act: (cubit) => cubit.signOut(),
    expect: () => [
      isA<SignOutLoading>(),
      isA<SignOutSuccess>()
          .having((state) => state.message, 'message', 'Logout successful!'),
    ],
  );

  blocTest<SignOutCubit, SignOutState>(
    'emits [SignOutLoading, SignOutFailure] when sign out fails',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => Left(Failure(error: 'error')));
      return SignOutCubit();
    },
    act: (cubit) => cubit.signOut(),
    expect: () => [
      isA<SignOutLoading>(),
      isA<SignOutFailure>()
          .having((state) => state.error, 'error', 'error: error'),
    ],
  );
}
