import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/utils/usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsUseCase extends Mock implements UseCase {}

void main() {
  late MockProductsUseCase mockUseCase;

  setUp(() {
    mockUseCase = MockProductsUseCase();
  });

  ProductEntity buildProduct() {
    return ProductEntity(
      categoryName: 'Shoes',
      id: '1',
      currentDiscount: 0,
      categoryId: 'c1',
      colors: const [],
      createdDate: Timestamp.fromDate(DateTime(2024, 1, 1)),
      discountedPrice: 100,
      gender: 'unisex',
      images: const [],
      price: 100,
      sizes: const [],
      title: 'Sneaker',
      productId: 'p1',
      salesNumber: 5,
      description: 'desc',
    );
  }

  blocTest<ProductsDisplayCubit, ProductsDisplayState>(
    'emits [Loading, Loaded] when products load succeeds',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => Right([buildProduct()]));
      return ProductsDisplayCubit(mockUseCase);
    },
    act: (cubit) => cubit.displayProducts(),
    expect: () => [
      isA<ProductsDisplayLoading>(),
      isA<ProductsDisplayLoaded>()
          .having((state) => state.products.length, 'products length', 1),
    ],
  );

  blocTest<ProductsDisplayCubit, ProductsDisplayState>(
    'emits [Loading, Error] when products load fails',
    build: () {
      when(() => mockUseCase.call(null))
          .thenAnswer((_) async => Left(Failure(error: 'db error')));
      return ProductsDisplayCubit(mockUseCase);
    },
    act: (cubit) => cubit.displayProducts(),
    expect: () => [
      isA<ProductsDisplayLoading>(),
      isA<ProductsDisplayError>()
          .having((state) => state.message, 'message', 'error: db error'),
    ],
  );
}
