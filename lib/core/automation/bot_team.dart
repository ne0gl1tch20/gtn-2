import 'guessing_bot.dart';

class BotAction {
  const BotAction({
    required this.botId,
    required this.guess,
    required this.sequence,
    required this.delayMillis,
  });

  final String botId;
  final int guess;
  final int sequence;
  final int delayMillis;
}

/// Runtime state for GTN1's rotating Auto Clicker team.
///
/// The sequence is supplied by the save layer so it can survive restarts.
/// Search intervals intentionally remain in-memory, matching GTN1 where the
/// bot guessers are reset to the active range when the game is loaded.
class BotTeam {
  static const botIds = <String>[
    'auto_clicker_basic',
    'bot_byte',
    'bot_pixel',
  ];

  final GuessingBot _sharedGuesser = GuessingBot();
  final Map<String, GuessingBot> _independentGuessers = {};

  void reset(int minimum, int maximum) {
    _sharedGuesser.reset(minimum, maximum);
    for (final bot in _independentGuessers.values) {
      bot.reset(minimum, maximum);
    }
  }

  int delayMillis({
    required bool active,
    required double speed,
    required bool speedTalentOne,
    required bool speedTalentTwo,
    required bool speedMutator,
  }) {
    final talentMultiplier =
        (speedTalentOne ? 1.25 : 1.0) * (speedTalentTwo ? 1.5 : 1.0);
    final effectiveSpeed = speed * talentMultiplier * (speedMutator ? 3.0 : 1.0);
    if (!active || effectiveSpeed <= 0) return 1000;
    return (1000.0 / effectiveSpeed).toInt();
  }

  BotAction? nextAction({
    required Set<String> purchasedBots,
    required bool sharedMemory,
    required int sequence,
    required int rangeMinimum,
    required int rangeMaximum,
    required int currentMinimum,
    required int currentMaximum,
    required double speed,
    required bool speedTalentOne,
    required bool speedTalentTwo,
    required bool speedMutator,
  }) {
    if (purchasedBots.isEmpty) return null;
    final ownedBots = botIds.where(purchasedBots.contains).toList();
    if (ownedBots.isEmpty) return null;
    if (currentMinimum < rangeMinimum || currentMaximum > rangeMaximum ||
        currentMinimum > currentMaximum) {
      throw ArgumentError('Current game range must be inside the bot range.');
    }
    final botId = ownedBots[sequence % ownedBots.length];
    final guesser = sharedMemory || botId == 'auto_clicker_basic'
        ? _sharedGuesser
        : _independentGuessers.putIfAbsent(botId, () => GuessingBot());
    final proposed = guesser.nextGuess(
      rangeMinimum: rangeMinimum,
      rangeMaximum: rangeMaximum,
    );
    final guess = proposed.clamp(currentMinimum, currentMaximum).toInt();
    return BotAction(
      botId: botId,
      guess: guess,
      sequence: sequence + 1,
      delayMillis: delayMillis(
        active: true,
        speed: speed,
        speedTalentOne: speedTalentOne,
        speedTalentTwo: speedTalentTwo,
        speedMutator: speedMutator,
      ),
    );
  }

  void observe({
    required String botId,
    required int guess,
    required BotFeedback feedback,
    required bool sharedMemory,
    required int nextRangeMinimum,
    required int nextRangeMaximum,
  }) {
    final guesser = botId == 'auto_clicker_basic' || sharedMemory
        ? _sharedGuesser
        : _independentGuessers.putIfAbsent(botId, GuessingBot.new);
    guesser.observeGuess(guess, feedback);
    if (feedback == BotFeedback.correct) {
      reset(nextRangeMinimum, nextRangeMaximum);
    }
  }
}
