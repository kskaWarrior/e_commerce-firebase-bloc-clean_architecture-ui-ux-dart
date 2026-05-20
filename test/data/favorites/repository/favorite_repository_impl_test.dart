import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/repository/favorite_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/source/favorites_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFavoritesFirebaseService extends Mock implements FavoritesFirebaseService {}

void main() {
  late MockFavoritesFirebaseService mockService;
  late FavoriteRepositoryImpl repository;

  setUp(() async {
    await sl.reset();
    mockService = MockFavoritesFirebaseService();
    sl.registerSingleton<FavoritesFirebaseService>(mockService);
    repository = FavoriteRepositoryImpl();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('getFavoritesByUserId maps raw maps into entities', () async {
    final ts = Timestamp.fromDate(DateTime(2025, 1, 1));
    final raw = [
      {
        'createdDate': ts,
        'id': 'f1',
        'productId': 'p1',
        'userId': 'u1',
      }
    ];

    when(() => mockService.getFavoritesByUserId('u1'))
        .thenAnswer((_) async => Right(raw));

    final result = await repository.getFavoritesByUserId('u1');

    expect(result.isRight(), true);
    result.fold(
      (_) => fail('Expected Right but got Left'),
      (favorites) {
        expect((favorites as List).length, 1);
        final FavoriteEntity first = favorites.first as FavoriteEntity;
        expect(first.id, 'f1');
        expect(first.productId, 'p1');
      },
    );
    verify(() => mockService.getFavoritesByUserId('u1')).called(1);
  });

  test('getFavoritesByUserId forwards service failure', () async {
    when(() => mockService.getFavoritesByUserId('u1'))
        .thenAnswer((_) async => const Left('Failed to load favorites. Please try again.'));

    final result = await repository.getFavoritesByUserId('u1');

    expect(result, const Left('Failed to load favorites. Please try again.'));
  });

  test('registerFavorite converts entity to map and forwards to service', () async {
    final favorite = FavoriteEntity(
      createdDate: Timestamp.fromDate(DateTime(2025, 1, 1)),
      id: 'f1',
      productId: 'p1',
      userId: 'u1',
    );

    when(() => mockService.registerFavorite(any()))
        .thenAnswer((_) async => const Right('Favorite registered successfully!'));

    final result = await repository.registerFavorite(favorite);

    expect(result, const Right('Favorite registered successfully!'));
    verify(() => mockService.registerFavorite(any())).called(1);
  });

  test('deleteFavorite forwards to service', () async {
    when(() => mockService.deleteFavorite('u1', 'p1'))
        .thenAnswer((_) async => const Right('Favorite removed successfully!'));

    final result = await repository.deleteFavorite('u1', 'p1');

    expect(result, const Right('Favorite removed successfully!'));
    verify(() => mockService.deleteFavorite('u1', 'p1')).called(1);
  });
}
