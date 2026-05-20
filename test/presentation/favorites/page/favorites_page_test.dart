import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/color_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/page/favorites_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/firebase_auth_test_mocks.dart';

class MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class MockProductsDisplayCubit extends MockCubit<ProductsDisplayState>
    implements ProductsDisplayCubit {}

class MockNewInDisplayCubit extends MockCubit<ProductsDisplayState>
    implements NewInDisplayCubit {}

void main() {
  late MockFavoritesCubit mockFavoritesCubit;
  late MockProductsDisplayCubit mockProductsDisplayCubit;
  late MockNewInDisplayCubit mockNewInDisplayCubit;

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  ProductEntity buildProduct({required String id, required String title}) {
    return ProductEntity(
      categoryName: 'Shoes',
      id: id,
      currentDiscount: 20,
      categoryId: 'c1',
      colors: [
        ProductColorEntity(title: 'Black', hexCode: '#000000'),
      ],
      createdDate: Timestamp.fromDate(DateTime(2025, 1, 1)),
      discountedPrice: 80,
      gender: 'unisex',
      images: const ['image.jpg'],
      price: 100,
      sizes: const ['40'],
      title: title,
      productId: id,
      salesNumber: 10,
      description: 'Comfortable shoes',
    );
  }

  FavoriteEntity buildFavorite({required String productId}) {
    return FavoriteEntity(
      createdDate: Timestamp.fromDate(DateTime(2025, 1, 1)),
      id: 'f-$productId',
      productId: productId,
      userId: 'u1',
    );
  }

  setUp(() async {
    await setupFirebaseCoreMocks();
    await sl.reset();

    mockFavoritesCubit = MockFavoritesCubit();
    mockProductsDisplayCubit = MockProductsDisplayCubit();
    mockNewInDisplayCubit = MockNewInDisplayCubit();

    when(() => mockFavoritesCubit.loadFavoritesByUserId(any()))
        .thenAnswer((_) async {});
    when(() => mockFavoritesCubit.deleteFavorite(any(), any()))
        .thenAnswer((_) async {});

    when(() => mockProductsDisplayCubit.displayProducts()).thenReturn(null);
    when(() => mockNewInDisplayCubit.displayProducts()).thenReturn(null);

    sl.registerSingleton<FavoritesCubit>(mockFavoritesCubit);
    sl.registerSingleton<ProductsDisplayCubit>(mockProductsDisplayCubit);
    sl.registerSingleton<NewInDisplayCubit>(mockNewInDisplayCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows auth required view when user is not authenticated',
      (tester) async {
    await setupFirebaseAuthMocks(uid: null);
    when(() => mockFavoritesCubit.state).thenReturn(FavoritesInitial());
    when(() => mockProductsDisplayCubit.state)
        .thenReturn(ProductsDisplayInitial());
    when(() => mockNewInDisplayCubit.state).thenReturn(ProductsDisplayInitial());

    await tester.pumpWidget(wrap(const FavoritesPage()));
    await tester.pumpAndSettle();

    expect(find.text('Please sign in'), findsOneWidget);
    expect(find.text('Sign in to view your favorite products.'), findsOneWidget);
  });

  testWidgets('shows loading indicator when favorites are loading',
      (tester) async {
    when(() => mockFavoritesCubit.state).thenReturn(FavoritesLoading());
    when(() => mockProductsDisplayCubit.state)
        .thenReturn(ProductsDisplayLoading());
    when(() => mockNewInDisplayCubit.state)
        .thenReturn(ProductsDisplayLoading());

    await tester.pumpWidget(wrap(const FavoritesPage(userIdOverride: 'u1')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    verify(() => mockFavoritesCubit.loadFavoritesByUserId('u1')).called(1);
  });

  testWidgets('shows favorites error view when loading favorites fails',
      (tester) async {
    when(() => mockFavoritesCubit.state)
        .thenReturn(FavoritesError('unable to load favorites'));
    when(() => mockProductsDisplayCubit.state)
        .thenReturn(ProductsDisplayInitial());
    when(() => mockNewInDisplayCubit.state)
        .thenReturn(ProductsDisplayInitial());

    await tester.pumpWidget(wrap(const FavoritesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    expect(find.text('Could not load favorites'), findsOneWidget);
    expect(find.text('unable to load favorites'), findsOneWidget);
    verify(() => mockFavoritesCubit.loadFavoritesByUserId('u1'))
        .called(greaterThanOrEqualTo(1));
  });

  testWidgets('shows empty favorites state when user has no favorites',
      (tester) async {
    when(() => mockFavoritesCubit.state).thenReturn(FavoritesLoaded(const []));
    when(() => mockProductsDisplayCubit.state)
        .thenReturn(ProductsDisplayLoaded(const []));
    when(() => mockNewInDisplayCubit.state)
        .thenReturn(ProductsDisplayLoaded(const []));

    await tester.pumpWidget(wrap(const FavoritesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    expect(find.text('No favorites yet'), findsOneWidget);
    expect(
      find.text('Tap the heart icon in product lists to save favorites.'),
      findsOneWidget,
    );
    expect(find.text('Return to home'), findsOneWidget);
    verify(() => mockFavoritesCubit.loadFavoritesByUserId('u1'))
        .called(greaterThanOrEqualTo(1));
  });

  testWidgets(
      'shows unavailable state when favorites exist but products are missing',
      (tester) async {
    when(() => mockFavoritesCubit.state)
        .thenReturn(FavoritesLoaded([buildFavorite(productId: 'p1')]));
    when(() => mockProductsDisplayCubit.state)
        .thenReturn(ProductsDisplayLoaded(const []));
    when(() => mockNewInDisplayCubit.state)
        .thenReturn(ProductsDisplayLoaded(const []));

    await tester.pumpWidget(wrap(const FavoritesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    expect(find.text('Favorites unavailable'), findsOneWidget);
  });

  testWidgets('shows favorite product grid when catalog has matching products',
      (tester) async {
    when(() => mockFavoritesCubit.state)
        .thenReturn(FavoritesLoaded([buildFavorite(productId: 'p1')]));
    when(() => mockProductsDisplayCubit.state).thenReturn(
      ProductsDisplayLoaded([
        buildProduct(id: 'p1', title: 'Runner Pro'),
      ]),
    );
    when(() => mockNewInDisplayCubit.state)
        .thenReturn(ProductsDisplayLoaded(const []));

    await tester.pumpWidget(wrap(const FavoritesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    expect(find.text('My Favorites'), findsNWidgets(2));
    expect(find.text('Favorites count: 1'), findsOneWidget);
    expect(find.text('Runner Pro'), findsOneWidget);
    verify(() => mockFavoritesCubit.loadFavoritesByUserId('u1'))
        .called(greaterThanOrEqualTo(1));
  });
}
