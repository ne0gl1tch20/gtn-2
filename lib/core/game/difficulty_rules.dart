/// Canonical GTN1 difficulty balance, ported from DifficultyRules.kt.
class DifficultyRules {
  DifficultyRules._();

  static const classic = 'classic';
  static const hard = 'hard';
  static const extreme = 'extreme';
  static const ids = <String>[classic, hard, extreme];

  static bool isValid(String id) => ids.contains(id);

  static String name(String id) => switch (id) {
    hard => 'Hard',
    extreme => 'Extreme',
    _ => 'Classic',
  };

  static int baseRangeMaximum(String id) => switch (id) {
    hard => 150,
    extreme => 250,
    _ => 100,
  };

  static int rangeMaximum(String id, int betterRangeLevel) =>
      (baseRangeMaximum(id) - betterRangeLevel.clamp(0, 20) * 5)
          .clamp(50, 250)
          .toInt();

  static double rewardMultiplier(String id) => switch (id) {
    hard => 1.5,
    extreme => 2.5,
    _ => 1.0,
  };

  static double wrongGuessPenalty(String id) => switch (id) {
    hard => 0.02,
    extreme => 0.05,
    _ => 0.0,
  };
}
