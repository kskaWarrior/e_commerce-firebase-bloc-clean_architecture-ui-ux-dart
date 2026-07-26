import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/source/sales_firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../helpers/test_tenant.dart';

void main() {
  late SalesFirebaseServiceImpl service;

  setUp(() {
    service = SalesFirebaseServiceImpl(unavailableTenantCollections());
  });

  test('getSalesByUserId returns Left when Firestore is unavailable', () async {
    final result = await service.getSalesByUserId('u1');

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (_) => ''), 'Failed to load sales. Please try again.');
  });

  test('registerSale returns Left when Firestore is unavailable', () async {
    final result = await service.registerSale({
      'id': 's1',
      'userId': 'u1',
      'userName': 'John',
      'productsList': const [
        {
          'productId': 'p1',
          'title': 'Sneaker',
          'quantity': 1,
          'unitPrice': 100,
          'unitDiscounted': 80,
          'totalPrice': 80,
        }
      ],
    });

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (_) => ''), 'Failed to register sale. Please try again.');
  });
}
