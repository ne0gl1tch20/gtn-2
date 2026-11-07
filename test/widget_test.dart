import 'package:flutter/material.dart' show ListView;
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/main.dart';

void main() {
  testWidgets('shows the GTN 1-inspired game dashboard',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GtnApp());
    expect(find.text('Game Center'), findsOneWidget);
    expect(find.text('YOUR WALLET'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('MAKE YOUR GUESS'), findsOneWidget);
    expect(find.text('GUESS'), findsOneWidget);
  });
}
