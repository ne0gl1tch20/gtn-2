import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/worlds/world_boss_battle_engine.dart';
import 'package:gtn_2/worlds/world_boss_catalog.dart';

void main() {
  const engine = WorldBossBattleEngine();

  ProgressionState fightReadyState() => ProgressionState(
        correctGuesses: 10,
        upgrades: const {'upgrade_a': 3},
      );

  test('unlocks the next world only after its previous boss and thresholds', () {
    final first = WorldBossCatalog.worlds.first;
    final second = WorldBossCatalog.worlds[1];
    var state = ProgressionState(
      correctGuesses: 25,
      upgrades: const {'upgrade_a': 5},
    );
    expect(WorldBossCatalog.canUnlock(state, second), isFalse);

    state = state.copyWith(
      defeatedBosses: const {'verdant_guardian'},
      legacySystems: state.legacySystems.copyWith(
        relicInventory: const {'verdant_guardian'},
      ),
    );
    expect(WorldBossCatalog.canUnlock(state, second), isTrue);
    final unlocked = engine.unlockWorld(state, second.id);
    expect(unlocked.accepted, isTrue);
    expect(unlocked.progression.legacySystems.unlockedWorldIds,
        containsAll([first.id, second.id]));
    expect(unlocked.progression.legacySystems.activeWorldId, second.id);
    expect(WorldBossCatalog.isUnlocked(unlocked.progression, second), isTrue);
  });

  test('starts and stops only an eligible world boss battle', () {
    final locked = engine.toggleBossBattle(ProgressionState(), 'verdant_grove');
    expect(locked.accepted, isFalse);

    final started = engine.toggleBossBattle(fightReadyState(), 'verdant_grove');
    expect(started.accepted, isTrue);
    expect(started.progression.legacySystems.activeBossBattleWorldId, 'verdant_grove');

    final stopped = engine.toggleBossBattle(started.progression, 'verdant_grove');
    expect(stopped.accepted, isTrue);
    expect(stopped.progression.legacySystems.activeBossBattleWorldId, isNull);
  });

  test('correct guesses hit the boss and phase changes reset miss counters', () {
    var state = engine.toggleBossBattle(fightReadyState(), 'verdant_grove').progression;
    var result = engine.recordGuess(state, correct: false);
    state = result.progression;
    expect(state.legacySystems.bossBattleMistakes['verdant_guardian'], 1);
    expect(state.bossDamage['verdant_guardian'], isNull);

    result = engine.recordGuess(state, correct: true);
    state = result.progression;
    expect(state.bossDamage['verdant_guardian'], 1);
    expect(state.legacySystems.bossBattleMistakes['verdant_guardian'], 0);
  });

  test('miss regression follows 4, 3 and 2 misses across boss phases', () {
    var state = engine.toggleBossBattle(fightReadyState(), 'verdant_grove').progression;
    for (var i = 0; i < 4; i++) {
      state = engine.recordGuess(state, correct: false).progression;
    }
    expect(state.bossDamage['verdant_guardian'] ?? 0, 0);
    expect(state.legacySystems.bossBattleMistakes['verdant_guardian'], 4);

    state = engine.recordGuess(state, correct: true).progression;
    expect(state.bossDamage['verdant_guardian'], 1);
    for (var i = 0; i < 3; i++) {
      state = engine.recordGuess(state, correct: false).progression;
    }
    expect(state.bossDamage['verdant_guardian'], 0);
  });

  test('normal boss defeat pays rewards once and records relic, codex and mastery', () {
    var state = engine.toggleBossBattle(fightReadyState(), 'verdant_grove').progression;
    for (var i = 0; i < 3; i++) {
      state = engine.recordGuess(state, correct: true).progression;
    }
    expect(state.money, BigNumber.fromInt(25000));
    expect(state.moneyEarned, BigNumber.fromInt(25000));
    expect(state.nebula, BigNumber.fromInt(10));
    expect(state.nebulaEarned, BigNumber.fromInt(10));
    expect(state.defeatedBosses, contains('verdant_guardian'));
    expect(state.legacySystems.relicInventory, contains('verdant_guardian'));
    expect(state.legacySystems.codexEntries, containsAll(['world:verdant_grove', 'boss:verdant_guardian']));
    expect(state.legacySystems.worldMasteryLevels['verdant_grove'], 1);
    expect(state.legacySystems.worldBossVictories, 1);
    expect(state.legacySystems.activeBossBattleWorldId, isNull);
    expect(engine.recordGuess(state, correct: true).progression.money, state.money);
  });

  test('boss rewards include relic set, mastery, sanctuary, event and secret bonuses', () {
    final state = fightReadyState().copyWith(
      legacySystems: ProgressionState.initial.legacySystems.copyWith(
        activeWorldId: 'verdant_grove',
        activeBossBattleWorldId: 'verdant_grove',
        equippedRelics: const {
          'verdant_guardian', 'crystal_golem', 'ember_dragon', 'nebula_titan',
        },
        worldMasteryLevels: const {'verdant_grove': 5},
        homeBaseLevel: 20,
        permanentEventBoosts: 25,
        discoveredSecrets: const {'whispering_hollow'},
      ),
    );
    var defeated = state;
    for (var i = 0; i < 3; i++) {
      defeated = engine.recordGuess(defeated, correct: true).progression;
    }
    // 35% relic set + 10% mastery + 40% sanctuary + 50% event + 5% secret.
    expect(defeated.money, BigNumber.fromInt(60000));
    // Four relics + mastery level five + discovered secret.
    expect(defeated.nebula, BigNumber.fromInt(30));
  });

  test('Endless Rift scales boss health and rewards then rotates to the next world', () {
    var state = fightReadyState().copyWith(
      legacySystems: ProgressionState.initial.legacySystems.copyWith(
        endlessRiftActive: true,
        endlessRiftTier: 2,
        activeWorldId: 'verdant_grove',
        activeBossBattleWorldId: 'verdant_grove',
      ),
    );
    for (var i = 0; i < 5; i++) {
      state = engine.recordGuess(state, correct: true).progression;
    }
    expect(state.money, BigNumber.fromInt(50000));
    expect(state.nebula, BigNumber.fromInt(20));
    expect(state.legacySystems.endlessRiftTier, 3);
    expect(state.legacySystems.endlessRiftBestTier, 2);
    expect(state.legacySystems.activeWorldId, 'crystal_caverns');
    expect(state.legacySystems.activeBossBattleWorldId, 'crystal_caverns');
    expect(state.legacySystems.worldBossVictories, 1);
  });

  test('selecting a different world cannot interrupt an active Endless Rift', () {
    final state = fightReadyState().copyWith(
      legacySystems: ProgressionState.initial.legacySystems.copyWith(
        endlessRiftActive: true,
        endlessRiftTier: 1,
        activeWorldId: 'verdant_grove',
        activeBossBattleWorldId: 'verdant_grove',
      ),
    );
    final result = engine.selectWorld(state, 'crystal_caverns');
    expect(result.accepted, isFalse);
    expect(result.progression.legacySystems.activeWorldId, 'verdant_grove');
  });
}
