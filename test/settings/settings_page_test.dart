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
    await tester.scrollUntilVisible(
      find.text('Audio & Haptics'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Audio & Haptics'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Notifications'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Notifications'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Updates'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Updates'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Accessibility'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Accessibility'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Reduce flashes'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Reduce flashes'), findsOneWidget);
  });

  testWidgets('Settings exposes Help & Tutorial, diagnostics and Menu Studio', (
    tester,
  ) async {
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
          onReplayTutorial: () {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Rerun Nimmy tutorial'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rerun Nimmy tutorial'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Save logs to storage'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Save logs to storage'), findsOneWidget);
    expect(find.text('Verbose logging'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Menu Studio'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Menu Studio'));
    expect(openedMenuStudio, isTrue);
  });
}
