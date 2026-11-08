import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_calculator.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';

void main() {
  const engine = ProgressionEngine();

  test('bot guesses award rewards without changing player guess or streak stats', () {
    final before = ProgressionState.initial.copyWith(
      totalGuesses: 12,
      correctGuesses: 7,
      currentStreak: 4,
      bestStreak: 9,
    );
    final correct = engine.recordGuess(
      before,
      correct: true,
      baseReward: BigNumber.fromInt(25),
      isBot: true,
    );
    expect(correct.money.toString(), '25');
    expect(correct.moneyEarned.toString(), '25');
    expect(correct.totalGuesses, 12);
    expect(correct.correctGuesses, 7);
    expect(correct.currentStreak, 4);
    expect(correct.bestStreak, 9);

    final miss = engine.recordGuess(before, correct: false, isBot: true);
    expect(miss.totalGuesses, 12);
    expect(miss.currentStreak, 4);
  });

  test('correct guesses award exact money and update streak stats', () {
    var state = engine.recordGuess(
      ProgressionState.initial,
      correct: true,
      baseReward: BigNumber.parse('1.25'),
      modifiers: const GuessRewardModifiers(
        streakMultiplier: 2, criticalMultiplier: 3,
      ),
    );
    expect(state.money.toString(), '7.5');
    expect(state.correctGuesses, 1);
    expect(state.currentStreak, 1);
    expect(state.bestStreak, 1);
    state = engine.recordGuess(state, correct: false);
    expect(state.money.toString(), '7.5');
    expect(state.currentStreak, 0);
    expect(state.totalGuesses, 2);
  });

  test('upgrade pricing follows baseCost times growthRate to level', () {
    final upgrade = UpgradeDefinition(
      id: 'income', baseCost: BigNumber.fromInt(10),
      growthRate: BigNumber.fromInt(2), maxLevel: 3,
    );
    expect(upgrade.costAtLevel(0).toString(), '10');
    expect(upgrade.costAtLevel(1).toString(), '20');
    expect(upgrade.costAtLevel(2).toString(), '40');
    var state = ProgressionState.initial.copyWith(money: BigNumber.fromInt(100));
    state = engine.purchaseUpgrade(state, upgrade);
    expect(state.money.toString(), '90');
    expect(state.upgrades['income'], 1);
    state = engine.purchaseUpgrade(state, upgrade);
    state = engine.purchaseUpgrade(state, upgrade);
    expect(state.upgrades['income'], 3);
    expect(engine.purchaseUpgrade(state, upgrade), same(state));
  });

  test('permanent Prestige and Ultra shop items spend exact currency once', () {
    var state = ProgressionState.initial.copyWith(
      prestige: BigNumber.fromInt(350),
      ultra: BigNumber.fromInt(11000),
    );

    state = engine.purchasePrestigeShopItem(state, 'prestige_auto_speed');
    expect(state.prestige.toString(), '250');
    expect(state.prestigeShopPurchases, contains('prestige_auto_speed'));
    expect(
      engine.purchasePrestigeShopItem(state, 'prestige_auto_speed'),
      same(state),
    );

    state = engine.purchasePrestigeShopItem(state, 'prestige_luck_charm');
    expect(state.prestige.toString(), '0');
    expect(state.prestigeShopPurchases, containsAll({
      'prestige_auto_speed',
      'prestige_luck_charm',
    }));

    state = engine.purchaseUltraShopItem(state, 'ultra_universal_harmony');
    expect(state.ultra.toString(), '10500');
    state = engine.purchaseUltraShopItem(state, 'ultra_infinite_multiplier');
    expect(state.ultra.toString(), '9500');
    state = engine.purchaseUltraShopItem(state, 'ultra_flex_badge');
    expect(state.ultra.toString(), '0');
    expect(state.ultraShopPurchases, containsAll({
      'ultra_universal_harmony',
      'ultra_infinite_multiplier',
      'ultra_flex_badge',
    }));
  });

  test('permanent shop rejects unknown and unaffordable items atomically', () {
    final state = ProgressionState.initial.copyWith(
      prestige: BigNumber.fromInt(99),
      ultra: BigNumber.fromInt(499),
    );
    expect(
      engine.purchasePrestigeShopItem(state, 'not_a_real_item'),
      same(state),
    );
    expect(
      engine.purchasePrestigeShopItem(state, 'prestige_auto_speed'),
      same(state),
    );
    expect(
      engine.purchaseUltraShopItem(state, 'ultra_universal_harmony'),
      same(state),
    );
  });

  test('Prestige and Ultra resets preserve permanent shop ownership', () {
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(1000),
      prestige: BigNumber.fromInt(1000),
      prestigeShopPurchases: const {'prestige_auto_speed', 'prestige_luck_charm'},
      ultraShopPurchases: const {
        'ultra_universal_harmony',
        'ultra_infinite_multiplier',
      },
    );
    final afterPrestige = engine.prestige(
      state,
      PrestigeRules(
        minimumMoney: BigNumber.fromInt(100),
        rewardForMoney: (_) => BigNumber.fromInt(10),
      ),
    );
    expect(afterPrestige.prestigeShopPurchases, state.prestigeShopPurchases);
    expect(afterPrestige.ultraShopPurchases, state.ultraShopPurchases);

    final afterUltra = engine.ultra(
      afterPrestige.copyWith(money: BigNumber.fromInt(1000)),
      UltraRules(
        minimumMoney: BigNumber.fromInt(100),
        rewardForMoney: (_) => 5,
      ),
    );
    expect(afterUltra.prestigeShopPurchases, state.prestigeShopPurchases);
    expect(afterUltra.ultraShopPurchases, state.ultraShopPurchases);
  });

  test('Prestige soft-resets normal upgrades and preserves permanent progress', () {
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(150), prestige: BigNumber.fromInt(4),
      ultra: BigNumber.fromInt(2), nebula: BigNumber.fromInt(30),
      upgrades: const {'income': 4}, prestigeUpgrades: const {'permanent': 2},
    );
    final result = engine.prestige(state, PrestigeRules(
      minimumMoney: BigNumber.fromInt(100),
      rewardForMoney: (_) => BigNumber.fromInt(2),
    ));
    expect(result.money.toString(), '0');
    expect(result.prestige.toString(), '6');
    expect(result.ultra.toString(), '2');
    expect(result.nebula.toString(), '30');
    expect(result.upgrades, isEmpty);
    expect(result.prestigeUpgrades['permanent'], 2);
    expect(result.prestigeResets, 1);
  });

  test('Prestige is unavailable below configured threshold', () {
    final state = ProgressionState.initial.copyWith(money: BigNumber.fromInt(99));
    final result = engine.prestige(state, PrestigeRules(
      minimumMoney: BigNumber.fromInt(100),
      rewardForMoney: (_) => BigNumber.fromInt(1),
    ));
    expect(result, same(state));
  });

  test('Ultra payout is capped at 2,000 and resets Prestige progression', () {
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(1000000), prestige: BigNumber.fromInt(50),
      prestigeResets: 3, upgrades: const {'income': 5},
      prestigeUpgrades: const {'permanent': 1}, nebula: BigNumber.fromInt(25),
    );
    final result = engine.ultra(state, UltraRules(
      minimumMoney: BigNumber.fromInt(100),
      rewardForMoney: (_) => 2500,
    ));
    expect(result.ultra.toString(), '2000');
    expect(result.money.toString(), '0');
    expect(result.prestige.toString(), '0');
    expect(result.prestigeResets, 0);
    expect(result.ultraResets, 1);
    expect(result.upgrades, isEmpty);
    expect(result.prestigeUpgrades, isEmpty);
    expect(result.nebula.toString(), '25');
  });

  test('Arcade Nebula rewards and 25-Nebula shop purchases are separate', () {
    final rewarded = engine.awardNebulaFromArcade(
      ProgressionState.initial, BigNumber.fromInt(30),
    );
    expect(rewarded.nebula.toString(), '30');
    expect(rewarded.nebulaEarned.toString(), '30');
    final bought = engine.purchaseNebulaItem(rewarded, itemId: 'arcade_boost');
    expect(bought.nebula.toString(), '5');
    expect(bought.nebulaItems['arcade_boost'], 1);
    expect(bought.money.toString(), '0');
  });
  test('Prestige gain and starting capital upgrades match GTN1', () {
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(50000000),
      prestigeUpgrades: const {
        'prestige_gain_boost': 5,
        'prestige_starting_capital': 3,
      },
    );
    final result = engine.prestige(
      state,
      ProgressionCalculator.prestigeRules(state),
    );
    expect(result.prestige.toString(), '2');
    expect(result.money.toString(), '3000');
    expect(result.upgrades, isEmpty);
    expect(result.prestigeUpgrades['prestige_gain_boost'], 5);
  });

  test('Ultra gain boost and Prestige starting capital match GTN1', () {
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(1000000000000),
      prestige: BigNumber.fromInt(1000),
      prestigeUpgrades: const {'prestige_starting_capital': 3},
      ultraUpgrades: const {'ultra_gain_boost': 2},
    );
    final result = engine.ultra(
      state,
      ProgressionCalculator.ultraRules(state),
    );
    expect(result.ultra.toString(), '400');
    expect(result.money.toString(), '3000');
    expect(result.prestige.toString(), '0');
    expect(result.prestigeUpgrades, isEmpty);
    expect(result.ultraUpgrades['ultra_gain_boost'], 2);
  });

  test('Ultra Nebula upgrade stacks with the Nebula shop boost', () {
    final state = ProgressionState.initial.copyWith(
      nebulaItems: const {'nebula_boost': 1},
      ultraUpgrades: const {'ultra_nebula_boost': 2},
    );
    final result = engine.awardNebulaFromArcade(
      state,
      BigNumber.fromInt(5),
    );
    expect(result.nebula.toString(), '30');
    expect(result.nebulaEarned.toString(), '30');
  });

}
