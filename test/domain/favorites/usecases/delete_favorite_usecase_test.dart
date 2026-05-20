import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/repository/favorite_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/delete_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

void main() {
  late MockFavoriteRepository mockRepository;
  late DeleteFavoriteUseCase useCase;

  setUp(() {
    sl.reset();
    mockRepository = MockFavoriteRepository();
    sl.registerSingleton<FavoriteRepository>(mockRepository);
    useCase = DeleteFavoriteUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('calls repository with correct user and product ids', () async {
    const userId = 'u1';
    const productId = 'p1';

    when(() => mockRepository.deleteFavorite(userId, productId))
        .thenAnswer((_) async => const Right('deleted'));

    final result = await useCase.call(
      DeleteFavoriteParams(userId: userId, productId: productId),
    );

    expect(result, const Right('deleted'));
    verify(() => mockRepository.deleteFavorite(userId, productId)).called(1);
  });

  test('returns failure when repository fails', () async {
    when(() => mockRepository.deleteFavorite('u1', 'p1'))
        .thenAnswer((_) async => Left(Failure(error: 'not found')));

    final result = await useCase.call(
      DeleteFavoriteParams(userId: 'u1', productId: 'p1'),
    );

    expect(result.isLeft(), true);
    expect(result.fold((f) => f.toString(), (_) => ''), 'error: not found');
  });
}
