import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/cart/cart_draft_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/get_user.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/delete_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/get_favorites_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/register_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_new_in_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_top_selling_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/usecases/get_sales_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/store/usecases/get_store.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/pages/web_cart_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/pages/web_purchases_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/web/widgets/web_scaffold.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/firebase_auth_test_mocks.dart';

/// Regression guard for the three phone-width RenderFlex overflows fixed in
/// 8fbe3bb. Every layout is pumped at both a phone and a desktop size, because
/// each fix added a breakpoint and both sides of it have to lay out.
///
/// The assertion is deliberately blunt - `tester.takeException()` is null -
/// since an overflow surfaces as a thrown FlutterError during paint. That is
/// exactly what nothing was catching before.

class _MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class _MockSignOutUseCase extends Mock implements SignOutUseCase {}

class _MockGetUserUseCase extends Mock implements GetUserUseCase {}

class _MockGetStoreUseCase extends Mock implements GetStoreUseCase {}

class _MockGetSalesByUserIdUseCase extends Mock
    implements GetSalesByUserIdUseCase {}

class _MockGetFavoritesUseCase extends Mock
    implements GetFavoritesByUserIdUseCase {}

class _MockRegisterFavoriteUseCase extends Mock
    implements RegisterFavoriteUseCase {}

class _MockDeleteFavoriteUseCase extends Mock implements DeleteFavoriteUseCase {}

class _MockGetTopSellingUseCase extends Mock
    implements GetTopSellingProductsUseCase {}

class _MockGetNewInUseCase extends Mock implements GetNewInProductsUseCase {}

/// A phone in portrait - the width the storefront overflowed at.
const Size _phone = Size(390, 844);

/// A laptop - the width every one of these layouts was designed against.
const Size _desktop = Size(1440, 900);

void main() {
  late _MockGetSalesByUserIdUseCase mockGetSales;

  Timestamp ts() => Timestamp.fromDate(DateTime(2026, 1, 1));

  /// A sale whose text is long enough to press on every horizontal budget.
  SalesEntity buildSale({required String id, String status = 'pending'}) {
    return SalesEntity(
      createdDate: ts(),
      discountedPrice: 249.9,
      freight: 24.9,
      id: id,
      installmentsNumber: 3,
      paymentMethod: 'mercadopago',
      price: 329.9,
      productsList: [
        {
          'productId': 'PRD-000000001',
          'title': 'Tenis Runner Pro Ultraleve Edicao Limitada',
          'categoryName': 'Calcados',
          'color': 'Preto Onix',
          'size': '42',
          'quantity': 2,
          'unitPrice': 164.95,
          'unitDiscounted': 124.95,
          'totalPrice': 249.9,
        },
      ],
      totalPrice: 274.8,
      userBirthDate: ts(),
      userGender: 'male',
      userId: 'u1',
      userName: 'Joao da Silva Pereira',
      status: status,
      deliveryMethod: 'delivery',
    );
  }

  Future<void> registerWebDependencies() async {
    await sl.reset();

    final categories = _MockGetCategoriesUseCase();
    when(() => categories.call(null))
        .thenAnswer((_) async => const Right(<CategoriesEntity>[]));
    sl.registerSingleton<GetCategoriesUseCase>(categories);
    sl.registerFactory<CategoriesCubit>(() => CategoriesCubit());

    final signOut = _MockSignOutUseCase();
    when(() => signOut.call(null))
        .thenAnswer((_) async => const Right('signed out'));
    sl.registerSingleton<SignOutUseCase>(signOut);

    final getUser = _MockGetUserUseCase();
    when(() => getUser.call(null))
        .thenAnswer((_) async => Left(Failure(error: 'no user')));
    sl.registerSingleton<GetUserUseCase>(getUser);
    sl.registerFactory<UserCubit>(() => UserCubit());

    final getStore = _MockGetStoreUseCase();
    when(() => getStore.call(null))
        .thenAnswer((_) async => Left(Failure(error: 'no store')));
    sl.registerSingleton<GetStoreUseCase>(getStore);

    // The empty-cart suggestions and the compact header both reach for these.
    final favorites = _MockGetFavoritesUseCase();
    when(() => favorites.call(any()))
        .thenAnswer((_) async => const Right(<dynamic>[]));
    sl.registerSingleton<GetFavoritesByUserIdUseCase>(favorites);
    sl.registerSingleton<RegisterFavoriteUseCase>(_MockRegisterFavoriteUseCase());
    sl.registerSingleton<DeleteFavoriteUseCase>(_MockDeleteFavoriteUseCase());
    sl.registerFactory<FavoritesCubit>(
      () => FavoritesCubit(
        getFavoritesByUserIdUseCase: sl<GetFavoritesByUserIdUseCase>(),
        registerFavoriteUseCase: sl<RegisterFavoriteUseCase>(),
        deleteFavoriteUseCase: sl<DeleteFavoriteUseCase>(),
      ),
    );

    final topSelling = _MockGetTopSellingUseCase();
    when(() => topSelling.call(null))
        .thenAnswer((_) async => Left(Failure(error: 'no products')));
    sl.registerSingleton<GetTopSellingProductsUseCase>(topSelling);
    sl.registerFactory<ProductsDisplayCubit>(
      () => ProductsDisplayCubit(sl<GetTopSellingProductsUseCase>()),
    );

    final newIn = _MockGetNewInUseCase();
    when(() => newIn.call(null))
        .thenAnswer((_) async => Left(Failure(error: 'no products')));
    sl.registerSingleton<GetNewInProductsUseCase>(newIn);
    sl.registerFactory<NewInDisplayCubit>(
      () => NewInDisplayCubit(sl<GetNewInProductsUseCase>()),
    );

    mockGetSales = _MockGetSalesByUserIdUseCase();
    sl.registerSingleton<GetSalesByUserIdUseCase>(mockGetSales);
    sl.registerFactory<GetSalesByUserIdCubit>(
      () => GetSalesByUserIdCubit(getSalesByUserIdUseCase: mockGetSales),
    );
  }

  /// Pumps [child] at [size] and asserts nothing was thrown while laying it
  /// out - an overflow surfaces here.
  Future<void> pumpAt(
    WidgetTester tester,
    Widget child, {
    required Size size,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    CartDraftStore.instance.clear();
    await setupFirebaseCoreMocks();
    await setupFirebaseAuthMocks(uid: 'u1');
    await registerWebDependencies();
  });

  tearDown(() async {
    CartDraftStore.instance.clear();
    await sl.reset();
  });

  group('WebScaffold header', () {
    // The header's fix is not an overflow guard: its search field is
    // Expanded, so a Row that no longer fits squeezes the search box to
    // nothing and shoves the cart button off the right edge without ever
    // throwing. So assert the behaviour instead - below the breakpoint the
    // secondary controls fold away and the cart button stays on screen.
    testWidgets('folds secondary controls away on a phone', (tester) async {
      await pumpAt(
        tester,
        const WebScaffold(body: SizedBox.expand()),
        size: _phone,
      );

      expect(find.byIcon(Icons.favorite_border), findsNothing);
      expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);

      final cart = find.byIcon(Icons.shopping_bag_outlined);
      expect(cart, findsOneWidget);
      expect(tester.getTopRight(cart).dx, lessThanOrEqualTo(_phone.width));
    });

    testWidgets('shows every control on a desktop', (tester) async {
      await pumpAt(
        tester,
        const WebScaffold(body: SizedBox.expand()),
        size: _desktop,
      );

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_outlined), findsOneWidget);
    });
  });

  group('WebCartPage', () {
    testWidgets('lays out a filled cart on a phone', (tester) async {
      CartDraftStore.instance.addDraft(buildSale(id: 'c1'));
      await pumpAt(
        tester,
        const WebCartPage(userIdOverride: 'u1'),
        size: _phone,
      );
    });

    testWidgets('lays out a filled cart on a desktop', (tester) async {
      CartDraftStore.instance.addDraft(buildSale(id: 'c1'));
      await pumpAt(
        tester,
        const WebCartPage(userIdOverride: 'u1'),
        size: _desktop,
      );
    });

    testWidgets('lays out an empty cart on a phone', (tester) async {
      await pumpAt(
        tester,
        const WebCartPage(userIdOverride: 'u1'),
        size: _phone,
      );
    });
  });

  group('WebPurchasesPage', () {
    testWidgets('lays out an order footer on a phone', (tester) async {
      when(() => mockGetSales.call('u1'))
          .thenAnswer((_) async => Right([buildSale(id: 'o1')]));
      await pumpAt(
        tester,
        const WebPurchasesPage(userIdOverride: 'u1'),
        size: _phone,
      );
    });

    testWidgets('lays out an order footer on a desktop', (tester) async {
      when(() => mockGetSales.call('u1'))
          .thenAnswer((_) async => Right([buildSale(id: 'o1')]));
      await pumpAt(
        tester,
        const WebPurchasesPage(userIdOverride: 'u1'),
        size: _desktop,
      );
    });
  });
}
