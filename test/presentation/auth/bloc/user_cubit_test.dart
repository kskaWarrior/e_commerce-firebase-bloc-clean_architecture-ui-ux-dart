import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUserUseCase extends Mock implements GetUserUseCase {}

void main() {
  late MockGetUserUseCase mockUseCase;

  setUp(() async {
    await sl.reset();
    mockUseCase = MockGetUserUseCase();
    sl.registerSingleton<GetUserUseCase>(mockUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  blocTest<UserCubit, UserState>(
    'emits [UserLoading, UserLoaded] when get user succeeds',
    build: () {
      final user = UserEntity(
        id: 'u1',
        email: 'john@doe.com',
        address: 'Street',
        phone: '123',
        name: 'John',
        birthDate: DateTime(1990, 1, 1),
        gender: 'male',
      );
      when(() => mockUseCase.call(null)).thenAnswer((_) async => Right(user));
      return UserCubit();
    },
    act: (cubit) => cubit.getUser(),
    expect: () => [
      isA<UserLoading>(),
      isA<UserLoaded>().having((state) => state.user.id, 'user id', 'u1'),
    ],
  );

  blocTest<UserCubit, UserState>(
    'emits [UserLoading, UserError] when get user fails',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => Left(Failure(error: 'permission-denied')));
      return UserCubit();
    },
    act: (cubit) => cubit.getUser(),
    expect: () => [
      isA<UserLoading>(),
      isA<UserError>()
          .having((state) => state.error, 'error', 'error: permission-denied'),
    ],
  );
}
