import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:gtn_2/settings/settings_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Settings follows the pinned GTN1 screen hierarchy', (
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
    expect(find.text('Settings & Save Management'), findsOneWidget);
    expect(find.text('Game Preferences'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme Appearance'), findsOneWidget);
    expect(find.text('Theme Colors'), findsOneWidget);
    expect(find.text('Number Notation'), findsOneWidget);
    expect(find.text('Push Notifications & Reminders'), findsOneWidget);
    expect(find.text('Sound FX'), findsOneWidget);
    expect(find.text('Visual comfort & accessibility'), findsOneWidget);
    expect(find.text('Master Volume'), findsOneWidget);
    expect(find.text('Sound Effects Volume'), findsOneWidget);
  });

  testWidgets('Notification categories follow the enabled state', (
    tester,
  ) async {
    var latest = GameSettings.initial;
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: SettingsPage(
          settings: latest,
          onChanged: (next) async {
            latest = next;
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Reminders'), findsOneWidget);
    expect(find.text('Progression milestones'), findsOneWidget);
    expect(find.text('Game events'), findsOneWidget);
  });

  testWidgets('Sound effects volume is disabled when sound FX are off', (
    tester,
  ) async {
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: SettingsPage(
          settings: GameSettings.initial.copyWith(soundEnabled: false),
          onChanged: (_) async {},
        ),
      ),
    );

    await tester.pumpAndSettle();
    final slider = tester.widget<Slider>(
      find.byWidgetPredicate(
        (widget) => widget is Slider && widget.onChanged == null,
      ),
    );
    expect(slider.onChanged, isNull);
  });
}
