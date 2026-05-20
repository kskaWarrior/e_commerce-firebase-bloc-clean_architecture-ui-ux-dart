import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/repository/products_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_top_selling_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late MockProductsRepository mockProductsRepository;
  late GetTopSellingProductsUseCase useCase;

  setUp(() {
    sl.reset();
    mockProductsRepository = MockProductsRepository();
    sl.registerSingleton<ProductsRepository>(mockProductsRepository);
    useCase = GetTopSellingProductsUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('gets top selling products', () async {
    when(() => mockProductsRepository.getTopSelling())
        .thenAnswer((_) async => const Right(['p1', 'p2']));

    final result = await useCase.call(null);

    expect(result, const Right(['p1', 'p2']));
    verify(() => mockProductsRepository.getTopSelling()).called(1);
  });

  test('returns left value when repository fails', () async {
    when(() => mockProductsRepository.getTopSelling())
        .thenAnswer((_) async => const Left('network'));

    final result = await useCase.call(null);

    expect(result, const Left('network'));
  });
}
