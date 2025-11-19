import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/gradient_icon.dart';

void main() {
  testWidgets('GradientCircleIcon triggers onTap', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GradientCircleIcon(
            icon: Icons.star,
            size: 24,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(GradientCircleIcon));
    await tester.pump();
    expect(tapped, isTrue);
  });
}