import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/data/saves/save_data.dart';
import 'package:gtn_2/data/saves/save_storage.dart';
import 'package:gtn_2/legacy/legacy_pages.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets(
    'Legacy More destinations navigate and Music changes survive a save reload',
    (WidgetTester tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'gtn2-legacy-hub-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final storage = SaveStorage(directory: directory);
      await storage.createIfEmpty(
        SaveData(secret: 42, attempts: 0, gamesWon: 0),
      );

      var progression = ProgressionState.initial;
      Future<void> persist(ProgressionState next) async {
        progression = next;
        await storage.update((current) => current!.copyWith(progression: next));
      }

      await tester.pumpWidget(
        M3EMaterialApp(
          data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
          fontFamily: 'Manrope',
          autoTheming: false,
          initialTheme: Brightness.light,
          home: StatefulBuilder(
            builder: (context, setState) => LegacyHubPage(
              progression: progression,
              activeSlot: 1,
              onSystemsChanged: (next) async {
                await persist(next);
                setState(() {});
              },
            ),
          ),
        ),
      );

      Future<void> visit(String destination, String pageTitle) async {
        final destinationFinder = find.text(destination).first;
        await tester.ensureVisible(destinationFinder);
        await tester.tap(destinationFinder);
        await tester.pumpAndSettle();
        expect(find.text(pageTitle), findsWidgets, reason: destination);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('More'), findsWidgets);
      }

      await visit('Creative Mode', 'Creative Mode');
      await visit('All gameplay systems', 'Gameplay Systems');
      await visit('Achievements & Perks', 'Achievements & Perks');
      await visit('Rewards', 'Rewards');
      await visit('Statistics', 'Statistics');
      await visit('Codex', 'Codex');
      await visit('Music', 'Music');
      await visit('Lucky Stake', 'Lucky Stake');
      await visit('Changelog', 'Changelog');
      await visit('About', 'About');

      final musicFinder = find.text('Music').first;
      await tester.ensureVisible(musicFinder);
      await tester.tap(musicFinder);
      await tester.pumpAndSettle();

      final shuffleSwitch = find.byType(M3ESwitch).first;
      expect(shuffleSwitch, findsOneWidget);
      await tester.tap(shuffleSwitch);
      await tester.pumpAndSettle();

      final reloaded = await storage.load();
      expect(reloaded, isNotNull);
      expect(reloaded!.progression.legacySystems.musicShuffle, isTrue);
      expect(
        ProgressionState.fromJson(reloaded.progression.toJson())
            .legacySystems
            .musicShuffle,
        isTrue,
      );
    },
  );
}
