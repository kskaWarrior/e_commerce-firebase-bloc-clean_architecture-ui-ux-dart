import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/repository/sales_repository.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/register_sale.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesRepository extends Mock implements SalesRepository {}

void main() {
  late MockSalesRepository mockSalesRepository;
  late RegisterSaleUseCase useCase;

  SalesEntity buildSale() {
    return SalesEntity(
      createdDate: Timestamp.fromDate(DateTime(2025, 1, 1)),
      discountedPrice: 80,
      freight: 10,
      id: 'sale-1',
      installmentsNumber: 1,
      paymentMethod: 'Debit card',
      price: 100,
      productsList: const [
        {'id': 'p1', 'title': 'Sneaker', 'quantity': 1}
      ],
      totalPrice: 90,
      userBirthDate: Timestamp.fromDate(DateTime(1990, 1, 1)),
      userGender: 'male',
      userId: 'u1',
      userName: 'John',
    );
  }

  setUp(() {
    sl.reset();
    mockSalesRepository = MockSalesRepository();
    sl.registerSingleton<SalesRepository>(mockSalesRepository);
    useCase = RegisterSaleUseCase();
  });

  tearDown(() async {
    await sl.reset();
  });

  test('registers sale through repository', () async {
    final sale = buildSale();

    when(() => mockSalesRepository.registerSale(sale))
        .thenAnswer((_) async => const Right('ok'));

    final result = await useCase.call(sale);

    expect(result, const Right('ok'));
    verify(() => mockSalesRepository.registerSale(sale)).called(1);
  });

  test('returns left value when repository fails', () async {
    final sale = buildSale();

    when(() => mockSalesRepository.registerSale(sale))
        .thenAnswer((_) async => const Left('failed'));

    final result = await useCase.call(sale);

    expect(result, const Left('failed'));
  });
}
