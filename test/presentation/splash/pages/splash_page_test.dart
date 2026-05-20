import 'package:bloc_test/bloc_test.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/signin.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_cubit.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/bloc/splash_state.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/splash/pages/splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSplashCubit extends MockCubit<SplashState> implements SplashCubit {}

void main() {
  late MockSplashCubit mockSplashCubit;

  Widget wrap(Widget child) {
    return MaterialApp(
      home: BlocProvider<SplashCubit>.value(
        value: mockSplashCubit,
        child: child,
      ),
    );
  }

  setUp(() {
    mockSplashCubit = MockSplashCubit();
    when(() => mockSplashCubit.state).thenReturn(DisplaySplash());
  });

  testWidgets('renders splash logo', (tester) async {
    await tester.pumpWidget(wrap(const SplashPage()));
    await tester.pump();

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('navigates to signin page when unauthenticated', (tester) async {
    whenListen(
      mockSplashCubit,
      Stream<SplashState>.fromIterable([
        UnAuthenticated(),
      ]),
      initialState: DisplaySplash(),
    );

    await tester.pumpWidget(wrap(const SplashPage()));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byType(SigninPage), findsOneWidget);
  });

}
