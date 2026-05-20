import 'package:bloc_test/bloc_test.dart';
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
}
