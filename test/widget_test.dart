import 'package:flutter/material.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/main.dart';

void main() {
  testWidgets('shows the GTN 1-inspired game dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GtnApp());
    expect(find.text('Guess The Number'), findsOneWidget);
    expect(find.text('YOUR WALLET'), findsOneWidget);

    // The dashboard is lazy-built, so scroll to the input instead of assuming it exists.
    await tester.scrollUntilVisible(
      find.text('MAKE YOUR GUESS'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('MAKE YOUR GUESS'), findsOneWidget);
    expect(find.text('GUESS'), findsOneWidget);
  });
}
