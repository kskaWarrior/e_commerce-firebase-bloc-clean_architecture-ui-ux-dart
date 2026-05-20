import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/domain/sales/entities/sales_entity.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/bloc/get_sales_by_user_id_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/my_purchases_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/firebase_auth_test_mocks.dart';

class MockGetSalesByUserIdCubit extends MockCubit<GetSalesByUserIdState>
    implements GetSalesByUserIdCubit {}

void main() {
  late MockGetSalesByUserIdCubit mockCubit;

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  SalesEntity buildSale({
    String id = 's1',
    DateTime? createdAt,
    int installmentsNumber = 2,
    double totalPrice = 100,
    double price = 100,
    double discountedPrice = 90,
    List<Map<String, dynamic>> productsList = const <Map<String, dynamic>>[],
  }) {
    final ts = Timestamp.fromDate(createdAt ?? DateTime(2025, 1, 1));
    return SalesEntity(
      createdDate: ts,
      discountedPrice: discountedPrice,
      freight: 10,
      id: id,
      installmentsNumber: installmentsNumber,
      paymentMethod: 'Credit card',
      price: price,
      productsList: productsList,
      totalPrice: totalPrice,
      userBirthDate: ts,
      userGender: 'male',
      userId: 'u1',
      userName: 'John',
    );
  }

  setUp(() async {
    await setupFirebaseCoreMocks();
    await sl.reset();
    mockCubit = MockGetSalesByUserIdCubit();
    when(() => mockCubit.getSalesByUserId(any())).thenAnswer((_) async {});
    sl.registerSingleton<GetSalesByUserIdCubit>(mockCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows sign in message when user is not authenticated',
      (tester) async {
    await setupFirebaseAuthMocks(uid: null);
    when(() => mockCubit.state).thenReturn(GetSalesByUserIdInitial());

    await tester.pumpWidget(wrap(const MyPurchasesPage()));
    await tester.pumpAndSettle();

    expect(find.text('Please sign in'), findsOneWidget);
    expect(find.text('Sign in to view your purchases.'), findsOneWidget);
    verifyNever(() => mockCubit.getSalesByUserId(any()));
  });

  testWidgets('shows loading state when signed in and cubit is loading',
      (tester) async {
    when(() => mockCubit.state).thenReturn(GetSalesByUserIdLoading());

    await tester.pumpWidget(wrap(const MyPurchasesPage(userIdOverride: 'u1')));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    verify(() => mockCubit.getSalesByUserId('u1'))
        .called(greaterThanOrEqualTo(1));
  });

  testWidgets('shows error state when signed in and load fails',
      (tester) async {
    when(() => mockCubit.state)
        .thenReturn(GetSalesByUserIdError('unable to load'));

    await tester.pumpWidget(wrap(const MyPurchasesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    expect(find.text('Could not load purchases'), findsOneWidget);
    expect(find.text('unable to load'), findsOneWidget);
  });

  testWidgets(
      'shows empty purchases state when signed in and sales list is empty',
      (tester) async {
    when(() => mockCubit.state).thenReturn(GetSalesByUserIdLoaded(const []));

    await tester.pumpWidget(wrap(const MyPurchasesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    expect(find.text('No purchases yet'), findsOneWidget);
    expect(find.text('Confirmed purchases will appear here.'), findsOneWidget);
  });

  testWidgets('shows loaded purchases and expands details', (tester) async {
    when(() => mockCubit.state).thenReturn(
      GetSalesByUserIdLoaded([
        buildSale(id: 's1'),
      ]),
    );

    await tester.pumpWidget(wrap(const MyPurchasesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    expect(find.text('Recent Purchases'), findsOneWidget);
    expect(find.text('Order #s1'), findsOneWidget);
    expect(find.text('Show more'), findsOneWidget);

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(find.text('Products details:'), findsOneWidget);
    expect(find.text('No product details available.'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);
  });

  testWidgets('renders product detail cards when sale contains products',
      (tester) async {
    when(() => mockCubit.state).thenReturn(
      GetSalesByUserIdLoaded([
        buildSale(
          id: 's2',
          productsList: const [
            {
              'title': 'Runner Pro',
              'quantity': 2,
              'size': '42',
              'color': 'Black',
              'colorHex': '#000000',
              'unitPrice': 100,
              'unitDiscounted': 80,
              'totalPrice': 160,
            }
          ],
        ),
      ]),
    );

    await tester.pumpWidget(wrap(const MyPurchasesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();

    expect(find.text('Runner Pro'), findsOneWidget);
    expect(find.text('Line total'), findsOneWidget);
    expect(find.text('Installment value'), findsOneWidget);
  });

  testWidgets('sorts purchases by latest created date first', (tester) async {
    when(() => mockCubit.state).thenReturn(
      GetSalesByUserIdLoaded([
        buildSale(id: 'old', createdAt: DateTime(2025, 1, 1)),
        buildSale(id: 'new', createdAt: DateTime(2025, 1, 2)),
      ]),
    );

    await tester.pumpWidget(wrap(const MyPurchasesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    final orderFinder = find.textContaining('Order #');
    expect(orderFinder, findsNWidgets(2));

    final orderedTexts = orderFinder
        .evaluate()
        .map((element) => (element.widget as Text).data ?? '')
        .toList(growable: false);

    expect(orderedTexts.first, 'Order #new');
    expect(orderedTexts.last, 'Order #old');
  });

  testWidgets('collapses expanded section when show less is tapped',
      (tester) async {
    when(() => mockCubit.state).thenReturn(
      GetSalesByUserIdLoaded([
        buildSale(id: 's3'),
      ]),
    );

    await tester.pumpWidget(wrap(const MyPurchasesPage(userIdOverride: 'u1')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Show more'));
    await tester.pumpAndSettle();
    expect(find.text('Show less'), findsOneWidget);

    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();
    expect(find.text('Show more'), findsOneWidget);
    expect(find.text('Products details:'), findsNothing);
  });
}
