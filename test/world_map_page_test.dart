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
  }) =>
      ProgressionState(
        correctGuesses: correctGuesses,
        legacySystems: LegacySystemsState.initial.copyWith(
          unlockedWorldIds: unlocked,
          worldUnlockMigrationPending: false,
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

  testWidgets('renders all four world nodes on an interactive map',
      (tester) async {
    final state = stateWith();
    await pumpMap(tester, state: state, onAction: (_, __) async => state);

    expect(find.byType(InteractiveViewer), findsOneWidget);
    for (final world in WorldBossCatalog.worlds) {
      expect(find.byKey(ValueKey('world-node-${world.id}')), findsOneWidget);
    }
    expect(find.text('Verdant Grove'), findsWidgets);
  });

  testWidgets('map fit, reset and zoom controls update the real viewport',
      (tester) async {
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
    final controller = tester.widget<InteractiveViewer>(viewer)
        .transformationController!;
    final before = controller.value.clone();

    await tester.drag(viewer, const Offset(40, 24));
    await tester.pump(const Duration(milliseconds: 400));

    expect(controller.value.storage, isNot(equals(before.storage)));
  });

  testWidgets('selecting an unlocked node uses the progression action',
      (tester) async {
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

    await tester.tap(find.byKey(const ValueKey('world-node-crystal_caverns')));
    await tester.pump(const Duration(milliseconds: 400));

    expect(calls, contains(('crystal_caverns', 'select_world')));
    expect(find.text('Selected world'), findsOneWidget);
  });

  testWidgets('defeated world exposes mastery and dispatches its real action',
      (tester) async {
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

  testWidgets('secret route marker appears at its threshold and dispatches discovery',
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

    final secret = find.byKey(const ValueKey('secret-node-whispering_hollow'));
    expect(secret, findsOneWidget);
    await tester.tap(secret);
    await tester.pump(const Duration(milliseconds: 400));

    expect(actionId, 'whispering_hollow');
    expect(actionName, 'secret');
  });
}
