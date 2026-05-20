import 'package:bloc_test/bloc_test.dart';
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
}
