import 'dart:math';

import '../game/game_engine.dart';
import '../numbers/big_number.dart';
import 'progression_state.dart';

enum RandomEventType {
  cashBurst,
  nebulaRain,
  jackpot,
  streakSurge,
  rangeShuffle,
  taxRefund,
  cosmicGift,
}

extension RandomEventTypeId on RandomEventType {
  String get luaId => switch (this) {
    RandomEventType.cashBurst => 'CASH_BURST',
    RandomEventType.nebulaRain => 'NEBULA_RAIN',
    RandomEventType.jackpot => 'JACKPOT',
    RandomEventType.streakSurge => 'STREAK_SURGE',
    RandomEventType.rangeShuffle => 'RANGE_SHUFFLE',
    RandomEventType.taxRefund => 'TAX_REFUND',
    RandomEventType.cosmicGift => 'COSMIC_GIFT',
  };

  String get saveId => switch (this) {
    RandomEventType.cashBurst => 'cash_burst',
    RandomEventType.nebulaRain => 'nebula_rain',
    RandomEventType.jackpot => 'jackpot',
    RandomEventType.streakSurge => 'streak_surge',
    RandomEventType.rangeShuffle => 'range_shuffle',
    RandomEventType.taxRefund => 'tax_refund',
    RandomEventType.cosmicGift => 'cosmic_gift',
  };
}

RandomEventType? randomEventTypeFromLuaId(String? id) => switch (id) {
  'CASH_BURST' => RandomEventType.cashBurst,
  'NEBULA_RAIN' => RandomEventType.nebulaRain,
  'JACKPOT' => RandomEventType.jackpot,
  'STREAK_SURGE' => RandomEventType.streakSurge,
  'RANGE_SHUFFLE' => RandomEventType.rangeShuffle,
  'TAX_REFUND' => RandomEventType.taxRefund,
  'COSMIC_GIFT' => RandomEventType.cosmicGift,
  _ => null,
};

class RandomEventResult {
  const RandomEventResult({
    required this.type,
    required this.progression,
    required this.game,
  });

  final RandomEventType type;
  final ProgressionState progression;
  final GameState game;
}

/// Applies a Lua-approved event using Dart-owned economy and game transactions.
/// Lua never receives or mutates ProgressionState or GameState.
class RandomEventEngine {
  RandomEventEngine({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  static final _minimumCashBurst = BigNumber.fromInt(100);
  static final _minimumTaxRefund = BigNumber.fromInt(100);

  RandomEventResult apply({
    required ProgressionState progression,
    required GameState game,
    required RandomEventType type,
  }) {
    if (game.minimum > game.maximum) {
      throw ArgumentError('Game range is invalid.');
    }
    final base = progression.copyWith(
      randomEventsTriggered: progression.randomEventsTriggered + 1,
      lastRandomEventId: type.saveId,
    );

    switch (type) {
      case RandomEventType.cashBurst:
        final percentageBonus = progression.money * BigNumber.parse('0.10');
        final bonus = percentageBonus.compareTo(_minimumCashBurst) < 0
            ? _minimumCashBurst
            : percentageBonus;
        return RandomEventResult(
          type: type,
          progression: base.copyWith(
            money: base.money + bonus,
            moneyEarned: base.moneyEarned + bonus,
          ),
          game: game,
        );
      case RandomEventType.nebulaRain:
        final bonus = BigNumber.fromInt(10 + _random.nextInt(41));
        return RandomEventResult(
          type: type,
          progression: base.copyWith(
            nebula: base.nebula + bonus,
            nebulaEarned: base.nebulaEarned + bonus,
          ),
          game: game,
        );
      case RandomEventType.jackpot:
        final bonus = BigNumber.fromInt(1000).multiplyInt(game.maximum);
        return RandomEventResult(
          type: type,
          progression: base.copyWith(
            money: base.money + bonus,
            moneyEarned: base.moneyEarned + bonus,
          ),
          game: game,
        );
      case RandomEventType.streakSurge:
        final streak = base.currentStreak + 2;
        return RandomEventResult(
          type: type,
          progression: base.copyWith(
            currentStreak: streak,
            bestStreak: streak > base.bestStreak ? streak : base.bestStreak,
          ),
          game: game,
        );
      case RandomEventType.rangeShuffle:
        final rangeSize = game.maximum - game.minimum + 1;
        final target = game.minimum + _random.nextInt(rangeSize);
        return RandomEventResult(
          type: type,
          progression: base,
          game: GameState(
            secret: target,
            attempts: game.attempts,
            isComplete: game.isComplete,
            lastResult: game.lastResult,
            minimum: game.minimum,
            maximum: game.maximum,
          ),
        );
      case RandomEventType.taxRefund:
        final percentageRefund =
            progression.moneySpent * BigNumber.parse('0.05');
        final refund = percentageRefund.compareTo(_minimumTaxRefund) < 0
            ? _minimumTaxRefund
            : percentageRefund;
        return RandomEventResult(
          type: type,
          progression: base.copyWith(
            money: base.money + refund,
            moneyEarned: base.moneyEarned + refund,
          ),
          game: game,
        );
      case RandomEventType.cosmicGift:
        final bonus = BigNumber.fromInt(100);
        return RandomEventResult(
          type: type,
          progression: base.copyWith(
            nebula: base.nebula + bonus,
            nebulaEarned: base.nebulaEarned + bonus,
          ),
          game: game,
        );
    }
  }
}
