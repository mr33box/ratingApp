// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rating_app/main.dart';

void main() {
  testWidgets('Rating App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RatingApp());

    // Verify that the app title is displayed.
    expect(find.text('Rating App'), findsOneWidget);

    // Verify that the empty state message is shown when there are no ratings.
    expect(find.text('No ratings yet'), findsOneWidget);
    expect(find.text('Tap the + button to add your first rating'), findsOneWidget);

    // Verify that the floating action button is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
