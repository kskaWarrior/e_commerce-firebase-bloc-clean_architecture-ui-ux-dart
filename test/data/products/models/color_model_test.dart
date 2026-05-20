import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/models/color_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap and toMap preserve values', () {
    final map = {'title': 'Red', 'hexCode': '#FF0000'};

    final model = ProductColorModel.fromMap(map);

    expect(model.title, 'Red');
    expect(model.hexCode, '#FF0000');
    expect(model.toMap(), map);
  });

  test('toEntity maps fields', () {
    final model = ProductColorModel(title: 'Blue', hexCode: '#0000FF');

    final entity = model.toEntity();

    expect(entity.title, 'Blue');
    expect(entity.hexCode, '#0000FF');
  });

  test('toJson/fromJson roundtrip', () {
    final model = ProductColorModel(title: 'Green', hexCode: '#00FF00');

    final json = model.toJson();
    final rebuilt = ProductColorModel.fromJson(json);

    expect(rebuilt.title, model.title);
    expect(rebuilt.hexCode, model.hexCode);
  });
}
