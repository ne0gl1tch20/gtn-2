/// Reward formulas shared by GTN1 Android and Windows Arcade minigames.
class ArcadeRewardRules {
  const ArcadeRewardRules._();

  static const int tooEarlyReactionSentinel = 9999;

  static bool isReactionTestRewardEligible(int reactionTimeMillis) =>
      reactionTimeMillis >= 0 && reactionTimeMillis != tooEarlyReactionSentinel;

  /// Memory Match rewards are claimable only after a submitted correct answer.
  static bool isMemoryMatchRewardEligible({
    required bool submitted,
    required bool correct,
  }) => submitted && correct;

  /// One guaranteed Nebula plus capped time and score bonuses.
  static int calculateNebulaReward(int playSeconds, int score) {
    final timeBonus = (playSeconds < 0 ? 0 : playSeconds ~/ 30)
        .clamp(0, 4)
        .toInt();
    final scoreBonus = (score < 0 ? 0 : score ~/ 5).clamp(0, 5).toInt();
    return (1 + timeBonus + scoreBonus).clamp(0, 10).toInt();
  }

  /// Small Money reward based on validated elapsed time and score.
  static int calculateMoneyReward(int playSeconds, int score) {
    final safeSeconds = playSeconds.clamp(0, 600).toInt();
    final safeScore = score < 0 ? 0 : score;
    final reward = safeScore * 300 + safeSeconds * 25;
    return reward.clamp(0, 1000000).toInt();
  }
}
