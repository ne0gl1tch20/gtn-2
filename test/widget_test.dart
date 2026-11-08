import 'package:flutter/material.dart' show ListView, TextField;
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

    final field = tester.widget<TextField>(find.byType(TextField).first);
    await tester.tap(find.text('LOW END'));
    await tester.pump();
    expect(field.controller?.text, '1');

    await tester.tap(find.text('MIDPOINT'));
    await tester.pump();
    expect(field.controller?.text, '50');

    await tester.tap(find.text('HIGH END'));
    await tester.pump();
    expect(field.controller?.text, '100');

    await tester.tap(find.text('CLEAR'));
    await tester.pump();
    expect(field.controller?.text, isEmpty);
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
