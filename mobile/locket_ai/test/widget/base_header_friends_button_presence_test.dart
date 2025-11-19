import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/base_header.dart';
import 'package:locket_ai/widgets/friend_button.dart';

void main() {
  testWidgets('BaseHeader contains FriendsButton', (tester) async {
    final controller = PageController(initialPage: 1);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BaseHeader(
            horizontalController: controller,
            count: 3,
            label: 'All',
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.byType(FriendsButton), findsOneWidget);
  });
}