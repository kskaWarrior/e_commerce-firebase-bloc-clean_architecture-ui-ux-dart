import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/repository/category_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository mockRepository;
  late GetCategoriesUseCase useCase;

  setUp(() {
    sl.reset();
    mockRepository = MockCategoryRepository();
    sl.registerSingleton<CategoryRepository>(mockRepository);
    useCase = GetCategoriesUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('returns categories when repository succeeds', () async {
    final categories = [
      {'id': '1', 'title': 'Shoes'}
    ];

    when(() => mockRepository.getCategories())
        .thenAnswer((_) async => Right(categories));

    final result = await useCase.call(null);

    expect(result.isRight(), true);
    verify(() => mockRepository.getCategories()).called(1);
  });

  test('returns Failure when repository fails', () async {
    when(() => mockRepository.getCategories())
        .thenAnswer((_) async => Left(Failure(error: 'db error')));

    final result = await useCase.call(null);

    expect(result.isLeft(), true);
    expect(result.fold((f) => f.toString(), (_) => ''), 'error: db error');
    verify(() => mockRepository.getCategories()).called(1);
  });
}
