import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/friend_button.dart';

void main() {
  testWidgets('FriendsButton shows count when showCount=true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FriendsButton(
            count: 12,
            label: 'Friends',
            onTap: () {},
            showCount: true,
          ),
        ),
      ),
    );

    expect(find.text('12'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
  });

  testWidgets('FriendsButton hides count when showCount=false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FriendsButton(
            count: 12,
            label: 'Friends',
            onTap: () {},
            showCount: false,
          ),
        ),
      ),
    );

    expect(find.text('12'), findsNothing);
    expect(find.text('Friends'), findsOneWidget);
  });
}