import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/base_header.dart';

void main() {
  testWidgets('BaseHeader right icon navigates to page 2', (tester) async {
    final controller = PageController(initialPage: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              PageView(
                controller: controller,
                children: const [
                  Center(child: Text('Page 0')),
                  Center(child: Text('Page 1')),
                  Center(child: Text('Page 2')),
                ],
              ),
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

    final rightIcon = find.byIcon(Icons.maps_ugc_outlined);
    await tester.tap(rightIcon);
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
  });
}