import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/base_header.dart';

void main() {
  testWidgets('BaseHeader renders FriendsButton with provided label', (tester) async {
    final controller = PageController(initialPage: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BaseHeader(
            horizontalController: controller,
            count: 5,
            label: 'All',
            onTap: () {},
            showCount: false,
          ),
        ),
      ),
    );

    expect(find.text('All'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('BaseHeader navigates to page 0 on left/right tap', (tester) async {
    final controller = PageController(initialPage: 1);

    final pageView = PageView(
      controller: controller,
      children: const [
        Center(child: Text('Page 0')),
        Center(child: Text('Page 1')),
        Center(child: Text('Page 2')),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              pageView,
              Align(
                alignment: Alignment.topCenter,
                child: BaseHeader(
                  horizontalController: controller,
                  count: 0,
                  label: 'All',
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);

    final leftIcon = find.byIcon(Icons.account_circle_outlined);
    await tester.tap(leftIcon);
    await tester.pumpAndSettle();
    expect(find.text('Page 0'), findsOneWidget);
  });
}