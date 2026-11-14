import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:gtn_2/settings/menu_studio_layout.dart';
import 'package:gtn_2/settings/menu_studio_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('default layout preserves the GTN1 pinned navigation order', () {
    expect(MenuStudioLayout.defaults().primaryNavigationIds, [
      'worlds',
      'arcade',
      'play',
      'upgrades',
      'more',
    ]);
  });

  test('layout parser rejects payloads missing the source nav order', () {
    expect(
      MenuStudioLayout.tryParse(
        '{"areas":{},"orders":{"more":[]},"colors":{}}',
      ),
      isNull,
    );
  });

  testWidgets('Menu Studio saves both source-compatible menu areas', (
    tester,
  ) async {
    GameSettings? saved;
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.dark,
        home: MenuStudioPage(
          settings: GameSettings.initial,
          onChanged: (settings) async {
            saved = settings;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Top bar'), findsOneWidget);
    expect(find.text('More menu'), findsOneWidget);
    expect(find.text('Live preview'), findsOneWidget);
    expect(find.text('Worlds'), findsWidgets);

    await tester.tap(find.byTooltip('Choose color for Worlds'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hue:'), findsOneWidget);
    expect(find.text('Hex'), findsOneWidget);
    expect(find.text('Use theme'), findsOneWidget);
    await tester.tap(find.text('Use theme'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Move to More').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    final payload = jsonDecode(saved!.webMenuStudioLayout!) as Map;
    final areas = payload['areas'] as Map;
    final orders = payload['orders'] as Map;
    expect(orders['nav'], isA<List>());
    expect(orders['more'], contains('worlds'));
    expect(areas['worlds'], 'more');
    expect(saved!.moreScreenOrder, contains('worlds'));

    final restored = MenuStudioLayout.tryParse(saved!.webMenuStudioLayout);
    expect(restored, isNotNull);
    expect(restored!.visibleNavigationIds, isNot(contains('worlds')));
    expect(restored.visibleMoreIds, contains('worlds'));
  });
}
