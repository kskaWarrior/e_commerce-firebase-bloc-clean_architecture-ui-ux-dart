import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/color_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/firebase_auth_test_mocks.dart';

class MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

void main() {
  late MockFavoritesCubit mockFavoritesCubit;

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  Future<void> pumpProductPage(
    WidgetTester tester, {
    required ProductEntity product,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(wrap(ProductPage(product: product)));
    await tester.pumpAndSettle();
  }

  ProductEntity buildProduct({
    List<dynamic>? sizes,
    List<ProductColorEntity>? colors,
    List<dynamic>? images,
    num price = 100,
    num discountedPrice = 80,
  }) {
    return ProductEntity(
      categoryName: 'Shoes',
      id: 'p1',
      currentDiscount: 20,
      categoryId: 'c1',
      colors: colors ??
          [
            ProductColorEntity(title: 'Black', hexCode: '#000000'),
            ProductColorEntity(title: 'Blue', hexCode: '#0000FF'),
          ],
      createdDate: Timestamp.fromDate(DateTime(2025, 1, 1)),
      discountedPrice: discountedPrice,
      gender: 'unisex',
      images: images ?? const ['image.jpg'],
      price: price,
      sizes: sizes ?? const ['40', '42'],
      title: 'Runner Pro',
      productId: 'RP-001',
      salesNumber: 120,
      description: 'Comfortable running shoe',
    );
  }

  setUp(() async {
    await setupFirebaseCoreMocks();
    await setupFirebaseAuthMocks(uid: null);
    await sl.reset();
    CartDraftStore.instance.clear();

    mockFavoritesCubit = MockFavoritesCubit();
    when(() => mockFavoritesCubit.state).thenReturn(FavoritesInitial());
    when(() => mockFavoritesCubit.loadFavoritesByUserId(any()))
        .thenAnswer((_) async {});

    sl.registerSingleton<FavoritesCubit>(mockFavoritesCubit);
  });

  tearDown(() async {
    CartDraftStore.instance.clear();
    await sl.reset();
  });

  testWidgets('renders key product information', (tester) async {
    await pumpProductPage(tester, product: buildProduct());

    expect(find.text('Product details'), findsOneWidget);
    expect(find.text('Runner Pro'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Sizes'), findsOneWidget);
    expect(find.text('Colors'), findsOneWidget);
    expect(find.text('Add to cart'), findsOneWidget);
  });

  testWidgets('increments and decrements quantity without going below one',
      (tester) async {
    await pumpProductPage(tester, product: buildProduct());

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add).last);
    await tester.pump();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove).last);
    await tester.pump();
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove).last);
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('allows selecting and toggling size and color options',
      (tester) async {
    await pumpProductPage(tester, product: buildProduct());

    await tester.tap(find.text('42'));
    await tester.pump();
    await tester.tap(find.text('42'));
    await tester.pump();

    await tester.tap(find.text('Blue'));
    await tester.pump();
    await tester.tap(find.text('Blue'));
    await tester.pump();

    expect(find.text('42'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
  });

  testWidgets('shows placeholders when sizes, colors and images are missing',
      (tester) async {
    await pumpProductPage(
      tester,
      product: buildProduct(
        sizes: const [],
        colors: const [],
        images: const [],
      ),
    );

    expect(find.text('No sizes available'), findsOneWidget);
    expect(find.text('No colors available'), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });

  testWidgets('shows sign in snackbar when adding to cart while logged out',
      (tester) async {
    await pumpProductPage(tester, product: buildProduct());

    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    expect(
      find.text('Please sign in to add products to cart.'),
      findsOneWidget,
    );
    expect(CartDraftStore.instance.itemsCount, 0);
  });

  testWidgets('shows sign in snackbar when toggling favorite while logged out',
      (tester) async {
    await pumpProductPage(tester, product: buildProduct());

    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();

    expect(find.text('Please sign in to manage favorites.'), findsOneWidget);
  });
}
