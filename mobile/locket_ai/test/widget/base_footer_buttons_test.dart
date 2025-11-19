import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/base_footer.dart';

void main() {
  testWidgets('BaseFooter has three tappable GestureDetectors', (tester) async {
    final vertical = PageController(initialPage: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BaseFooter(
            verticalController: vertical,
            messageController: TextEditingController(),
            onSend: () {},
          ),
        ),
      ),
    );

    final detectors = find.byWidgetPredicate((w) => w is GestureDetector && w.onTap != null);
    expect(detectors, findsNWidgets(3));
  });
}