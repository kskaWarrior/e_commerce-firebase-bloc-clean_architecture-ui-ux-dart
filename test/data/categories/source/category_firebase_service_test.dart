import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/categories/source/category_firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CategoryFirebaseServiceImpl service;

  setUp(() {
    service = CategoryFirebaseServiceImpl();
  });

  test('getCategories returns Left when Firestore is unavailable', () async {
    final result = await service.getCategories();

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l, (_) => ''), contains('Error fetching categories'));
  });
}
