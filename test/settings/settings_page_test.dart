import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:gtn_2/settings/settings_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Settings recreates the full GTN1 preference groups', (
    tester,
  ) async {
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: SettingsPage(
          settings: GameSettings.initial,
          onChanged: (_) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('GAME PREFERENCES'), findsOneWidget);
    expect(find.text('Language & Numbers'), findsOneWidget);
    expect(find.text('Number notation'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    await tester.ensureVisible(find.text('Audio & Haptics'));
    await tester.pumpAndSettle();
    expect(find.text('Audio & Haptics'), findsOneWidget);
    await tester.ensureVisible(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    await tester.ensureVisible(find.text('Updates'));
    await tester.pumpAndSettle();
    expect(find.text('Updates'), findsOneWidget);
    await tester.ensureVisible(find.text('Accessibility'));
    await tester.pumpAndSettle();
    expect(find.text('Accessibility'), findsOneWidget);
    await tester.ensureVisible(find.text('Reduce flashes'));
    await tester.pumpAndSettle();
    expect(find.text('Reduce flashes'), findsOneWidget);
  });

  testWidgets('Settings exposes diagnostics and Menu Studio', (tester) async {
    var openedMenuStudio = false;
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: SettingsPage(
          settings: GameSettings.initial,
          onChanged: (_) async {},
          onOpenMenuStudio: () => openedMenuStudio = true,
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save logs to storage'));
    await tester.pumpAndSettle();
    expect(find.text('Save logs to storage'), findsOneWidget);
    expect(find.text('Verbose logging'), findsOneWidget);
    await tester.ensureVisible(find.text('Menu Studio'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu Studio'));
    expect(openedMenuStudio, isTrue);
  });
}
