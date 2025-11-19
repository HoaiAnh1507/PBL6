import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/app_footer.dart';

void main() {
  testWidgets('AppFooter contains three icons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppFooter(
            onLeftTap: () {},
            onButtonTap: () {},
            onRightTap: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.apps_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_outlined), findsOneWidget);
    expect(find.byType(Container), findsWidgets);
  });
}