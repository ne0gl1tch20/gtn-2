import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
    final list = find.byType(ListView).first;
    Future<void> scrollTo(Finder finder) async {
      for (
        var attempt = 0;
        attempt < 12 && finder.evaluate().isEmpty;
        attempt++
      ) {
        await tester.drag(list, const Offset(0, -320));
        await tester.pumpAndSettle();
      }
      expect(finder, findsWidgets);
    }

    await scrollTo(find.text('Live preview'));
    expect(find.text('Nice guess!'), findsOneWidget);
    expect(find.text('Guess'), findsOneWidget);
    for (final label in [
      'Game Preferences',
      'Theme Appearance',
      'Theme Colors',
      'Number Notation',
      'Push Notifications & Reminders',
      'Sound FX',
      'Visual comfort & accessibility',
    ]) {
      await scrollTo(find.text(label));
    }
    await scrollTo(find.textContaining('Master Volume ·'));
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
    expect(
      find.text('Periodic reminders to return to the game.'),
      findsOneWidget,
    );
    expect(find.text('World unlocks and boss victories.'), findsOneWidget);
    expect(
      find.text('New random events and limited-time event rewards.'),
      findsOneWidget,
    );
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

  testWidgets('Android notification permission enables the setting on grant', (
    tester,
  ) async {
    const channel = MethodChannel('gtn/notification_permission');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'request');
          return true;
        });
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    var latest = GameSettings.initial.copyWith(notificationsEnabled: false);
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
    await tester.scrollUntilVisible(
      find.text('Notifications'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(latest.notificationsEnabled, isTrue);
    expect(find.text('Notifications enabled!'), findsOneWidget);
  });

  testWidgets('Android notification permission denial leaves it disabled', (
    tester,
  ) async {
    const channel = MethodChannel('gtn/notification_permission');
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
    addTearDown(() {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    var latest = GameSettings.initial.copyWith(notificationsEnabled: false);
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
    await tester.scrollUntilVisible(
      find.text('Notifications'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();

    expect(latest.notificationsEnabled, isFalse);
    expect(find.text('Notification permission denied.'), findsOneWidget);
  });
}
