import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/entity/user_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/firebase_options.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/entities/favorite_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/delete_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/get_favorites_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/register_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/color_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_new_in_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_top_selling_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/page/favorites_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/page/home.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/page/product_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/cart_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/my_purchases_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test/helpers/firebase_auth_test_mocks.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockGetTopSellingProductsUseCase extends Mock
    implements GetTopSellingProductsUseCase {}

class MockGetNewInProductsUseCase extends Mock implements GetNewInProductsUseCase {}

class MockGetFavoritesByUserIdUseCase extends Mock
    implements GetFavoritesByUserIdUseCase {}

class MockRegisterFavoriteUseCase extends Mock implements RegisterFavoriteUseCase {}

class MockDeleteFavoriteUseCase extends Mock implements DeleteFavoriteUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockFavoritesCubit extends MockCubit<FavoritesState>
    implements FavoritesCubit {}

class MockProductsDisplayCubit extends MockCubit<ProductsDisplayState>
    implements ProductsDisplayCubit {}

class MockNewInDisplayCubit extends MockCubit<ProductsDisplayState>
    implements NewInDisplayCubit {}

class MockGetSalesByUserIdCubit extends MockCubit<GetSalesByUserIdState>
    implements GetSalesByUserIdCubit {}

class MockUserCubit extends MockCubit<UserState> implements UserCubit {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          textScaler: TextScaler.linear(1.0),
        ),
        child: child,
      ),
    );
  }

  Future<void> configureViewport(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(430, 932));
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
      sizes: const ['40', '42'],
      title: title,
      productId: id,
      salesNumber: 10,
      description: 'Comfortable shoes',
    );
  }

  SalesEntity buildSale({required String id}) {
    final ts = Timestamp.fromDate(DateTime(2025, 1, 1));
    return SalesEntity(
      createdDate: ts,
      discountedPrice: 90,
      freight: 10,
      id: id,
      installmentsNumber: 2,
      paymentMethod: 'Credit card',
      price: 100,
      productsList: const [
        {
          'title': 'Runner Pro',
          'quantity': 1,
          'size': '42',
          'color': 'Black',
          'colorHex': '#000000',
          'unitPrice': 100,
          'unitDiscounted': 90,
          'totalPrice': 90,
        }
      ],
      totalPrice: 100,
      userBirthDate: ts,
      userGender: 'male',
      userId: 'u1',
      userName: 'John',
    );
  }

  FavoriteEntity buildFavorite(String productId) {
    return FavoriteEntity(
      createdDate: Timestamp.fromDate(DateTime(2025, 1, 1)),
      id: 'f-$productId',
      productId: productId,
      userId: 'u1',
    );
  }

  Future<void> commonSetup() async {
    SharedPreferences.setMockInitialValues({});

    // Integration tests run on a real simulator; initialize Firebase with
    // generated options so FirebaseAuth does not crash on iOS when plist is absent.
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') {
        rethrow;
      }
    }

    await setupFirebaseAuthMocks(uid: null);
    await sl.reset();
  }

  group('Main feature flows', () {
    testWidgets('Home feature renders key sections and search', (tester) async {
      await commonSetup();
      await configureViewport(tester);

      final mockGetCategoriesUseCase = MockGetCategoriesUseCase();
      final mockGetTopSellingProductsUseCase = MockGetTopSellingProductsUseCase();
      final mockGetNewInProductsUseCase = MockGetNewInProductsUseCase();
      final mockGetFavoritesByUserIdUseCase = MockGetFavoritesByUserIdUseCase();
      final mockRegisterFavoriteUseCase = MockRegisterFavoriteUseCase();
      final mockDeleteFavoriteUseCase = MockDeleteFavoriteUseCase();
      final mockSignOutUseCase = MockSignOutUseCase();

      final products = [buildProduct(id: 'p1', title: 'Runner Pro')];

      when(() => mockGetCategoriesUseCase.call(null)).thenAnswer(
        (_) async => Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      );
      when(() => mockGetTopSellingProductsUseCase.call(null))
          .thenAnswer((_) async => Right(products));
      when(() => mockGetNewInProductsUseCase.call(null))
          .thenAnswer((_) async => Right(products));
      when(() => mockGetFavoritesByUserIdUseCase.call(any()))
          .thenAnswer((_) async => const Right(<dynamic>[]));
      when(() => mockSignOutUseCase.call(null))
          .thenAnswer((_) async => const Right('signed out'));

      sl.registerSingleton<GetCategoriesUseCase>(mockGetCategoriesUseCase);
      sl.registerSingleton<GetTopSellingProductsUseCase>(
          mockGetTopSellingProductsUseCase);
      sl.registerSingleton<GetNewInProductsUseCase>(mockGetNewInProductsUseCase);
      sl.registerSingleton<GetFavoritesByUserIdUseCase>(
          mockGetFavoritesByUserIdUseCase);
      sl.registerSingleton<RegisterFavoriteUseCase>(mockRegisterFavoriteUseCase);
      sl.registerSingleton<DeleteFavoriteUseCase>(mockDeleteFavoriteUseCase);
      sl.registerSingleton<SignOutUseCase>(mockSignOutUseCase);

      sl.registerFactory<CategoriesCubit>(() => CategoriesCubit());
      sl.registerFactory<NewInDisplayCubit>(
        () => NewInDisplayCubit(sl<GetNewInProductsUseCase>()),
      );
      sl.registerFactory<ProductsDisplayCubit>(
        () => ProductsDisplayCubit(sl<GetTopSellingProductsUseCase>()),
      );
      sl.registerFactory<SignOutCubit>(() => SignOutCubit());
      sl.registerFactory<FavoritesCubit>(
        () => FavoritesCubit(
          getFavoritesByUserIdUseCase: sl<GetFavoritesByUserIdUseCase>(),
          registerFavoriteUseCase: sl<RegisterFavoriteUseCase>(),
          deleteFavoriteUseCase: sl<DeleteFavoriteUseCase>(),
        ),
      );

      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Go to favorites'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'run');
      await tester.pumpAndSettle();

      expect(find.text('Search results'), findsOneWidget);
      expect(find.text('Runner Pro'), findsWidgets);

      await sl.reset();
    });

    testWidgets('Favorites feature covers unauth and signed-in list',
        (tester) async {
      await commonSetup();
      await configureViewport(tester);

      final mockFavoritesCubit = MockFavoritesCubit();
      final mockProductsDisplayCubit = MockProductsDisplayCubit();
      final mockNewInDisplayCubit = MockNewInDisplayCubit();

      when(() => mockFavoritesCubit.loadFavoritesByUserId(any()))
          .thenAnswer((_) async {});
      when(() => mockFavoritesCubit.state).thenReturn(FavoritesInitial());
      when(() => mockProductsDisplayCubit.displayProducts()).thenReturn(null);
      when(() => mockNewInDisplayCubit.displayProducts()).thenReturn(null);
      when(() => mockProductsDisplayCubit.state)
          .thenReturn(ProductsDisplayInitial());
      when(() => mockNewInDisplayCubit.state)
          .thenReturn(ProductsDisplayInitial());

      sl.registerSingleton<FavoritesCubit>(mockFavoritesCubit);
      sl.registerSingleton<ProductsDisplayCubit>(mockProductsDisplayCubit);
      sl.registerSingleton<NewInDisplayCubit>(mockNewInDisplayCubit);

      await tester.pumpWidget(wrap(const FavoritesPage()));
      await tester.pumpAndSettle();

      expect(find.text('Please sign in'), findsOneWidget);

      when(() => mockFavoritesCubit.state)
          .thenReturn(FavoritesLoaded([buildFavorite('p1')]));
      when(() => mockProductsDisplayCubit.state).thenReturn(
        ProductsDisplayLoaded([buildProduct(id: 'p1', title: 'Runner Pro')]),
      );
      when(() => mockNewInDisplayCubit.state)
          .thenReturn(ProductsDisplayLoaded(const []));

      await tester.pumpWidget(
        wrap(const FavoritesPage(userIdOverride: 'u1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Favorites count: 1'), findsOneWidget);
      expect(find.text('Runner Pro'), findsOneWidget);

      await sl.reset();
    });

    testWidgets('Cart feature renders auth gate and signed-in empty state',
        (tester) async {
      await commonSetup();
      await configureViewport(tester);

      final mockUserCubit = MockUserCubit();
      when(() => mockUserCubit.state).thenReturn(
        UserLoaded(
          user: UserEntity(
            id: 'u1',
            email: 'john@doe.com',
            address: 'Street',
            phone: '999',
            name: 'John',
            birthDate: DateTime(1990, 1, 1),
            gender: 'male',
          ),
        ),
      );
      when(() => mockUserCubit.getUser()).thenAnswer((_) async {});

      sl.registerSingleton<UserCubit>(mockUserCubit);

      await tester.pumpWidget(wrap(const CartPage()));
      await tester.pumpAndSettle();
      expect(find.text('Please sign in'), findsOneWidget);

      await tester.pumpWidget(wrap(const CartPage(userIdOverride: 'u1')));
      await tester.pumpAndSettle();
      expect(find.text('Your cart is empty'), findsOneWidget);

      await sl.reset();
    });

    testWidgets('Purchases feature renders loaded state and details',
        (tester) async {
      await commonSetup();
      await configureViewport(tester);

      final mockCubit = MockGetSalesByUserIdCubit();
      when(() => mockCubit.getSalesByUserId(any())).thenAnswer((_) async {});
      when(() => mockCubit.state)
          .thenReturn(GetSalesByUserIdLoaded([buildSale(id: 's1')]));

      sl.registerSingleton<GetSalesByUserIdCubit>(mockCubit);

      await tester.pumpWidget(wrap(const MyPurchasesPage(userIdOverride: 'u1')));
      await tester.pumpAndSettle();

      expect(find.text('Recent Purchases'), findsOneWidget);
      expect(find.text('Order #s1'), findsOneWidget);

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();
      expect(find.text('Products details:'), findsOneWidget);

      await sl.reset();
    });

    testWidgets('Product feature handles interactions and unauth actions',
        (tester) async {
      await commonSetup();
      await configureViewport(tester);

      final mockFavoritesCubit = MockFavoritesCubit();
      when(() => mockFavoritesCubit.state).thenReturn(FavoritesInitial());
      when(() => mockFavoritesCubit.loadFavoritesByUserId(any()))
          .thenAnswer((_) async {});

      sl.registerSingleton<FavoritesCubit>(mockFavoritesCubit);

      await tester.pumpWidget(
        wrap(
          ProductPage(
            product: buildProduct(id: 'p1', title: 'Runner Pro'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Product details'), findsOneWidget);

      final addIconFinder = find.byIcon(Icons.add).last;
      await tester.ensureVisible(addIconFinder);
      await tester.pumpAndSettle();
      await tester.tap(addIconFinder, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();
      expect(find.text('Please sign in to add products to cart.'), findsOneWidget);

      await sl.reset();
    });
  });
}
