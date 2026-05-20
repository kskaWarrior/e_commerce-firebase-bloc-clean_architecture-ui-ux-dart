import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/models/categories_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap and toMap preserve values', () {
    final map = {'id': 'c1', 'title': 'Shoes', 'image': 'shoes.png'};

    final model = CategoriesModel.fromMap(map);

    expect(model.id, 'c1');
    expect(model.title, 'Shoes');
    expect(model.image, 'shoes.png');
    expect(model.toMap(), map);
  });

  test('toEntity maps fields correctly', () {
    final model = CategoriesModel(id: 'c1', title: 'Shoes', image: 'shoes.png');

    final entity = model.toEntity();

    expect(entity.id, 'c1');
    expect(entity.title, 'Shoes');
    expect(entity.image, 'shoes.png');
  });

  test('toJson/fromJson roundtrip', () {
    final model = CategoriesModel(id: 'c1', title: 'Shoes', image: 'shoes.png');

    final json = model.toJson();
    final rebuilt = CategoriesModel.fromJson(json);

    expect(rebuilt.id, model.id);
    expect(rebuilt.title, model.title);
    expect(rebuilt.image, model.image);
  });
}
