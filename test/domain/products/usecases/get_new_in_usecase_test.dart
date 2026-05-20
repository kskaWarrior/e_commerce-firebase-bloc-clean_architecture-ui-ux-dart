import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/repository/products_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_new_in_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockProductsRepository extends Mock implements ProductsRepository {}

void main() {
  late MockProductsRepository mockProductsRepository;
  late GetNewInProductsUseCase useCase;

  setUp(() {
    sl.reset();
    mockProductsRepository = MockProductsRepository();
    sl.registerSingleton<ProductsRepository>(mockProductsRepository);
    useCase = GetNewInProductsUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('gets new in products', () async {
    when(() => mockProductsRepository.getNewIn())
        .thenAnswer((_) async => const Right(['p3']));

    final result = await useCase.call(null);

    expect(result, const Right(['p3']));
    verify(() => mockProductsRepository.getNewIn()).called(1);
  });

  test('returns left value when repository fails', () async {
    when(() => mockProductsRepository.getNewIn())
        .thenAnswer((_) async => const Left('timeout'));

    final result = await useCase.call(null);

    expect(result, const Left('timeout'));
  });
}
