import 'package:e_commerce_app_with_firebase_bloc_clean_architecture/common/helpr/navigator/app_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('First'),
          ElevatedButton(
            onPressed: () => AppNavigator.push(context, const SecondPage()),
            child: const Text('Push'),
          ),
          ElevatedButton(
            onPressed: () => AppNavigator.pushReplacement(context, const SecondPage()),
            child: const Text('Replace'),
          ),
          ElevatedButton(
            onPressed: () => AppNavigator.pushAndRemoveUntil(context, const ThirdPage()),
            child: const Text('ClearAndPush'),
          ),
        ],
      ),
    );
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Second'));
  }
}

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('Third'));
  }
}

void main() {
  testWidgets('AppNavigator.push opens a new page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FirstPage()));

    await tester.tap(find.text('Push'));
    await tester.pumpAndSettle();

    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('AppNavigator.pushReplacement replaces current page', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FirstPage()));

    await tester.tap(find.text('Replace'));
    await tester.pumpAndSettle();

    expect(find.text('Second'), findsOneWidget);
    expect(find.text('First'), findsNothing);
  });

  testWidgets('AppNavigator.pushAndRemoveUntil clears stack', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FirstPage()));

    await tester.tap(find.text('ClearAndPush'));
    await tester.pumpAndSettle();

    expect(find.text('Third'), findsOneWidget);
    expect(find.text('First'), findsNothing);
  });
}
