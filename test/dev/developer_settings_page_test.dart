import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/trait_catalog_repository.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/dev/developer_settings_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'developer page exposes trait, runtime, seasonal and diagnostic inspectors',
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
            loadTraitCatalog: () async => const <TraitCatalogEntry>[],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Trait Registry Inspector'), findsOneWidget);
      expect(find.text('Runtime Inspector'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Season Simulator'), 250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Quick presets'), findsOneWidget);
      await tester.ensureVisible(find.text('Lunar New Year').first);
      await tester.tap(find.text('Lunar New Year').first);
      await tester.pumpAndSettle();
      expect(find.text('Preview: 2027-02-06'), findsOneWidget);
      expect(find.textContaining('Lunar New Year'), findsWidgets);

      await tester.scrollUntilVisible(
        find.text('Diagnostic Log Viewer'), 250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Diagnostic Log Viewer'), findsOneWidget);
    },
  );
}
