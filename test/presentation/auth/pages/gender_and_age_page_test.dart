import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/data/auth/models/user_creation_req.dart';
import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/presentation/auth/pages/gender_and_age.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: child);
  }

  testWidgets('renders gender and age page core UI', (tester) async {
    await tester.pumpWidget(
      wrap(
        GenderAndAgePage(
          userCreationReq: UserCreationReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('2. Just one step away from the best offers!'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
    expect(find.text('Male'), findsOneWidget);
    expect(find.text('Female'), findsOneWidget);
    expect(find.text('Both'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows validation when address is empty', (tester) async {
    await tester.pumpWidget(
      wrap(
        GenderAndAgePage(
          userCreationReq: UserCreationReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pump();

    expect(find.text('Please enter your address.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('gender chip selection changes selected chip', (tester) async {
    await tester.pumpWidget(
      wrap(
        GenderAndAgePage(
          userCreationReq: UserCreationReq(email: 'john@doe.com'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    ChoiceChip femaleBefore = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Female'),
    );
    expect(femaleBefore.selected, isFalse);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Female'));
    await tester.pump();

    ChoiceChip femaleAfter = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Female'),
    );
    expect(femaleAfter.selected, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
