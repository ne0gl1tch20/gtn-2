import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/shop/upgrade_batch_policy.dart';
import 'package:gtn_2/shop/upgrade_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const engine = ProgressionEngine();

  setUpAll(UpgradeCatalog.load);

  test(
    'canonical catalog contains eleven unique source upgrade definitions',
    () {
      final ids = UpgradeCatalog.all.map((item) => item.definition.id).toSet();
      expect(ids.length, 11);
      expect(UpgradeCatalog.all.length, 11);
    },
  );

  test(
    'only the source upgrades with wired effects are offered for purchase',
    () {
      expect(
        UpgradeCatalog.availableForGameplay
            .map((item) => item.definition.id)
            .toSet(),
        {'reward_multiplier', 'better_range'},
      );
    },
  );

  test(
    'bulk purchase spends the combined per-level cost and applies all levels',
    () {
      final upgrade = UpgradeCatalog.byId('reward_multiplier').definition;
      final state = ProgressionState.initial.copyWith(
        money: BigNumber.fromInt(475),
      );
      final result = engine.purchaseUpgradeLevels(state, upgrade, levels: 3);
      expect(result.money.toString(), '0');
      expect(result.moneySpent.toString(), '475');
      expect(result.upgrades['reward_multiplier'], 3);
    },
  );

  test('bulk purchase is atomic when the full amount is unaffordable', () {
    final upgrade = UpgradeCatalog.byId('reward_multiplier').definition;
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(474),
    );
    expect(
      engine.purchaseUpgradeLevels(state, upgrade, levels: 3),
      same(state),
    );
  });

  test('bulk purchase cannot exceed the source max level', () {
    final upgrade = UpgradeCatalog.byId('better_range').definition;
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(1000000000),
      upgrades: {'better_range': 19},
    );
    final result = engine.purchaseUpgradeLevels(state, upgrade, levels: 2);
    expect(result, same(state));
  });

  test('reward multiplier purchase spends the exact canonical cost', () {
    final upgrade = UpgradeCatalog.byId('reward_multiplier').definition;
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(100),
    );
    final result = engine.purchaseUpgrade(state, upgrade);
    expect(result.money.toString(), '0');
    expect(result.upgrades['reward_multiplier'], 1);
  });

  test('better range purchase respects its source cap and exact cost', () {
    final upgrade = UpgradeCatalog.byId('better_range').definition;
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(500),
    );
    final result = engine.purchaseUpgrade(state, upgrade);
    expect(result.money.toString(), '0');
    expect(result.upgrades['better_range'], 1);
  });

  test('unaffordable canonical upgrade purchase leaves state unchanged', () {
    final upgrade = UpgradeCatalog.byId('reward_multiplier').definition;
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(99),
    );
    expect(engine.purchaseUpgrade(state, upgrade), same(state));
  });

  test('loads source Prestige and Ultra upgrade catalogs', () {
    expect(UpgradeCatalog.prestige.map((item) => item.definition.id).toList(), [
      'prestige_money_boost',
      'prestige_gain_boost',
      'prestige_starting_capital',
    ]);
    expect(UpgradeCatalog.ultra.map((item) => item.definition.id).toList(), [
      'ultra_money_boost',
      'ultra_gain_boost',
      'ultra_nebula_boost',
    ]);
    expect(UpgradeCatalog.availablePrestige.length, 3);
    expect(UpgradeCatalog.availableUltra.length, 3);
  });

  test('Prestige upgrade purchase spends Prestige and persists its level', () {
    final upgrade = UpgradeCatalog.byId('prestige_money_boost').definition;
    final state = ProgressionState.initial.copyWith(
      prestige: BigNumber.fromInt(10),
    );
    final result = engine.purchasePrestigeUpgrade(state, upgrade);
    expect(result.prestige.toString(), '0');
    expect(result.prestigeUpgrades['prestige_money_boost'], 1);
  });

  test('Ultra upgrade purchase spends Ultra and persists its level', () {
    final upgrade = UpgradeCatalog.byId('ultra_money_boost').definition;
    final state = ProgressionState.initial.copyWith(
      ultra: BigNumber.fromInt(5),
    );
    final result = engine.purchaseUltraUpgrade(state, upgrade);
    expect(result.ultra.toString(), '0');
    expect(result.ultraUpgrades['ultra_money_boost'], 1);
  });
  test('fixed and MAX batch modes stop at the largest affordable prefix', () {
    final upgrade = UpgradeDefinition(
      id: 'batch_test',
      baseCost: BigNumber.fromInt(100),
      growthRate: BigNumber.fromInt(2),
      maxLevel: 10,
    );

    for (final multiplier in ['10', '100', 'MAX']) {
      expect(
        UpgradeBatchPolicy.affordableLevels(
          balance: BigNumber.fromInt(350),
          upgrade: upgrade,
          currentLevel: 0,
          multiplier: multiplier,
        ),
        2,
      );
    }
  });

  test(
    'batch policy respects selected count, remaining cap and no-funds case',
    () {
      final upgrade = UpgradeDefinition(
        id: 'batch_test',
        baseCost: BigNumber.fromInt(1),
        growthRate: BigNumber.fromInt(1),
        maxLevel: 3,
      );

      expect(
        UpgradeBatchPolicy.affordableLevels(
          balance: BigNumber.fromInt(100),
          upgrade: upgrade,
          currentLevel: 0,
          multiplier: '10',
        ),
        3,
      );
      expect(
        UpgradeBatchPolicy.affordableLevels(
          balance: BigNumber.fromInt(100),
          upgrade: upgrade,
          currentLevel: 0,
          multiplier: '100',
        ),
        3,
      );
      expect(
        UpgradeBatchPolicy.affordableLevels(
          balance: BigNumber.fromInt(0),
          upgrade: upgrade,
          currentLevel: 0,
          multiplier: 'MAX',
        ),
        0,
      );
      expect(
        UpgradeBatchPolicy.affordableLevels(
          balance: BigNumber.fromInt(100),
          upgrade: upgrade,
          currentLevel: 3,
          multiplier: 'MAX',
        ),
        0,
      );
    },
  );

  test('one-level mode never buys more than one level', () {
    final upgrade = UpgradeDefinition(
      id: 'batch_test',
      baseCost: BigNumber.fromInt(1),
      growthRate: BigNumber.fromInt(1),
      maxLevel: 10,
    );
    expect(
      UpgradeBatchPolicy.affordableLevels(
        balance: BigNumber.fromInt(100),
        upgrade: upgrade,
        currentLevel: 0,
        multiplier: '1',
      ),
      1,
    );
  });
}
