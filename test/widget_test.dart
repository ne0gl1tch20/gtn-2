import 'package:flutter/material.dart' show ListView;
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/main.dart';

void main() {
  testWidgets('shows the HTML-facing game dashboard controls',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GtnApp());
    expect(find.text('Guess The Number'), findsOneWidget);
    expect(find.text('YOUR WALLET'), findsOneWidget);
    expect(find.text('Play'), findsOneWidget);
    expect(find.text('Beyond the Numbers'), findsOneWidget);
    expect(find.text('More'), findsOneWidget);

    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('YOUR GUESS'), findsOneWidget);
    expect(find.text('->'), findsOneWidget);
    expect(find.text('QUICK PICK'), findsOneWidget);
    expect(find.text('LOW END'), findsOneWidget);
    expect(find.text('MIDPOINT'), findsOneWidget);
    expect(find.text('HIGH END'), findsOneWidget);
    expect(find.text('CLEAR'), findsOneWidget);
  });

  testWidgets('More opens its own destination with save and dev tools',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GtnApp());
    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    expect(find.text('More Menu'), findsOneWidget);
    expect(find.text('Save Slots'), findsOneWidget);
  });
}
