import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/core/constants/app_background.dart';

void main() {
  testWidgets('AppBackground renders child over background', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppBackground(child: Text('Content')),
        ),
      ),
    );

    expect(find.text('Content'), findsOneWidget);
  });
}