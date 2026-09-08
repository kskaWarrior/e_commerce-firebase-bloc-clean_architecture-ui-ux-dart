import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/entities/store_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/list_stores.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/admin/auth/pages/select_store_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListStoresUseCase extends Mock implements ListStoresUseCase {}

void main() {
  late _MockListStoresUseCase mockListStores;

  StoreEntity buildStore(String id, String name, {String status = 'active'}) {
    return StoreEntity(
      id: id,
      name: name,
      status: status,
      plan: 'free',
      ownerUid: 'owner-$id',
      branding: const <String, dynamic>{},
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: SelectStorePage()));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    await sl.reset();
    mockListStores = _MockListStoresUseCase();
    sl.registerSingleton<ListStoresUseCase>(mockListStores);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('lists the stores the platform owner can manage',
      (tester) async {
    when(() => mockListStores.call(null)).thenAnswer(
      (_) async => Right([
        buildStore('buybuy', 'BuyBuy'),
        buildStore('acme', 'Acme Shop', status: 'suspended'),
      ]),
    );

    await pump(tester);

    expect(find.text('BuyBuy'), findsOneWidget);
    expect(find.text('buybuy'), findsOneWidget);
    expect(find.text('Acme Shop'), findsOneWidget);
    // A non-active store says so next to its id.
    expect(find.text('acme · suspended'), findsOneWidget);
    // The free-text field is no longer the primary control.
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('falls back to manual entry when the listing fails',
      (tester) async {
    when(() => mockListStores.call(null))
        .thenAnswer((_) async => const Left('permission-denied'));

    await pump(tester);

    expect(find.text('Could not load the store list.'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('manual entry stays reachable when the listing succeeds',
      (tester) async {
    when(() => mockListStores.call(null))
        .thenAnswer((_) async => Right([buildStore('buybuy', 'BuyBuy')]));

    await pump(tester);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Enter a store ID instead'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('shows an empty state when there are no stores', (tester) async {
    when(() => mockListStores.call(null))
        .thenAnswer((_) async => const Right(<StoreEntity>[]));

    await pump(tester);

    expect(find.text('No stores yet.'), findsOneWidget);
  });
}
