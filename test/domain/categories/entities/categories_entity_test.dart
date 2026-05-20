import 'dart:convert';

import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CategoriesEntity buildEntity() {
    return CategoriesEntity(
      id: 'c1',
      title: 'Shoes',
      image: 'shoes.png',
    );
  }

  test('toMap returns expected fields', () {
    final entity = buildEntity();

    final map = entity.toMap();

    expect(map['id'], 'c1');
    expect(map['title'], 'Shoes');
    expect(map['image'], 'shoes.png');
  });

  test('fromMap maps all fields', () {
    final entity = CategoriesEntity.fromMap({
      'id': 'c2',
      'title': 'Hats',
      'image': 'hats.png',
    });

    expect(entity.id, 'c2');
    expect(entity.title, 'Hats');
    expect(entity.image, 'hats.png');
  });

  test('toJson and fromJson roundtrip values', () {
    final entity = buildEntity();

    final encoded = entity.toJson();
    final decoded = json.decode(encoded) as Map<String, dynamic>;
    final fromJson = CategoriesEntity.fromJson(encoded);

    expect(decoded['id'], 'c1');
    expect(fromJson.id, 'c1');
    expect(fromJson.title, 'Shoes');
    expect(fromJson.image, 'shoes.png');
  });
}
