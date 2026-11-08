import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/arcade/arcade_page.dart';

void main() {
  testWidgets('Memory Match accepts only one submitted answer',
      (WidgetTester tester) async {
    final rewards = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: ArcadePage(onReward: (nebula, money) async {
        rewards.add('${nebula.toString()}:${money.toString()}');
      }),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Memory Digit Sequence'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final sequence = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data?.trim())
        .whereType<String>()
        .firstWhere((value) => RegExp(r'^\\d\\s+\\d\\s+\\d$').hasMatch(value));
    final expected = sequence.split(RegExp(r'\\s+')).join();

    await tester.enterText(find.byType(TextField), '000');
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Incorrect! Expected $expected'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Claim reward'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(rewards, isEmpty);
  });

  testWidgets('Memory Match awards the original reward after a correct answer',
      (WidgetTester tester) async {
    final rewards = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: ArcadePage(onReward: (nebula, money) async {
        rewards.add('${nebula.toString()}:${money.toString()}');
      }),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Memory Digit Sequence'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    final sequence = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data?.trim())
        .whereType<String>()
        .firstWhere((value) => RegExp(r'^\\d\\s+\\d\\s+\\d$').hasMatch(value));
    final expected = sequence.split(RegExp(r'\\s+')).join();

    await tester.enterText(find.byType(TextField), expected);
    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(find.text('Correct! You remembered the sequence.'), findsOneWidget);
    await tester.tap(find.text('Claim reward'));
    await tester.pumpAndSettle();
    expect(rewards, ['1:10000']);
  });
}
