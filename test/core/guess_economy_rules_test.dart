import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/game/guess_economy_rules.dart';
import 'package:gtn_2/core/legacy/legacy_systems_engine.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/shop/upgrade_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(UpgradeCatalog.load);

  test('loads the exact eleven source GTN1 normal upgrade definitions', () {
    expect(
      UpgradeCatalog.all.map((item) => item.definition.id).toList(),
      [
        'reward_multiplier',
        'better_range',
        'critical_boost',
        'starting_money_boost',
        'auto_efficiency',
        'prestige_boost',
        'lucky_multiplier',
        'critical_multiplier',
        'auto_income_boost',
        'ultra_efficiency',
        'discount_bargain',
      ],
    );
    expect(UpgradeCatalog.byId('reward_multiplier').definition.baseCost.toString(), '100');
    expect(UpgradeCatalog.byId('reward_multiplier').definition.growthRate.toString(), '1.5');
    expect(UpgradeCatalog.byId('better_range').definition.maxLevel, 20);
  });

  test('shop exposes only upgrades whose source gameplay behavior is wired', () {
    expect(
      UpgradeCatalog.availableForGameplay.map((item) => item.definition.id).toSet(),
      {'reward_multiplier', 'better_range'},
    );
  });

  test('reward multiplier purchase price follows canonical source values', () {
    final upgrade = UpgradeCatalog.byId('reward_multiplier').definition;
    expect(upgrade.costAtLevel(0).toString(), '100');
    expect(upgrade.costAtLevel(1).toString(), '150');
    expect(upgrade.costAtLevel(2).toString(), '225');
  });

  test('GTN1 base reward uses 100 money per range unit and minimum ten', () {
    final reward = GuessEconomyRules.correctGuessReward(
      rangeMaximum: 100,
      currentStreak: 0,
      rewardMultiplierLevel: 0,
      hasTalentReward: false,
      isCritical: false,
      difficultyId: 'classic',
      mutatorMultiplier: BigNumber.fromInt(1),
      traitMultiplier: BigNumber.fromInt(1),
      permanentMoneyMultiplier: BigNumber.fromInt(1),
    );
    expect(reward.toString(), '10000');

    final minimum = GuessEconomyRules.correctGuessReward(
      rangeMaximum: 1,
      currentStreak: 0,
      rewardMultiplierLevel: 0,
      hasTalentReward: false,
      isCritical: false,
      difficultyId: 'classic',
      mutatorMultiplier: BigNumber.fromInt(1),
      traitMultiplier: BigNumber.parse('0.01'),
      permanentMoneyMultiplier: BigNumber.fromInt(1),
    );
    expect(minimum.toString(), '10');
  });

  test('Prestige talent reward bonus is applied once after the base guess reward', () {
    final before = ProgressionState.initial;
    final rawReward = GuessEconomyRules.correctGuessReward(
      rangeMaximum: 100,
      currentStreak: 0,
      rewardMultiplierLevel: 0,
      // The GTN1 Prestige talent is not GameEngine's shopPurchases/upgradeLevels flag.
      hasTalentReward: false,
      isCritical: false,
      difficultyId: 'classic',
      mutatorMultiplier: BigNumber.fromInt(1),
      traitMultiplier: BigNumber.fromInt(1),
      permanentMoneyMultiplier: BigNumber.fromInt(1),
    );
    expect(rawReward.toString(), '10000');

    final afterRawReward = before.copyWith(
      money: rawReward,
      moneyEarned: rawReward,
    );
    final adjusted = const LegacySystemsEngine().applyCorrectGuessBonuses(
      before: before,
      after: afterRawReward,
      systems: LegacySystemsState.initial.copyWith(
        talents: const {'talent_reward_1'},
      ),
    );

    // GTN1 adds +50% in applyTalentBonuses. Applying it in both the base
    // reward and the post-reward bonus would incorrectly produce 22,500.
    expect(adjusted.money.toString(), '15000');
    expect(adjusted.moneyEarned.toString(), '15000');
  });

  test('Critical Precision talents proc only in the GTN1 post-reward bonus', () {
    final before = ProgressionState.initial;
    final rawReward = BigNumber.fromInt(10000);
    final afterRawReward = before.copyWith(
      money: rawReward,
      moneyEarned: rawReward,
    );
    const engine = LegacySystemsEngine();

    for (final talentId in ['talent_crit_1', 'talent_crit_2']) {
      final systems = LegacySystemsState.initial.copyWith(
        talents: {talentId},
      );
      final baseReward = engine.correctGuessReward(
        baseReward: rawReward,
        systems: systems,
        criticalHit: true,
      );
      expect(
        baseReward.toString(),
        '10000',
        reason: '$talentId must not add a second base-reward multiplier',
      );

      final noProc = engine.applyCorrectGuessBonuses(
        before: before,
        after: afterRawReward,
        systems: systems,
        criticalHit: false,
      );
      final proc = engine.applyCorrectGuessBonuses(
        before: before,
        after: afterRawReward,
        systems: systems,
        criticalHit: true,
      );
      expect(noProc.money.toString(), '10000');
      expect(proc.money.toString(), '20000');
      expect(proc.moneyEarned.toString(), '20000');
    }
  });

  test('Omniscient Oracle awards its source-implemented Nebula bonus once', () {
    final before = ProgressionState.initial;
    final rawReward = BigNumber.fromInt(10000);
    final afterRawReward = before.copyWith(
      money: rawReward,
      moneyEarned: rawReward,
    );
    final adjusted = const LegacySystemsEngine().applyCorrectGuessBonuses(
      before: before,
      after: afterRawReward,
      systems: LegacySystemsState.initial.copyWith(
        talents: const {'talent_master_1'},
      ),
    );

    expect(adjusted.nebula.toString(), '1');
    expect(adjusted.nebulaEarned.toString(), '1');
  });

  test('streak and frenzy formulas match GTN1 five-guess tiers', () {
    expect(GuessEconomyRules.streakMultiplier(4), 1.4);
    expect(GuessEconomyRules.frenzyMultiplier(4), 1);
    expect(GuessEconomyRules.frenzyMultiplier(5), 1.25);
    expect(GuessEconomyRules.frenzyMultiplier(10), 1.5);
    expect(GuessEconomyRules.frenzyMultiplier(100), 5);
  });

  test('reward combines GTN1 streak, frenzy, critical, upgrade and difficulty', () {
    final reward = GuessEconomyRules.correctGuessReward(
      rangeMaximum: 100,
      currentStreak: 5,
      rewardMultiplierLevel: 2,
      hasTalentReward: true,
      isCritical: true,
      difficultyId: 'hard',
      mutatorMultiplier: BigNumber.fromInt(1),
      traitMultiplier: BigNumber.fromInt(1),
      permanentMoneyMultiplier: BigNumber.fromInt(1),
    );
    // 10,000 × 1.5 streak × 1.25 frenzy × 5 critical × 1.5 upgrade
    // × 1.5 talent × 1.5 Hard difficulty.
    expect(reward.toString(), '316406.25');
  });

  test('permanent Prestige and Ultra money boosts compound as in GTN1', () {
    final state = ProgressionState.initial.copyWith(
      prestigeUpgrades: const {'prestige_money_boost': 2},
      ultraUpgrades: const {'ultra_money_boost': 3},
    );
    expect(GuessEconomyRules.moneyEarningMultiplier(state).toString(), '14');
  });

  test('critical chance starts at five percent and adds one percent per level', () {
    expect(GuessEconomyRules.criticalChance(0), 0.05);
    expect(GuessEconomyRules.criticalChance(5), 0.10);
  });
}
