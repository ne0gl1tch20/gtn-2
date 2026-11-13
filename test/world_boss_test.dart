import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/worlds/world_boss_catalog.dart';

void main() {
  const engine = ProgressionEngine();

  test('world bosses unlock in order and pay only once after final hit', () {
    var state = ProgressionState(correctGuesses: 10, upgrades: const {'a': 3});
    final first = WorldBossCatalog.worlds.first;
    expect(WorldBossCatalog.isUnlocked(state, first), isTrue);
    expect(WorldBossCatalog.canFight(state, first), isTrue);

    state = engine.attackWorldBoss(state, first);
    expect(state.bossDamage[first.id], 1);
    state = engine.attackWorldBoss(state, first);
    expect(state.bossDamage[first.id], 2);
    state = engine.attackWorldBoss(state, first);
    expect(WorldBossCatalog.isDefeated(state, first), isTrue);
    expect(state.money, BigNumber.fromInt(25000));
    expect(state.nebula, BigNumber.fromInt(10));

    final paidAgain = engine.attackWorldBoss(state, first);
    expect(paidAgain.money, state.money);
    expect(paidAgain.nebula, state.nebula);
    expect(
      WorldBossCatalog.isUnlocked(state, WorldBossCatalog.worlds[1]),
      isFalse,
    );
  });

  test('separates world unlock requirements from boss fight requirements', () {
    final first = WorldBossCatalog.worlds.first;
    final second = WorldBossCatalog.worlds[1];
    var state = ProgressionState();

    expect(WorldBossCatalog.isUnlocked(state, first), isTrue);
    expect(WorldBossCatalog.canFight(state, first), isFalse);
    expect(engine.attackWorldBoss(state, first), same(state));

    state = state.copyWith(correctGuesses: 10, upgrades: const {'a': 3});
    expect(WorldBossCatalog.isUnlocked(state, first), isTrue);
    expect(WorldBossCatalog.canFight(state, first), isTrue);

    state = state.copyWith(correctGuesses: 25, upgrades: const {'a': 5});
    expect(WorldBossCatalog.isUnlocked(state, second), isFalse);
    expect(WorldBossCatalog.canFight(state, second), isFalse);
  });

  test(
    'matches GTN1 world identities, map positions and secret thresholds',
    () {
      expect(WorldBossCatalog.worlds.map((world) => world.bossId), [
        'verdant_guardian',
        'crystal_golem',
        'ember_dragon',
        'nebula_titan',
      ]);
      expect(WorldBossCatalog.worlds.map((world) => (world.x, world.y)), [
        (0.16, 0.24),
        (0.43, 0.43),
        (0.67, 0.24),
        (0.82, 0.59),
      ]);
      expect(WorldBossCatalog.routes, [(0, 1), (1, 2), (1, 3), (2, 3)]);
      expect(WorldBossCatalog.worlds.map((world) => world.secretAt), [
        50,
        150,
        300,
        600,
      ]);
      expect(WorldBossCatalog.worlds.map((world) => world.hits), [3, 5, 7, 10]);
      expect(WorldBossCatalog.worlds.last.unlockUltraCount, 1);
      expect(WorldBossCatalog.worlds.last.fightUltraCount, 1);
      expect(WorldBossCatalog.worlds.last.fightPrestigeCount, 5);
    },
  );
}
