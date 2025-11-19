import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/base_header.dart';

void main() {
  testWidgets('BaseHeader shows count when showCount=true', (tester) async {
    final controller = PageController(initialPage: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BaseHeader(
            horizontalController: controller,
            count: 7,
            label: 'All',
            onTap: () {},
            showCount: true,
          ),
        ),
      ),
    );

    expect(find.text('7'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
  });
}