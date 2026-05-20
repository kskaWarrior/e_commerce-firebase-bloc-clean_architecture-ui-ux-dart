import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

void main() {
  late MockGetCategoriesUseCase mockUseCase;

  setUp(() async {
    await sl.reset();
    mockUseCase = MockGetCategoriesUseCase();
    sl.registerSingleton<GetCategoriesUseCase>(mockUseCase);
  });

  tearDown(() async {
    await sl.reset();
  });

  blocTest<CategoriesCubit, CategoriesState>(
    'emits [CategoriesLoading, CategoriesLoaded] when load succeeds',
    build: () {
      final categories = [
        CategoriesEntity(id: '1', title: 'Shoes', image: 'img.png'),
      ];
      when(() => mockUseCase.call(null)).thenAnswer((_) async => Right(categories));
      return CategoriesCubit();
    },
    act: (cubit) => cubit.loadCategories(),
    expect: () => [
      isA<CategoriesLoading>(),
      isA<CategoriesLoaded>()
          .having((state) => state.categories.length, 'categories length', 1),
    ],
  );

  blocTest<CategoriesCubit, CategoriesState>(
    'emits [CategoriesLoading, CategoriesError] when load fails',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => Left(Failure(error: 'offline')));
      return CategoriesCubit();
    },
    act: (cubit) => cubit.loadCategories(),
    expect: () => [
      isA<CategoriesLoading>(),
      isA<CategoriesError>()
          .having((state) => state.message, 'message', 'error: offline'),
    ],
  );
}
