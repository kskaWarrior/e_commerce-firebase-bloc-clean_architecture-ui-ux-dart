import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> buildMap() {
    return {
      'categoryName': 'Shoes',
      'id': 'p1',
      'currentDiscount': 10,
      'categoryId': 'c1',
      'colors': [
        {'title': 'Red', 'hexCode': '#FF0000'}
      ],
      'createdDate': Timestamp.fromDate(DateTime(2025, 1, 1)),
      'discountedPrice': 90,
      'gender': 'unisex',
      'images': ['shoe.png'],
      'price': 100,
      'sizes': ['M', 'L'],
      'title': 'Running Shoe',
      'productId': 'sku-1',
      'salesNumber': 12,
      'description': 'desc',
    };
  }

  test('fromMap parses product correctly', () {
    final model = ProductModel.fromMap(buildMap());

    expect(model.id, 'p1');
    expect(model.categoryId, 'c1');
    expect(model.colors.length, 1);
    expect(model.images.first, 'shoe.png');
    expect(model.sizes, ['M', 'L']);
    expect(model.salesNumber, 12);
  });

  test('toEntity maps nested values', () {
    final model = ProductModel.fromMap(buildMap());

    final entity = model.toEntity();

    expect(entity.id, 'p1');
    expect(entity.colors.first.title, 'Red');
    expect(entity.description, 'desc');
  });
}
