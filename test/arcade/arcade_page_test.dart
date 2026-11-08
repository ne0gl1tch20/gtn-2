import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/arcade/arcade_page.dart';

void main() {
  testWidgets('Memory Match allows one answer and rewards only a correct answer',
      (WidgetTester tester) async {
    final rewards = <String>[];
    await tester.pumpWidget(MaterialApp(
      home: ArcadePage(onReward: (nebula, money) async {
        rewards.add('${nebula.toString()}:${money.toString()}');
      }),
    ));

    Future<String> openRound() async {
      for (var attempt = 0;
          attempt < 20 && find.text('Memory Digit Sequence').evaluate().isEmpty;
          attempt++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Memory Digit Sequence'), findsOneWidget);
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

    final failedAnswer = await openRound();
    await tester.enterText(find.byType(TextField), '000');
    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Incorrect! Expected $failedAnswer'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Claim reward'), findsNothing);

    await tester.tap(find.text('Done'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Memory Digit Sequence'), findsOneWidget);
    expect(rewards, isEmpty);

    final correctAnswer = await openRound();
    await tester.enterText(find.byType(TextField), correctAnswer);
    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Correct! You remembered the sequence.'), findsOneWidget);
    await tester.tap(find.text('Claim reward'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(rewards, ['1:10000']);
  });
}
