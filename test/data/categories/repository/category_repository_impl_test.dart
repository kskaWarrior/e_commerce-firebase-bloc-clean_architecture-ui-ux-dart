import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/repository/category_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/source/category_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryFirebaseService extends Mock implements CategoryFirebaseService {}

void main() {
  late MockCategoryFirebaseService mockCategoryFirebaseService;
  late CategoryRepositoryImpl repository;

  setUp(() {
    sl.reset();
    mockCategoryFirebaseService = MockCategoryFirebaseService();
    sl.registerSingleton<CategoryFirebaseService>(mockCategoryFirebaseService);
    repository = CategoryRepositoryImpl();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('maps category maps into category entities', () async {
    when(() => mockCategoryFirebaseService.getCategories()).thenAnswer(
      (_) async => const Right([
        {'id': 'c1', 'title': 'Shoes', 'image': 'shoes.png'},
        {'id': 'c2', 'title': 'Hats', 'image': 'hats.png'},
      ]),
    );

    final result = await repository.getCategories();

    expect(result.isRight(), isTrue);
    final mapped = result.fold((_) => <CategoriesEntity>[], (right) => right as List<CategoriesEntity>);
    expect(mapped.length, 2);
    expect(mapped.first.id, 'c1');
    expect(mapped.first.title, 'Shoes');
  });

  test('returns left when firebase service fails', () async {
    when(() => mockCategoryFirebaseService.getCategories())
        .thenAnswer((_) async => const Left('firebase error'));

    final result = await repository.getCategories();

    expect(result, const Left('firebase error'));
  });
}
