import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/worlds/world_boss_catalog.dart';
import 'package:gtn_2/worlds/world_map_page.dart';

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
    await tester.pumpWidget(
      MaterialApp(
        home: WorldMapPage(progression: state, onAction: onAction),
      ),
    );
    await tester.pumpAndSettle();
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

  testWidgets('selecting an unlocked node uses the progression action',
      (tester) async {
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
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
    await tester.pumpAndSettle();

    expect(calls, contains(('crystal_caverns', 'select_world')));
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('world-node-crystal_caverns')),
      ).getSemanticsData().flagsCollection.isSelected,
      Tristate.isTrue,
    );
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
    await tester.pumpAndSettle();

    expect(actionId, 'whispering_hollow');
    expect(actionName, 'secret');
  });
}
