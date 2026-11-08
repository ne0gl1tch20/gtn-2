import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/arcade/arcade_page.dart';

void main() {
  Future<String> startMemoryMatch(
    WidgetTester tester,
    ArcadeRewardCallback onReward,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: ArcadePage(onReward: onReward),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Memory Digit Sequence'));
    await tester.pump(const Duration(milliseconds: 300));

    final sequence = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data?.trim())
        .whereType<String>()
        .firstWhere((value) => RegExp(r'^\d\s+\d\s+\d$').hasMatch(value));
    final expected = sequence.split(RegExp(r'\s+')).join();

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    return expected;
  }

  testWidgets('Memory Match accepts only one submitted answer',
      (WidgetTester tester) async {
    final rewards = <String>[];
    final expected = await startMemoryMatch(tester, (nebula, money) async {
      rewards.add(nebula.toString() + ':' + money.toString());
    });

    await tester.enterText(find.byType(TextField), '000');
    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Incorrect! Expected $expected'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Claim reward'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(rewards, isEmpty);
  });

  testWidgets('Memory Match awards the original reward after a correct answer',
      (WidgetTester tester) async {
    final rewards = <String>[];
    final expected = await startMemoryMatch(tester, (nebula, money) async {
      rewards.add(nebula.toString() + ':' + money.toString());
    });

    await tester.enterText(find.byType(TextField), expected);
    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Correct! You remembered the sequence.'), findsOneWidget);
    await tester.tap(find.text('Claim reward'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(rewards, ['1:10000']);
  });
}
