import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/button_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockUseCase extends Mock implements UseCase {}

void main() {
  late ButtonCubit cubit;
  late MockUseCase mockUseCase;

  setUp(() {
    cubit = ButtonCubit();
    mockUseCase = MockUseCase();
  });

  tearDown(() {
    cubit.close();
  });

  blocTest<ButtonCubit, ButtonState>(
    'emits [LoadingState, SuccessState] when use case returns Right',
    build: () {
      when(() => mockUseCase.call('params'))
          .thenAnswer((_) async => const Right('ok'));
      return cubit;
    },
    act: (cubit) => cubit.execute(params: 'params', useCase: mockUseCase),
    expect: () => [
      isA<LoadingState>(),
      isA<SuccessState>().having((state) => state.message, 'message', 'ok'),
    ],
  );

  blocTest<ButtonCubit, ButtonState>(
    'emits [LoadingState, FailureState] when use case returns Left',
    build: () {
      when(() => mockUseCase.call('params')).thenAnswer(
        (_) async => Left(Failure(error: 'failed')),
      );
      return cubit;
    },
    act: (cubit) => cubit.execute(params: 'params', useCase: mockUseCase),
    expect: () => [
      isA<LoadingState>(),
      isA<FailureState>().having((state) => state.error, 'error', 'error: failed'),
    ],
  );

  blocTest<ButtonCubit, ButtonState>(
    'emits [LoadingState, FailureState] when use case throws',
    build: () {
      when(() => mockUseCase.call(any())).thenThrow(Exception('boom'));
      return cubit;
    },
    act: (cubit) => cubit.execute(params: 'params', useCase: mockUseCase),
    expect: () => [
      isA<LoadingState>(),
      isA<FailureState>(),
    ],
  );
}
