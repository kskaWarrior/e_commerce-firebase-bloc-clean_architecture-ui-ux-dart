import 'package:bloc_test/bloc_test.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/bloc/user_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/sales/pages/cart_page.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/firebase_auth_test_mocks.dart';

class MockUserCubit extends MockCubit<UserState> implements UserCubit {}

void main() {
  late MockUserCubit mockUserCubit;

  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  setUp(() async {
    await setupFirebaseCoreMocks();
    await setupFirebaseAuthMocks(uid: null);
    await sl.reset();

    mockUserCubit = MockUserCubit();
    when(() => mockUserCubit.state).thenReturn(UserInitial());
    when(() => mockUserCubit.getUser()).thenAnswer((_) async {});

    sl.registerSingleton<UserCubit>(mockUserCubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows auth required view when user is not authenticated',
      (tester) async {
    await tester.pumpWidget(wrap(const CartPage()));
    await tester.pumpAndSettle();

    expect(find.text('Please sign in'), findsOneWidget);
    expect(find.text('Sign in to view and confirm your cart.'), findsOneWidget);
  });

  testWidgets('does not show authenticated cart actions while logged out',
      (tester) async {
    await tester.pumpWidget(wrap(const CartPage()));
    await tester.pumpAndSettle();

    expect(find.text('Confirm purchase'), findsNothing);
    expect(find.text('Draft items'), findsNothing);
    expect(find.text('Your cart is empty'), findsNothing);
  });
}
