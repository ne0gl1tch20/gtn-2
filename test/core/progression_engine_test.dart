import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/achievement_catalog.dart';
import 'package:gtn_2/core/progression/progression_calculator.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';

void main() {
  const engine = ProgressionEngine();

  test(
    'bot guesses award rewards without changing player guess or streak stats',
    () {
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
    },
  );

  test('correct guesses award exact money and update streak stats', () {
    var state = engine.recordGuess(
      ProgressionState.initial,
      correct: true,
      baseReward: BigNumber.parse('1.25'),
      modifiers: const GuessRewardModifiers(
        streakMultiplier: 2,
        criticalMultiplier: 3,
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
      id: 'income',
      baseCost: BigNumber.fromInt(10),
      growthRate: BigNumber.fromInt(2),
      maxLevel: 3,
    );
    expect(upgrade.costAtLevel(0).toString(), '10');
    expect(upgrade.costAtLevel(1).toString(), '20');
    expect(upgrade.costAtLevel(2).toString(), '40');
    var state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(100),
    );
    state = engine.purchaseUpgrade(state, upgrade);
    expect(state.money.toString(), '90');
    expect(state.upgrades['income'], 1);
    state = engine.purchaseUpgrade(state, upgrade);
    state = engine.purchaseUpgrade(state, upgrade);
    expect(state.upgrades['income'], 3);
    expect(engine.purchaseUpgrade(state, upgrade), same(state));
  });

  test(
    'Prestige soft-resets normal upgrades and preserves permanent progress',
    () {
      final state = ProgressionState.initial.copyWith(
        money: BigNumber.fromInt(150),
        prestige: BigNumber.fromInt(4),
        ultra: BigNumber.fromInt(2),
        nebula: BigNumber.fromInt(30),
        upgrades: const {'income': 4},
        prestigeUpgrades: const {'permanent': 2},
      );
      final result = engine.prestige(
        state,
        PrestigeRules(
          minimumMoney: BigNumber.fromInt(100),
          rewardForMoney: (_) => BigNumber.fromInt(2),
        ),
      );
      expect(result.money.toString(), '0');
      expect(result.prestige.toString(), '6');
      expect(result.ultra.toString(), '2');
      expect(result.nebula.toString(), '30');
      expect(result.upgrades, isEmpty);
      expect(result.prestigeUpgrades['permanent'], 2);
      expect(result.prestigeResets, 1);
    },
  );

  test('Prestige is unavailable below configured threshold', () {
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(99),
    );
    final result = engine.prestige(
      state,
      PrestigeRules(
        minimumMoney: BigNumber.fromInt(100),
        rewardForMoney: (_) => BigNumber.fromInt(1),
      ),
    );
    expect(result, same(state));
  });

  test('Ultra payout is capped at 2,000 and resets Prestige progression', () {
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(1000000),
      prestige: BigNumber.fromInt(50),
      prestigeResets: 3,
      upgrades: const {'income': 5},
      prestigeUpgrades: const {'permanent': 1},
      nebula: BigNumber.fromInt(25),
    );
    final result = engine.ultra(
      state,
      UltraRules(
        minimumMoney: BigNumber.fromInt(100),
        rewardForMoney: (_) => 2500,
      ),
    );
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
      ProgressionState.initial,
      BigNumber.fromInt(30),
    );
    expect(rewarded.nebula.toString(), '30');
    expect(rewarded.nebulaEarned.toString(), '30');
    final bought = engine.purchaseNebulaItem(rewarded, itemId: 'arcade_boost');
    expect(bought.nebula.toString(), '5');
    expect(bought.nebulaItems['arcade_boost'], 1);
    expect(bought.money.toString(), '0');
  });
  test('Nebula permanent shop items cannot be purchased twice', () {
    final rich = ProgressionState.initial.copyWith(
      nebula: BigNumber.fromInt(200),
    );
    final bought = engine.purchaseNebulaItem(
      rich,
      itemId: 'nebula_boost',
      price: BigNumber.fromInt(50),
    );
    expect(bought.nebula.toString(), '150');
    expect(
      engine.purchaseNebulaItem(
        bought,
        itemId: 'nebula_boost',
        price: BigNumber.fromInt(50),
      ),
      same(bought),
    );
  });

  test('Nebula cosmetics can be purchased once and equipped only when owned', () {
    final rich = ProgressionState.initial.copyWith(
      nebula: BigNumber.fromInt(500),
    );
    final bought = engine.purchaseNebulaItem(
      rich,
      itemId: 'cosmetic_nebula_ring',
      price: BigNumber.fromInt(75),
    );
    expect(bought.nebula.toString(), '425');
    expect(bought.nebulaItems['cosmetic_nebula_ring'], 1);
    expect(
      engine.purchaseNebulaItem(
        bought,
        itemId: 'cosmetic_nebula_ring',
        price: BigNumber.fromInt(75),
      ),
      same(bought),
    );
    expect(
      engine.equipNebulaCosmetic(
        ProgressionState.initial,
        'cosmetic_nebula_ring',
      ),
      same(ProgressionState.initial),
    );
    final equipped = engine.equipNebulaCosmetic(
      bought,
      'cosmetic_nebula_ring',
    );
    expect(equipped.equippedCosmeticId, 'cosmetic_nebula_ring');
    expect(
      engine.equipNebulaCosmetic(equipped, 'cosmetic_starfield'),
      same(equipped),
    );
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
    final result = engine.ultra(state, ProgressionCalculator.ultraRules(state));
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
    final result = engine.awardNebulaFromArcade(state, BigNumber.fromInt(5));
    expect(result.nebula.toString(), '30');
    expect(result.nebulaEarned.toString(), '30');
  });

  test('GTN1 achievement catalog unlocks exact milestones and pays once', () {
    final before = ProgressionState.initial.copyWith(
      correctGuesses: 50,
      totalGuesses: 50,
      bestStreak: 10,
      currentStreak: 10,
      money: BigNumber.fromInt(10000000),
      prestigeResets: 5,
      ultraResets: 3,
      playtimeSeconds: 36000,
    );
    final unlocked = engine.evaluateAchievements(before);
    expect(AchievementCatalog.all, hasLength(27));
    expect(
      unlocked.achievements,
      containsAll([
        'correct_10',
        'correct_50',
        'streak_5',
        'streak_10',
        'millionaire',
        'ten_millionaire',
        'prestige_1',
        'prestige_5',
        'ultra_1',
        'ultra_3',
        'playtime_1h',
        'playtime_10h',
        'frenzy_5',
        'frenzy_10',
      ]),
    );
    expect(unlocked.nebula.toString(), '935');
    expect(unlocked.nebulaEarned.toString(), '935');
    expect(engine.evaluateAchievements(unlocked), same(unlocked));
  });

  test('achievement rewards apply GTN1 Nebula multipliers exactly once', () {
    final state = ProgressionState.initial.copyWith(
      correctGuesses: 10,
      totalGuesses: 10,
      ultraUpgrades: const {'ultra_nebula_boost': 2},
      nebulaItems: const {'nebula_boost': 1},
    );
    final unlocked = engine.evaluateAchievements(state);
    expect(unlocked.achievements, contains('correct_10'));
    expect(unlocked.nebula.toString(), '60');
    expect(unlocked.nebulaEarned.toString(), '60');
    expect(engine.evaluateAchievements(unlocked).nebula.toString(), '60');
  });

  test('achievement evaluation respects exact thresholds', () {
    final below = ProgressionState.initial.copyWith(
      correctGuesses: 9,
      totalGuesses: 9,
      bestStreak: 4,
      money: BigNumber.fromInt(999999),
      playtimeSeconds: 3599,
    );
    expect(engine.evaluateAchievements(below).achievements, isEmpty);
    expect(engine.evaluateAchievements(below).nebula.toString(), '0');
  });
}
