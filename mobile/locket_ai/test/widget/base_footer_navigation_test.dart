import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/base_footer.dart';

void main() {
  testWidgets('BaseFooter navigates vertical PageView to page 0 on taps', (tester) async {
    final vertical = PageController(initialPage: 1);
    final messageCtrl = TextEditingController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PageView(
                controller: vertical,
                scrollDirection: Axis.vertical,
                children: const [
                  Center(child: Text('V0')),
                  Center(child: Text('V1')),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: BaseFooter(
                  verticalController: vertical,
                  messageController: messageCtrl,
                  onSend: () {},
                ),
              )
            ],
          ),
        ),
      ),
    );

    expect(find.text('V1'), findsOneWidget);

    final footerDetectors = find.byWidgetPredicate((w) => w is GestureDetector && w.onTap != null);
    await tester.tap(footerDetectors.at(0));
    await tester.pumpAndSettle();
    expect(find.text('V0'), findsOneWidget);
  });
}

