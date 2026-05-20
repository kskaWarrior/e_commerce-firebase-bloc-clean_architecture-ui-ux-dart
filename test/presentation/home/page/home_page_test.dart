import 'package:dartz/dartz.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/core/error/failure.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/entities/categories_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/categories/usecases/get_categories.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/auth/usecases/signout.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/delete_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/get_favorites_by_user_id.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/favorites/usecases/register_favorite.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/color_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/entities/product_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_new_in_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/products/usecases/get_top_selling_usecase.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/signout_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/favorites/bloc/favorites_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/categories_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/bloc/new_in_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/home/page/home.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/products/bloc/products_display_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/firebase_auth_test_mocks.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockGetTopSellingProductsUseCase extends Mock
    implements GetTopSellingProductsUseCase {}

class MockGetNewInProductsUseCase extends Mock implements GetNewInProductsUseCase {}

class MockGetFavoritesByUserIdUseCase extends Mock
    implements GetFavoritesByUserIdUseCase {}

class MockRegisterFavoriteUseCase extends Mock implements RegisterFavoriteUseCase {}

class MockDeleteFavoriteUseCase extends Mock implements DeleteFavoriteUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

void main() {
  late MockGetCategoriesUseCase mockGetCategoriesUseCase;
  late MockGetTopSellingProductsUseCase mockGetTopSellingProductsUseCase;
  late MockGetNewInProductsUseCase mockGetNewInProductsUseCase;
  late MockGetFavoritesByUserIdUseCase mockGetFavoritesByUserIdUseCase;
  late MockRegisterFavoriteUseCase mockRegisterFavoriteUseCase;
  late MockDeleteFavoriteUseCase mockDeleteFavoriteUseCase;
  late MockSignOutUseCase mockSignOutUseCase;

  ProductEntity buildProduct(String id, String title) {
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

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  Future<void> registerHomeDependencies({
    required Either categoriesResult,
    required Either topSellingResult,
    required Either newInResult,
  }) async {
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    mockGetTopSellingProductsUseCase = MockGetTopSellingProductsUseCase();
    mockGetNewInProductsUseCase = MockGetNewInProductsUseCase();
    mockGetFavoritesByUserIdUseCase = MockGetFavoritesByUserIdUseCase();
    mockRegisterFavoriteUseCase = MockRegisterFavoriteUseCase();
    mockDeleteFavoriteUseCase = MockDeleteFavoriteUseCase();
    mockSignOutUseCase = MockSignOutUseCase();

    when(() => mockGetCategoriesUseCase.call(null))
      .thenAnswer((_) async => categoriesResult);
    when(() => mockGetTopSellingProductsUseCase.call(null))
        .thenAnswer((_) async => topSellingResult);
    when(() => mockGetNewInProductsUseCase.call(null))
        .thenAnswer((_) async => newInResult);

    when(() => mockGetFavoritesByUserIdUseCase.call(any()))
        .thenAnswer((_) async => const Right(<dynamic>[]));
    when(() => mockSignOutUseCase.call(null))
      .thenAnswer((_) async => const Right('signed out'));

    await sl.reset();
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
  }

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 2400));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(wrap(const HomePage()));
    await tester.pumpAndSettle();
  }

  setUp(() async {
    await setupFirebaseCoreMocks();
    await setupFirebaseAuthMocks(uid: null);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders main home sections and product content', (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Top Selling'), findsWidgets);
    expect(find.text('New In'), findsWidgets);
    expect(find.text('Go to favorites'), findsOneWidget);
    expect(find.text('Runner Pro'), findsWidgets);
  });

  testWidgets('shows search section when query is entered', (tester) async {
    final products = [
      buildProduct('p1', 'Runner Pro'),
      buildProduct('p2', 'Classic Hat'),
    ];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'run');
    await tester.pumpAndSettle();

    expect(find.text('Search results'), findsOneWidget);
    expect(find.text('Runner Pro'), findsWidgets);
  });

  testWidgets('hides search section when query is cleared', (tester) async {
    final products = [
      buildProduct('p1', 'Runner Pro'),
      buildProduct('p2', 'Classic Hat'),
    ];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    await tester.enterText(find.byType(TextField), 'run');
    await tester.pumpAndSettle();
    expect(find.text('Search results'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('Search results'), findsNothing);
  });

  testWidgets('shows empty categories message when no categories are loaded',
      (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult: const Right(<CategoriesEntity>[]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    expect(find.text('No categories found'), findsOneWidget);
  });

  testWidgets('shows products error message when top selling load fails',
      (tester) async {
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Left(Failure(error: 'offline')),
      newInResult: const Right(<dynamic>[]),
    );

    await pumpHome(tester);

    expect(find.text('error: offline'), findsWidgets);
  });

  testWidgets('shows new in error when new in use case fails', (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Left(Failure(error: 'new in offline')),
    );

    await pumpHome(tester);

    expect(find.text('error: new in offline'), findsWidgets);
  });

  testWidgets('opens drawer and displays navigation actions', (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('My Purchases'), findsOneWidget);
    expect(find.text('Logout'), findsWidgets);
  });

  testWidgets('shows categories error when categories use case fails',
      (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult: Left(Failure(error: 'categories offline')),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    expect(find.text('error: categories offline'), findsWidgets);
  });

  testWidgets('selects and hides category section', (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    await tester.tap(find.text('Shoes').first);
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hide category'), findsOneWidget);

    await tester.tap(find.byTooltip('Hide category'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Hide category'), findsNothing);
  });

  testWidgets('opens logout dialog and closes it on cancel', (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout').first);
    await tester.pumpAndSettle();

    expect(find.text('Confirm logout'), findsOneWidget);
    expect(find.text('Are you sure you want to log out of your account?'),
        findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm logout'), findsNothing);
    expect(find.text('Categories'), findsOneWidget);
  });

  testWidgets('confirms logout and navigates to sign in page', (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );

    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    expect(find.byType(SigninPage), findsOneWidget);
  });

  testWidgets('shows snackbar when logout fails', (tester) async {
    final products = [buildProduct('p1', 'Runner Pro')];
    await registerHomeDependencies(
      categoriesResult:
          Right([CategoriesEntity(id: 'c1', title: 'Shoes', image: 'img')]),
      topSellingResult: Right(products),
      newInResult: Right(products),
    );
    when(() => mockSignOutUseCase.call(null))
        .thenAnswer((_) async => Left(Failure(error: 'cannot sign out')));

    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout').first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Logout').last);
    await tester.pumpAndSettle();

    expect(find.text('error: cannot sign out'), findsOneWidget);
    expect(find.byType(HomePage), findsOneWidget);
  });
}
