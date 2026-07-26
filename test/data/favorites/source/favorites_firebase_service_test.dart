import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/favorites/source/favorites_firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_tenant.dart';

void main() {
  late FavoritesFirebaseServiceImpl service;

  setUp(() {
    service = FavoritesFirebaseServiceImpl(unavailableTenantCollections());
  });

  test('getFavoritesByUserId returns Left when Firestore is unavailable', () async {
    final result = await service.getFavoritesByUserId('u1');

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (_) => ''), 'Failed to load favorites. Please try again.');
  });

  test('registerFavorite returns Left when Firestore is unavailable', () async {
    final result = await service.registerFavorite({'userId': 'u1', 'productId': 'p1'});

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (_) => ''), 'Failed to register favorite. Please try again.');
  });

  test('deleteFavorite returns Left when Firestore is unavailable', () async {
    final result = await service.deleteFavorite('u1', 'p1');

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (_) => ''), 'Failed to remove favorite. Please try again.');
  });
}
