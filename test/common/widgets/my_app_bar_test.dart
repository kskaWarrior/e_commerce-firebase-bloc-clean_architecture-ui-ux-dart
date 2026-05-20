import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/widgets/my_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyAppBar shows title and no back button when hideBack is true',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: MyAppBar(
            title: 'Title',
            hideBack: true,
          ),
        ),
      ),
    );

    expect(find.text('Title'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
  });

  testWidgets('MyAppBar shows back button when hideBack is false', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: MyAppBar(
            title: 'Title',
            hideBack: false,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
  });
}
