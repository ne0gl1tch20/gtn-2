import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_engine.dart';
import 'package:gtn_2/core/progression/progression_state.dart';
import 'package:gtn_2/shop/upgrade_catalog.dart';

void main() {
  const engine = ProgressionEngine();

  test('catalog upgrades have unique ids and finite level caps', () {
    final ids = UpgradeCatalog.all.map((item) => item.definition.id).toSet();
    expect(ids.length, UpgradeCatalog.all.length);
    for (final item in UpgradeCatalog.all) {
      expect(item.definition.maxLevel, isNotNull);
      expect(item.definition.maxLevel, greaterThan(0));
    }
  });

  test('Lucky Charm adds flat Money to each correct guess', () {
    final state = ProgressionState.initial.copyWith(
      upgrades: const {'lucky_charm': 3},
    );
    final effects = UpgradeCatalog.effectsFor(state, isFirstGuess: false);
    final result = engine.recordGuess(
      state,
      correct: true,
      baseReward: BigNumber.fromInt(1),
      flatBonusReward: effects.flatBonus,
      modifiers: GuessRewardModifiers(
        streakMultiplier: effects.streakMultiplier,
        criticalMultiplier: effects.firstGuessMultiplier,
      ),
    );
    expect(result.money.toString(), '4');
    expect(result.moneyEarned.toString(), '4');
  });

  test('Streak Engine applies multiplier at each five-correct milestone', () {
    final state = ProgressionState.initial.copyWith(
      currentStreak: 4,
      upgrades: const {'streak_engine': 2},
    );
    final effects = UpgradeCatalog.effectsFor(state, isFirstGuess: false);
    expect(effects.streakMultiplier, 3);
    final result = engine.recordGuess(
      state,
      correct: true,
      baseReward: BigNumber.fromInt(1),
      modifiers: GuessRewardModifiers(
        streakMultiplier: effects.streakMultiplier,
        criticalMultiplier: effects.firstGuessMultiplier,
      ),
    );
    expect(result.money.toString(), '3');
    expect(result.currentStreak, 5);
  });

  test('First Strike only boosts a first-guess correct answer', () {
    final state = ProgressionState.initial.copyWith(
      upgrades: const {'first_strike': 2},
    );
    final first = UpgradeCatalog.effectsFor(state, isFirstGuess: true);
    final later = UpgradeCatalog.effectsFor(state, isFirstGuess: false);
    expect(first.firstGuessMultiplier, 3);
    expect(later.firstGuessMultiplier, 1);
  });

  test('shop purchase spends Money and increments the selected level', () {
    final upgrade = UpgradeCatalog.byId('lucky_charm');
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(10),
    );
    final result = engine.purchaseUpgrade(state, upgrade.definition);
    expect(result.money.toString(), '0');
    expect(result.upgrades['lucky_charm'], 1);
  });

  test('unaffordable shop purchase leaves state unchanged', () {
    final upgrade = UpgradeCatalog.byId('first_strike');
    final state = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(10),
    );
    expect(engine.purchaseUpgrade(state, upgrade.definition), same(state));
  });
}
