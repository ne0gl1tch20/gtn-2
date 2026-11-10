import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/arcade/arcade_page.dart';
import 'package:gtn_2/design/expressive_widgets.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Memory Match locks the round after one incorrect answer',
      (WidgetTester tester) async {
    final rewards = <String>[];
    await tester.pumpWidget(M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.light,
      home: ArcadePage(onReward: (nebula, money) async {
        rewards.add('${nebula.toString()}:${money.toString()}');
      }),
    ));

    for (var attempt = 0;
        attempt < 20 && find.text('Memory Digit Sequence').evaluate().isEmpty;
        attempt++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Memory Digit Sequence'), findsOneWidget);
    final memoryMatchPlay = find.text('Play').at(3);
    await tester.ensureVisible(memoryMatchPlay);
    await tester.tap(memoryMatchPlay);
    await tester.pump(const Duration(milliseconds: 300));

    final sequence = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data?.trim())
        .whereType<String>()
        .firstWhere((value) => RegExp(r'^\d\s+\d\s+\d$').hasMatch(value));
    final expected = sequence.split(RegExp(r'\s+')).join();

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(GtnExpressiveTextField), '000');
    await tester.tap(find.text('Submit'));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Incorrect! Expected $expected'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Submit'), findsNothing);
    expect(find.text('Try again'), findsNothing);
    expect(find.text('Claim reward'), findsNothing);
    expect(rewards, isEmpty);
  });
}
