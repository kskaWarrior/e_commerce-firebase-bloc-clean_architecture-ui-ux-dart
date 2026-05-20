import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/sales/models/sales_model.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validMap() {
    final ts = Timestamp.fromDate(DateTime(2025, 1, 1));
    return {
      'createdDate': ts,
      'discountedPrice': 90,
      'freight': 10,
      'id': 's1',
      'installmentsNumber': 2,
      'paymentMethod': 'Credit card',
      'price': 100,
      'productsList': [
        {'id': 'p1', 'title': 'Shoe'}
      ],
      'totalPrice': 100,
      'userBirthDate': ts,
      'userGender': 'male',
      'userId': 'u1',
      'userName': 'John',
    };
  }

  test('fromMap handles fallback values for malformed fields', () {
    final model = SalesModel.fromMap({'id': 's1', 'productsIds': 'invalid'});

    expect(model.id, 's1');
    expect(model.installmentsNumber, 1);
    expect(model.paymentMethod, 'Unknown');
    expect(model.productsList, isEmpty);
  });

  test('toMap and toEntity keep values from valid map', () {
    final model = SalesModel.fromMap(validMap());

    final map = model.toMap();
    final entity = model.toEntity();

    expect(map['id'], 's1');
    expect((map['productsList'] as List).length, 1);
    expect(entity.userId, 'u1');
    expect(entity.productsList.first['title'], 'Shoe');
  });

  test('fromEntity maps sales entity back to model', () {
    final ts = Timestamp.fromDate(DateTime(2025, 1, 1));
    final entity = SalesEntity(
      createdDate: ts,
      discountedPrice: 90,
      freight: 10,
      id: 's1',
      installmentsNumber: 2,
      paymentMethod: 'Credit card',
      price: 100,
      productsList: const [
        {'id': 'p1', 'title': 'Shoe'}
      ],
      totalPrice: 100,
      userBirthDate: ts,
      userGender: 'male',
      userId: 'u1',
      userName: 'John',
    );

    final model = SalesModel.fromEntity(entity);

    expect(model.id, 's1');
    expect(model.installmentsNumber, 2);
    expect(model.userName, 'John');
  });
}
