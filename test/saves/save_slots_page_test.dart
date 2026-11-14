import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/saves/save_slots_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('unreadable save slots are not presented as empty slots', (
    tester,
  ) async {
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: SaveSlotsPage(
          activeSlot: 1,
          onSelect: (_) async {},
          previewLoader: (slot) => slot == 1
              ? Future<SaveData?>.error(StateError('Preview failed'))
              : Future<SaveData?>.value(null),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Could not read save. Your data was not changed.'),
      findsOneWidget,
    );
    expect(find.text('Empty slot'), findsAtLeastNWidgets(1));
    final firstSlotMenu = tester.widget<PopupMenuButton<String>>(
      find.byType(PopupMenuButton<String>).first,
    );
    expect(firstSlotMenu.enabled, isFalse);
  });

  testWidgets('new save dialog exposes permanent Creative Save setup', (
    tester,
  ) async {
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: SaveSlotsPage(
          activeSlot: 1,
          onSelect: (_) async {},
          previewLoader: (_) => Future<SaveData?>.value(null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(PopupMenuButton<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create save'));
    await tester.pumpAndSettle();

    expect(find.text('Create Slot 1'), findsOneWidget);
    expect(find.text('Creative Save'), findsOneWidget);
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.text('Range minimum (1–1,000,000)'), findsNothing);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(find.text('Range minimum (1–1,000,000)'), findsOneWidget);
    expect(find.text('Range maximum (1–1,000,000)'), findsOneWidget);
    expect(find.text('Permanently enables the active-save Creative Save tools.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Create Slot 1'), findsNothing);
  });

  testWidgets('Reset Everything requires the source safety checks', (
    tester,
  ) async {
    var resetCalled = false;
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: SaveSlotsPage(
          activeSlot: 1,
          onSelect: (_) async {},
          onResetEverything: () async {
            resetCalled = true;
          },
          previewLoader: (_) => Future<SaveData?>.value(null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset Everything').last);
    await tester.pumpAndSettle();
    expect(find.text('Confirm Data Reset'), findsOneWidget);
    expect(find.textContaining('Wait 45 seconds'), findsOneWidget);
    expect(resetCalled, isFalse);

    await tester.pump(const Duration(seconds: 45));
    await tester.pump();
    expect(find.text('You may confirm the reset.'), findsOneWidget);
    final confirm = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Confirm reset'),
    );
    expect(confirm.onPressed, isNull);
    expect(resetCalled, isFalse);

    final expression = tester
        .widgetList<Text>(find.byType(Text))
        .map((widget) => widget.data ?? '')
        .firstWhere(
          (value) =>
              value.contains(' + ') ||
              value.contains(' - ') ||
              value.contains(' * ') ||
              value.contains(' / '),
        );
    final tokens = expression.split(' ');
    var answer = int.parse(tokens.first);
    for (var index = 1; index < tokens.length; index += 2) {
      final operand = int.parse(tokens[index + 1]);
      answer = switch (tokens[index]) {
        '+' => answer + operand,
        '-' => answer - operand,
        '*' => answer * operand,
        _ => answer ~/ operand,
      };
    }
    await tester.tap(find.byType(CheckboxListTile));
    await tester.enterText(find.byType(TextField).last, answer.toString());
    await tester.pump();
    final enabledConfirm = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Confirm reset'),
    );
    expect(enabledConfirm.onPressed, isNotNull);
    await tester.tap(find.text('Confirm reset'));
    await tester.pumpAndSettle();
    expect(resetCalled, isTrue);
  });
}
