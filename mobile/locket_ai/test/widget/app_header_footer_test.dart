import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/app_header.dart';
import 'package:locket_ai/widgets/app_footer.dart';
import 'package:locket_ai/widgets/gradient_icon.dart';

void main() {
  group('AppHeader', () {
    testWidgets('Trigger onLeftTap and onRightTap when they are pressed', (tester) async {
      bool leftTapped = false;
      bool rightTapped = false;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppHeader(
              onLeftTap: () {
                leftTapped = true;
              },
              friendsSection: const Text('Friends'),
              onRightTap: () {
                rightTapped = true;
              },
            ),
          ),
        ),
      );

      final icons = find.byType(GradientCircleIcon);
      expect(icons, findsNWidgets(2));

      await tester.tap(icons.at(0));
      await tester.pump();
      await tester.tap(icons.at(1));
      await tester.pump();

      expect(leftTapped, isTrue);
      expect(rightTapped, isTrue);
    });
  });

  group('AppFooter', () {
    testWidgets('Trigger 3 callbacks after the buttons are pressed', (tester) async {
      bool leftTapped = false;
      bool buttonTapped = false;
      bool rightTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppFooter(
              onLeftTap: () {
                leftTapped = true;
              },
              onButtonTap: () {
                buttonTapped = true;
              },
              onRightTap: () {
                rightTapped = true;
              },
            ),
          ),
        ),
      );

      final detectors = find.descendant(
        of: find.byType(AppFooter),
        matching: find.byWidgetPredicate(
          (w) => w is GestureDetector && w.onTap != null,
        ),
      );

      expect(detectors, findsNWidgets(3));

      await tester.tap(detectors.at(0));
      await tester.pump();
      await tester.tap(detectors.at(1));
      await tester.pump();
      await tester.tap(detectors.at(2));
      await tester.pump();

      expect(leftTapped, isTrue);
      expect(buttonTapped, isTrue);
      expect(rightTapped, isTrue);
    });
  });
}