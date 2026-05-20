import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/repository/sales_repository_impl.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/source/sales_firebase_service.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSalesFirebaseService extends Mock implements SalesFirebaseService {}

void main() {
  late MockSalesFirebaseService mockService;
  late SalesRepositoryImpl repository;

  setUp(() async {
    await sl.reset();
    mockService = MockSalesFirebaseService();
    sl.registerSingleton<SalesFirebaseService>(mockService);
    repository = SalesRepositoryImpl();
  });

  tearDown(() async {
    await sl.reset();
  });

  SalesEntity buildSaleEntity() {
    final ts = Timestamp.fromDate(DateTime(2025, 1, 1));
    return SalesEntity(
      createdDate: ts,
      discountedPrice: 10,
      freight: 5,
      id: 's1',
      installmentsNumber: 1,
      paymentMethod: 'pix',
      price: 15,
      productsList: const [
        {
          'productId': 'p1',
          'title': 'Tee',
          'quantity': 1,
          'unitPrice': 15,
          'unitDiscounted': 10,
          'totalPrice': 10,
        }
      ],
      totalPrice: 15,
      userBirthDate: ts,
      userGender: 'male',
      userId: 'u1',
      userName: 'John',
    );
  }

  Map<String, dynamic> buildSaleMap() {
    final ts = Timestamp.fromDate(DateTime(2025, 1, 1));
    return {
      'createdDate': ts,
      'discountedPrice': 10,
      'freight': 5,
      'id': 's1',
      'installmentsNumber': 1,
      'paymentMethod': 'pix',
      'price': 15,
      'productsList': const [
        {
          'productId': 'p1',
          'title': 'Tee',
          'quantity': 1,
          'unitPrice': 15,
          'unitDiscounted': 10,
          'totalPrice': 10,
        }
      ],
      'totalPrice': 15,
      'userBirthDate': ts,
      'userGender': 'male',
      'userId': 'u1',
      'userName': 'John',
    };
  }

  test('getSalesByUserId maps raw sales maps into entities', () async {
    when(() => mockService.getSalesByUserId('u1'))
        .thenAnswer((_) async => Right([buildSaleMap()]));

    final result = await repository.getSalesByUserId('u1');

    expect(result.isRight(), true);
    result.fold(
      (_) => fail('Expected Right but got Left'),
      (sales) {
        expect((sales as List).length, 1);
        // ignore: non_constant_identifier_names
        final Sale = sales.first as SalesEntity;
        expect(Sale.id, 's1');
        expect(Sale.userId, 'u1');
      },
    );
    verify(() => mockService.getSalesByUserId('u1')).called(1);
  });

  test('getSalesByUserId returns parsing error for malformed sales data', () async {
    when(() => mockService.getSalesByUserId('u1'))
        .thenAnswer((_) async => Right([
              {1: 'invalid-key-type'}
            ]));

    final result = await repository.getSalesByUserId('u1');

    expect(result, const Left('Failed to parse purchases data. Please try again.'));
  });

  test('getSalesByUserId forwards service failure', () async {
    when(() => mockService.getSalesByUserId('u1'))
        .thenAnswer((_) async => const Left('Failed to load sales. Please try again.'));

    final result = await repository.getSalesByUserId('u1');

    expect(result, const Left('Failed to load sales. Please try again.'));
  });

  test('registerSale converts entity to map and forwards to service', () async {
    final sale = buildSaleEntity();

    when(() => mockService.registerSale(any()))
        .thenAnswer((_) async => const Right('Sale registered successfully!'));

    final result = await repository.registerSale(sale);

    expect(result, const Right('Sale registered successfully!'));
    verify(() => mockService.registerSale(any())).called(1);
  });
}
