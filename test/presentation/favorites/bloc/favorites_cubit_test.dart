import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/delete_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/get_favorites_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/register_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetFavoritesByUserIdUseCase extends Mock
    implements GetFavoritesByUserIdUseCase {}

class MockRegisterFavoriteUseCase extends Mock implements RegisterFavoriteUseCase {}

class MockDeleteFavoriteUseCase extends Mock implements DeleteFavoriteUseCase {}

class FakeDeleteFavoriteParams extends Fake implements DeleteFavoriteParams {}

void main() {
  late MockGetFavoritesByUserIdUseCase mockGetFavoritesByUserIdUseCase;
  late MockRegisterFavoriteUseCase mockRegisterFavoriteUseCase;
  late MockDeleteFavoriteUseCase mockDeleteFavoriteUseCase;
  late FavoriteEntity favoriteForRegister;

  FavoriteEntity buildFavorite() {
    return FavoriteEntity(
      createdDate: Timestamp.fromDate(DateTime(2025, 1, 1)),
      id: 'f1',
      productId: 'p1',
      userId: 'u1',
    );
  }

  setUp(() {
    registerFallbackValue(FakeDeleteFavoriteParams());
    mockGetFavoritesByUserIdUseCase = MockGetFavoritesByUserIdUseCase();
    mockRegisterFavoriteUseCase = MockRegisterFavoriteUseCase();
    mockDeleteFavoriteUseCase = MockDeleteFavoriteUseCase();
    favoriteForRegister = buildFavorite();
  });

  blocTest<FavoritesCubit, FavoritesState>(
    'emits [FavoritesLoading, FavoritesLoaded] when load succeeds',
    build: () {
      when(() => mockGetFavoritesByUserIdUseCase.call('u1'))
          .thenAnswer((_) async => Right([buildFavorite()]));
      return FavoritesCubit(
        getFavoritesByUserIdUseCase: mockGetFavoritesByUserIdUseCase,
        registerFavoriteUseCase: mockRegisterFavoriteUseCase,
        deleteFavoriteUseCase: mockDeleteFavoriteUseCase,
      );
    },
    act: (cubit) => cubit.loadFavoritesByUserId('u1'),
    expect: () => [
      isA<FavoritesLoading>(),
      isA<FavoritesLoaded>()
          .having((state) => state.favorites.length, 'favorites length', 1),
    ],
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'emits [FavoritesRegisterLoading, FavoritesRegisterSuccess] when register succeeds',
    build: () {
      when(() => mockRegisterFavoriteUseCase.call(favoriteForRegister))
          .thenAnswer((_) async => const Right('ok'));
      return FavoritesCubit(
        getFavoritesByUserIdUseCase: mockGetFavoritesByUserIdUseCase,
        registerFavoriteUseCase: mockRegisterFavoriteUseCase,
        deleteFavoriteUseCase: mockDeleteFavoriteUseCase,
      );
    },
    act: (cubit) => cubit.registerFavorite(favoriteForRegister),
    expect: () => [
      isA<FavoritesRegisterLoading>(),
      isA<FavoritesRegisterSuccess>()
          .having((state) => state.message, 'message', 'ok'),
    ],
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'emits [FavoritesDeleteLoading, FavoritesDeleteSuccess] when delete succeeds',
    build: () {
      when(() => mockDeleteFavoriteUseCase.call(any()))
          .thenAnswer((_) async => const Right('deleted'));
      return FavoritesCubit(
        getFavoritesByUserIdUseCase: mockGetFavoritesByUserIdUseCase,
        registerFavoriteUseCase: mockRegisterFavoriteUseCase,
        deleteFavoriteUseCase: mockDeleteFavoriteUseCase,
      );
    },
    act: (cubit) => cubit.deleteFavorite('u1', 'p1'),
    expect: () => [
      isA<FavoritesDeleteLoading>(),
      isA<FavoritesDeleteSuccess>()
          .having((state) => state.message, 'message', 'deleted'),
    ],
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'emits [FavoritesLoading, FavoritesError] when load fails',
    build: () {
      when(() => mockGetFavoritesByUserIdUseCase.call('u1'))
          .thenAnswer((_) async => Left(Failure(error: 'db')));
      return FavoritesCubit(
        getFavoritesByUserIdUseCase: mockGetFavoritesByUserIdUseCase,
        registerFavoriteUseCase: mockRegisterFavoriteUseCase,
        deleteFavoriteUseCase: mockDeleteFavoriteUseCase,
      );
    },
    act: (cubit) => cubit.loadFavoritesByUserId('u1'),
    expect: () => [
      isA<FavoritesLoading>(),
      isA<FavoritesError>()
          .having((state) => state.message, 'message', 'error: db'),
    ],
  );
}
