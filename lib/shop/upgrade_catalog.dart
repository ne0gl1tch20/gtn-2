import '../core/numbers/big_number.dart';
import '../core/progression/progression_engine.dart';
import '../core/progression/progression_state.dart';

class UpgradeRewardEffects {
  const UpgradeRewardEffects({
    required this.flatBonus,
    required this.streakMultiplier,
    required this.firstGuessMultiplier,
  });

  final BigNumber flatBonus;
  final int streakMultiplier;
  final int firstGuessMultiplier;
}

class GameUpgrade {
  const GameUpgrade({
    required this.definition,
    required this.name,
    required this.description,
    required this.effectDescription,
  });

  final UpgradeDefinition definition;
  final String name;
  final String description;
  final String effectDescription;
}

/// Starter catalog values are centralized so they can be rebalanced without
/// changing save data or the progression engine.
class UpgradeCatalog {
  UpgradeCatalog._();

  static final List<GameUpgrade> all = List.unmodifiable([
    GameUpgrade(
      definition: UpgradeDefinition(
        id: 'lucky_charm',
        baseCost: BigNumber.fromInt(10),
        growthRate: BigNumber.parse('1.8'),
        maxLevel: 20,
      ),
      name: 'Lucky Charm',
      description: 'Adds a little extra Money to every correct guess.',
      effectDescription: '+1 base Money per level',
    ),
    GameUpgrade(
      definition: UpgradeDefinition(
        id: 'streak_engine',
        baseCost: BigNumber.fromInt(40),
        growthRate: BigNumber.parse('1.9'),
        maxLevel: 10,
      ),
      name: 'Streak Engine',
      description: 'Build bigger rewards by keeping your correct-guess streak alive.',
      effectDescription: '+1× reward per 5-streak milestone, per level',
    ),
    GameUpgrade(
      definition: UpgradeDefinition(
        id: 'first_strike',
        baseCost: BigNumber.fromInt(75),
        growthRate: BigNumber.fromInt(2),
        maxLevel: 5,
      ),
      name: 'First Strike',
      description: 'Earn a bonus when your first guess of a round is correct.',
      effectDescription: '+1× first-guess reward multiplier per level',
    ),
  ]);

  static GameUpgrade byId(String id) =>
      all.firstWhere((upgrade) => upgrade.definition.id == id);

  static UpgradeRewardEffects effectsFor(
    ProgressionState state, {
    required bool isFirstGuess,
  }) {
    final luckyLevel = state.upgrades['lucky_charm'] ?? 0;
    final streakLevel = state.upgrades['streak_engine'] ?? 0;
    final firstStrikeLevel = state.upgrades['first_strike'] ?? 0;
    final nextStreak = state.currentStreak + 1;
    final streakMilestones = nextStreak ~/ 5;

    return UpgradeRewardEffects(
      flatBonus: BigNumber.fromInt(luckyLevel),
      streakMultiplier: 1 + streakMilestones * streakLevel,
      firstGuessMultiplier: isFirstGuess ? 1 + firstStrikeLevel : 1,
    );
  }
}
