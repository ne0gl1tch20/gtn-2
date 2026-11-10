import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:gtn_2/settings/settings_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('Settings recreates GTN1 preference groups with native controls',
      (WidgetTester tester) async {
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

    expect(find.text('GAME PREFERENCES'), findsOneWidget);
    expect(find.text('Language & gameplay'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Visual comfort'), 300);
    expect(find.text('Visual comfort'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Difficulty'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Reduce motion'), 300);
    expect(find.text('Reduce motion'), findsOneWidget);
  });
}
