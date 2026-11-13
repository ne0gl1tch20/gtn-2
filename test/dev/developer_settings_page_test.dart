import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/dev/developer_settings_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'developer page exposes trait, runtime and diagnostic inspectors',
    (tester) async {
      await tester.pumpWidget(
        M3EMaterialApp(
          data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
          fontFamily: 'Manrope',
          autoTheming: false,
          initialTheme: Brightness.light,
          home: DeveloperSettingsPage(
            save: SaveData(secret: 42, attempts: 0, gamesWon: 0),
            onCommand: (command) async => 'Executed $command',
            onApplySave: (_) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Trait Registry Inspector'), findsOneWidget);
      expect(find.text('Runtime Inspector'), findsOneWidget);
      expect(find.text('Diagnostic Log Viewer'), findsOneWidget);

      final commandField = find.byWidgetPredicate(
        (widget) =>
            widget is TextField &&
            widget.decoration?.labelText == 'Developer command',
      );
      await tester.ensureVisible(commandField);
      await tester.enterText(commandField, '/help');
      await tester.tap(find.text('Run command'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Diagnostic Log Viewer'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('[INFO][COMMAND_EXECUTED] /help'),
        findsOneWidget,
      );
    },
  );
}
