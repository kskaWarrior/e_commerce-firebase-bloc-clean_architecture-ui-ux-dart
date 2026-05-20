import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/repository_impl/products_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/source/products_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsFirebaseService extends Mock implements ProductsFirebaseService {}

void main() {
  late MockProductsFirebaseService mockProductsFirebaseService;
  late ProductsRepositoryImpl repository;

  Map<String, dynamic> productMap({required String id, required String title}) {
    return {
      'categoryName': 'Shoes',
      'id': id,
      'currentDiscount': 10,
      'categoryId': 'c1',
      'colors': [
        {'title': 'Black', 'hexCode': '#000000'}
      ],
      'createdDate': Timestamp.fromDate(DateTime(2025, 1, 1)),
      'discountedPrice': 90,
      'gender': 'unisex',
      'images': ['img.png'],
      'price': 100,
      'sizes': ['M'],
      'title': title,
      'productId': id,
      'salesNumber': 50,
      'description': 'desc',
    };
  }

  setUp(() {
    sl.reset();
    mockProductsFirebaseService = MockProductsFirebaseService();
    sl.registerSingleton<ProductsFirebaseService>(mockProductsFirebaseService);
    repository = ProductsRepositoryImpl();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('getTopSelling maps service payload into entities', () async {
    when(() => mockProductsFirebaseService.getTopSelling()).thenAnswer(
      (_) async => Right([
        productMap(id: 'p1', title: 'Runner'),
        productMap(id: 'p2', title: 'Boot'),
      ]),
    );

    final result = await repository.getTopSelling();

    expect(result.isRight(), isTrue);
    final products = result.fold((_) => <ProductEntity>[], (right) => right as List<ProductEntity>);
    expect(products.length, 2);
    expect(products.first.id, 'p1');
    expect(products.first.title, 'Runner');
  });

  test('getTopSelling returns left when service returns left', () async {
    when(() => mockProductsFirebaseService.getTopSelling())
        .thenAnswer((_) async => const Left('service error'));

    final result = await repository.getTopSelling();

    expect(result, const Left('service error'));
  });

  test('getTopSelling catches parsing exceptions', () async {
    when(() => mockProductsFirebaseService.getTopSelling())
        .thenAnswer((_) async => const Right([{'id': 'invalid-only'}]));

    final result = await repository.getTopSelling();

    expect(result.isLeft(), isTrue);
    final error = result.fold((left) => left.toString(), (_) => '');
    expect(error, contains('Failed to parse top selling products'));
  });

  test('getNewIn maps service payload into entities', () async {
    when(() => mockProductsFirebaseService.getNewIn()).thenAnswer(
      (_) async => Right([productMap(id: 'p3', title: 'Fresh Drop')]),
    );

    final result = await repository.getNewIn();

    expect(result.isRight(), isTrue);
    final products = result.fold((_) => <ProductEntity>[], (right) => right as List<ProductEntity>);
    expect(products.length, 1);
    expect(products.first.id, 'p3');
  });

  test('getNewIn returns left when service returns left', () async {
    when(() => mockProductsFirebaseService.getNewIn())
        .thenAnswer((_) async => const Left('query failed'));

    final result = await repository.getNewIn();

    expect(result, const Left('query failed'));
  });

  test('getNewIn catches parsing exceptions', () async {
    when(() => mockProductsFirebaseService.getNewIn())
        .thenAnswer((_) async => const Right([{'id': 'broken'}]));

    final result = await repository.getNewIn();

    expect(result.isLeft(), isTrue);
    final error = result.fold((left) => left.toString(), (_) => '');
    expect(error, contains('Failed to parse new in products'));
  });
}
