import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/app_header.dart';

void main() {
  testWidgets('AppHeader renders friendsSection widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppHeader(
            onLeftTap: () {},
            onRightTap: () {},
            friendsSection: const Text('FriendsSection'),
          ),
        ),
      ),
    );

    expect(find.text('FriendsSection'), findsOneWidget);
  });
}