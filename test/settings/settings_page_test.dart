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
    final scrollable = find.byType(Scrollable).first;
    for (final label in [
      'Game Preferences',
      'Theme Appearance',
      'Theme Colors',
      'Number Notation',
      'Push Notifications & Reminders',
      'Sound FX',
      'Visual comfort & accessibility',
    ]) {
      await tester.scrollUntilVisible(
        find.text(label).first,
        260,
        scrollable: scrollable,
      );
      await tester.pumpAndSettle();
      expect(find.text(label).first, findsOneWidget);
    }
    await tester.scrollUntilVisible(
      find.text('Live preview'),
      260,
      scrollable: scrollable,
    );
    expect(find.text('Nice guess!'), findsOneWidget);
    expect(find.text('Guess'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Master Volume ·'),
      260,
      scrollable: scrollable,
    );
    expect(find.textContaining('Master Volume ·'), findsOneWidget);
    expect(find.textContaining('Sound Effects Volume ·'), findsOneWidget);
  });

  testWidgets('Enabled notifications show all source categories', (
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
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Reminders'),
      260,
      scrollable: scrollable,
    );
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
    await tester.scrollUntilVisible(
      find.textContaining('Sound Effects Volume ·'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    final slider = tester.widget<Slider>(
      find.byWidgetPredicate(
        (widget) => widget is Slider && widget.onChanged == null,
      ),
    );
    expect(slider.onChanged, isNull);
  });
}
