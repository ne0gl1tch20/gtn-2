import '../core/numbers/big_number.dart';
import '../core/progression/progression_engine.dart';

class UpgradeBatchPolicy {
  const UpgradeBatchPolicy._();

  static int affordableLevels({
    required BigNumber balance,
    required UpgradeDefinition upgrade,
    required int currentLevel,
    required String multiplier,
  }) {
    if (currentLevel < 0) {
      throw ArgumentError.value(currentLevel, 'currentLevel');
    }
    final maxLevel = upgrade.maxLevel ?? 999999;
    final remaining = maxLevel - currentLevel;
    if (remaining <= 0) return 0;

    final requested = switch (multiplier) {
      '10' => 10,
      '100' => 100,
      'MAX' => remaining,
      _ => 1,
    };
    final limit = requested < remaining ? requested : remaining;
    var count = 0;
    var totalCost = BigNumber.fromInt(0);
    while (count < limit) {
      final nextCost = upgrade.costAtLevel(currentLevel + count);
      if (balance.compareTo(totalCost + nextCost) < 0) break;
      totalCost += nextCost;
      count++;
    }
    return count;
  }
}
