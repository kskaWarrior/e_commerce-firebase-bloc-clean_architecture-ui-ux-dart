import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/repository/sales_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

void main() {
  late MockSalesRepository mockSalesRepository;
  late GetSalesByUserIdUseCase useCase;

  setUp(() {
    sl.reset();
    mockSalesRepository = MockSalesRepository();
    sl.registerSingleton<SalesRepository>(mockSalesRepository);
    useCase = GetSalesByUserIdUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('gets sales list for a user id', () async {
    when(() => mockSalesRepository.getSalesByUserId('u1'))
        .thenAnswer((_) async => const Right(['sale1']));

    final result = await useCase.call('u1');

    expect(result, const Right(['sale1']));
    verify(() => mockSalesRepository.getSalesByUserId('u1')).called(1);
  });

  test('returns left value when repository fails', () async {
    when(() => mockSalesRepository.getSalesByUserId('u2'))
        .thenAnswer((_) async => const Left('error'));

    final result = await useCase.call('u2');

    expect(result, const Left('error'));
  });
}
