import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/products/source/products_firebase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProductsFirebaseServiceImpl service;

  setUp(() {
    service = ProductsFirebaseServiceImpl();
  });

  test('getTopSelling returns Left when Firestore is unavailable', () async {
    final result = await service.getTopSelling();

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l.toString(), (_) => ''), contains('Top selling query failed'));
  });

  test('getNewIn returns Left when Firestore is unavailable', () async {
    final result = await service.getNewIn();

    expect(result.isLeft(), isTrue);
    expect(result.fold((l) => l.toString(), (_) => ''), contains('New in query failed'));
  });
}
