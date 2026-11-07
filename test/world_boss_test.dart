import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/worlds/world_boss_catalog.dart';

void main() {
  const engine = ProgressionEngine();

  test('world bosses unlock in order and pay only once after final hit', () {
    var state = ProgressionState(
      correctGuesses: 10,
      upgrades: const {'a': 3},
    );
    final first = WorldBossCatalog.worlds.first;
    expect(WorldBossCatalog.isUnlocked(state, first), isTrue);

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
    expect(WorldBossCatalog.isUnlocked(state, WorldBossCatalog.worlds[1]), isFalse);
  });
}
