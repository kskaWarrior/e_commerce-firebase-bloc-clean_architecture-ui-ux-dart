import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/repository/favorite_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/get_favorites_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFavoriteRepository extends Mock implements FavoriteRepository {}

void main() {
  late MockFavoriteRepository mockFavoriteRepository;
  late GetFavoritesByUserIdUseCase useCase;

  setUp(() {
    sl.reset();
    mockFavoriteRepository = MockFavoriteRepository();
    sl.registerSingleton<FavoriteRepository>(mockFavoriteRepository);
    useCase = GetFavoritesByUserIdUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('gets favorites for the provided user id', () async {
    when(() => mockFavoriteRepository.getFavoritesByUserId('u1'))
        .thenAnswer((_) async => const Right(['favorite']));

    final result = await useCase.call('u1');

    expect(result, const Right(['favorite']));
    verify(() => mockFavoriteRepository.getFavoritesByUserId('u1')).called(1);
  });

  test('returns left value when repository fails', () async {
    when(() => mockFavoriteRepository.getFavoritesByUserId('u2'))
        .thenAnswer((_) async => const Left('db error'));

    final result = await useCase.call('u2');

    expect(result, const Left('db error'));
  });
}
