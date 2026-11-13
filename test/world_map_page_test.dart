import 'dart:ui' show Tristate;

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/worlds/world_boss_catalog.dart';
import 'package:gtn_2/worlds/world_map_page.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  ProgressionState stateWith({
    Set<String> unlocked = const {'verdant_grove'},
    int correctGuesses = 0,
    String activeWorldId = 'verdant_grove',
    bool endlessRiftActive = false,
    String? activeBossBattleWorldId,
    Set<String> discoveredSecrets = const {},
  }) => ProgressionState(
    correctGuesses: correctGuesses,
    legacySystems: LegacySystemsState.initial.copyWith(
      unlockedWorldIds: unlocked,
      worldUnlockMigrationPending: false,
      activeWorldId: activeWorldId,
      endlessRiftActive: endlessRiftActive,
      activeBossBattleWorldId: activeBossBattleWorldId,
      discoveredSecrets: discoveredSecrets,
    ),
  );

  Future<void> pumpMap(
    WidgetTester tester, {
    required ProgressionState state,
    required WorldBossAction onAction,
  }) async {
    // Use bounded frames: the expressive controls and map viewport can keep
    // scheduling animations, so waiting for global idle with pumpAndSettle is
    // not deterministic for this screen.
    await tester.pumpWidget(
      M3EMaterialApp(
        data: M3EThemeData.light(seedColor: const Color(0xFF7C5CFC)),
        fontFamily: 'Manrope',
        autoTheming: false,
        initialTheme: Brightness.light,
        home: WorldMapPage(progression: state, onAction: onAction),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('recreates GTN1 progression summary and world expedition list', (
    tester,
  ) async {
    final state = stateWith();
    await pumpMap(tester, state: state, onAction: (_, __) async => state);

    expect(find.text('BEYOND THE NUMBERS'), findsOneWidget);
    expect(find.text('Your universe'), findsOneWidget);
    expect(find.text('PRESTIGE'), findsOneWidget);
    expect(find.text('ULTRA'), findsOneWidget);
    expect(find.text('NEBULA'), findsOneWidget);
    expect(find.text('WORLD EXPEDITION'), findsOneWidget);
    expect(find.text('Worlds & bosses'), findsOneWidget);
    expect(find.text('Verdant Grove'), findsWidgets);
    expect(find.text('BOSS HEALTH'), findsWidgets);
    expect(find.text('Requirements pending'), findsWidgets);
  });

  testWidgets('renders all four world nodes on an interactive map', (
    tester,
  ) async {
    final state = stateWith();
    await pumpMap(tester, state: state, onAction: (_, __) async => state);

    expect(find.byType(InteractiveViewer), findsOneWidget);
    for (final world in WorldBossCatalog.worlds) {
      expect(find.byKey(ValueKey('world-node-${world.id}')), findsOneWidget);
    }
    expect(find.text('Verdant Grove'), findsWidgets);
  });

  testWidgets('locked worlds remain inspectable without selecting them', (
    tester,
  ) async {
    final state = stateWith();
    final calls = <(String, String)>[];
    final semantics = tester.ensureSemantics();

    await pumpMap(
      tester,
      state: state,
      onAction: (id, action) async {
        calls.add((id, action));
        return state;
      },
    );

    final lockedNode = find.byKey(const ValueKey('world-node-crystal_caverns'));
    await tester.ensureVisible(lockedNode);
    await tester.tap(lockedNode);
    await tester.pump(const Duration(milliseconds: 400));

    expect(calls, isEmpty);
    expect(
      tester.getSemantics(lockedNode).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(find.text('Crystal Caverns'), findsWidgets);
    expect(find.text('Unlock world'), findsWidgets);
    semantics.dispose();
  });

  testWidgets('Endless Rift keeps world selection on its active realm', (
    tester,
  ) async {
    final unlocked = WorldBossCatalog.worlds.map((world) => world.id).toSet();
    final state = stateWith(
      unlocked: unlocked,
      activeWorldId: 'verdant_grove',
      endlessRiftActive: true,
    );
    final calls = <(String, String)>[];
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    await pumpMap(
      tester,
      state: state,
      onAction: (id, action) async {
        calls.add((id, action));
        return state;
      },
    );

    final activeNode = find.byKey(const ValueKey('world-node-verdant_grove'));
    final otherNode = find.byKey(const ValueKey('world-node-crystal_caverns'));
    await tester.ensureVisible(otherNode);
    await tester.tap(otherNode);
    await tester.pump(const Duration(milliseconds: 400));

    expect(calls, isEmpty);
    expect(
      tester.getSemantics(activeNode).flagsCollection.isSelected,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(otherNode).flagsCollection.isSelected,
      Tristate.isFalse,
    );
    semantics.dispose();
  });

  testWidgets('active boss battle state is visible on its world node', (
    tester,
  ) async {
    final state = stateWith(activeBossBattleWorldId: 'verdant_grove');
    await pumpMap(tester, state: state, onAction: (_, __) async => state);

    expect(find.text('BATTLE LIVE'), findsOneWidget);
    expect(find.text('Battle active'), findsWidgets);
    expect(find.text('Leave boss battle'), findsOneWidget);
  });

  testWidgets('map fit, reset and zoom controls update the real viewport', (
    tester,
  ) async {
    final state = stateWith();
    await pumpMap(tester, state: state, onAction: (_, __) async => state);

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.panEnabled, isTrue);
    expect(viewer.scaleEnabled, isTrue);
    final controller = viewer.transformationController!;

    await tester.tap(find.byTooltip('Reset map view'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1, 0.001));

    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(controller.value.getMaxScaleOnAxis(), closeTo(1.25, 0.001));

    await tester.tap(find.byTooltip('Fit map to screen'));
    await tester.pump(const Duration(milliseconds: 400));
    final fittedScale = controller.value.getMaxScaleOnAxis();
    expect(fittedScale, greaterThan(0.35));
    expect(fittedScale, lessThan(1));
  });

  testWidgets('dragging the map pans its transformation', (tester) async {
    final state = stateWith();
    await pumpMap(tester, state: state, onAction: (_, __) async => state);

    final viewer = find.byType(InteractiveViewer);
    final controller = tester
        .widget<InteractiveViewer>(viewer)
        .transformationController!;
    final before = controller.value.clone();

    await tester.ensureVisible(viewer);
    await tester.drag(viewer, const Offset(40, 24));
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.value.storage, isNot(equals(before.storage)));
  });

  testWidgets('selecting an unlocked node uses the progression action', (
    tester,
  ) async {
    final unlocked = WorldBossCatalog.worlds.map((world) => world.id).toSet();
    final state = stateWith(unlocked: unlocked);
    final calls = <(String, String)>[];

    await pumpMap(
      tester,
      state: state,
      onAction: (id, action) async {
        calls.add((id, action));
        return state.copyWith(
          legacySystems: state.legacySystems.copyWith(activeWorldId: id),
        );
      },
    );

    final node = find.byKey(const ValueKey('world-node-crystal_caverns'));
    await tester.ensureVisible(node);
    await tester.tap(node);
    await tester.pump(const Duration(milliseconds: 400));

    expect(calls, contains(('crystal_caverns', 'select_world')));
    expect(find.text('Selected world'), findsWidgets);
  });

  testWidgets('defeated world exposes mastery and dispatches its real action', (
    tester,
  ) async {
    final state = stateWith().copyWith(
      defeatedBosses: const {'verdant_guardian'},
      nebula: BigNumber.fromInt(1000),
      legacySystems: LegacySystemsState.initial.copyWith(
        unlockedWorldIds: const {'verdant_grove'},
        worldUnlockMigrationPending: false,
        worldMasteryLevels: const {'verdant_grove': 1},
      ),
    );
    String? actionId;
    String? actionName;

    await pumpMap(
      tester,
      state: state,
      onAction: (id, action) async {
        actionId = id;
        actionName = action;
        return state.copyWith(
          nebula: BigNumber.fromInt(980),
          legacySystems: state.legacySystems.copyWith(
            worldMasteryLevels: const {'verdant_grove': 2},
          ),
        );
      },
    );

    expect(find.textContaining('World mastery: 1 / 10'), findsOneWidget);
    final upgrade = find.ancestor(
      of: find.textContaining('Increase mastery'),
      matching: find.byType(M3EButton),
    );
    expect(upgrade, findsOneWidget);
    await tester.ensureVisible(upgrade);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(upgrade);
    await tester.pump(const Duration(milliseconds: 400));

    expect(actionId, 'verdant_grove');
    expect(actionName, 'mastery');
    expect(find.textContaining('World mastery: 2 / 10'), findsOneWidget);
  });

  testWidgets(
    'secret route marker appears at its threshold and dispatches discovery',
    (tester) async {
      final state = stateWith(correctGuesses: 50);
      String? actionId;
      String? actionName;

      await pumpMap(
        tester,
        state: state,
        onAction: (id, action) async {
          actionId = id;
          actionName = action;
          return state;
        },
      );

      final secret = find.byKey(
        const ValueKey('secret-node-whispering_hollow'),
      );
      expect(secret, findsOneWidget);
      await tester.ensureVisible(secret);
      await tester.tap(secret);
      await tester.pump(const Duration(milliseconds: 400));

      expect(actionId, 'whispering_hollow');
      expect(actionName, 'secret');
    },
  );
}
