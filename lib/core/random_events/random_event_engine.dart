import 'dart:math';

import '../numbers/big_number.dart';
import '../progression/progression_state.dart';

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
  String get id => switch (this) {
        RandomEventType.cashBurst => 'cash_burst',
        RandomEventType.nebulaRain => 'nebula_rain',
        RandomEventType.jackpot => 'jackpot',
        RandomEventType.streakSurge => 'streak_surge',
        RandomEventType.rangeShuffle => 'range_shuffle',
        RandomEventType.taxRefund => 'tax_refund',
        RandomEventType.cosmicGift => 'cosmic_gift',
      };
}

class RandomEventSelector {
  RandomEventSelector({Random? random}) : _random = random ?? Random();

  static const triggerProbability = 0.35;
  static const eventTypes = RandomEventType.values;

  final Random _random;

  RandomEventType? roll() {
    if (_random.nextDouble() >= triggerProbability) return null;
    return eventTypes[_random.nextInt(eventTypes.length)];
  }
}

class RandomEventResult {
  const RandomEventResult({
    required this.progression,
    required this.event,
    required this.message,
    this.newSecret,
  });

  final ProgressionState progression;
  final RandomEventType event;
  final String message;
  final int? newSecret;
}

class RandomEventEngine {
  RandomEventEngine({Random? random}) : _random = random ?? Random();

  final Random _random;

  RandomEventResult apply({
    required ProgressionState progression,
    required int currentRangeMin,
    required int currentRangeMax,
    required RandomEventType event,
  }) {
    if (currentRangeMin < 1 ||
        currentRangeMax < currentRangeMin ||
        currentRangeMax > 500) {
      throw ArgumentError('Random event range is invalid.');
    }

    var next = progression;
    int? newSecret;
    late final String message;
    switch (event) {
      case RandomEventType.cashBurst:
        final proportional = progression.money * BigNumber.parse('0.10');
        final bonus = proportional.compareTo(BigNumber.fromInt(100)) < 0
            ? BigNumber.fromInt(100)
            : proportional;
        next = progression.copyWith(
          money: progression.money + bonus,
          moneyEarned: progression.moneyEarned + bonus,
        );
        message = 'Random event: Cash Burst! +' + bonus.toString() + ' Money.';
        break;
      case RandomEventType.nebulaRain:
        final bonus = _random.nextInt(41) + 10;
        next = progression.copyWith(
          nebula: progression.nebula + BigNumber.fromInt(bonus),
          nebulaEarned: progression.nebulaEarned + BigNumber.fromInt(bonus),
        );
        message = 'Random event: Nebula Rain! +' + bonus.toString() + ' Nebula.';
        break;
      case RandomEventType.jackpot:
        final bonus = BigNumber.fromInt(1000).multiplyInt(currentRangeMax);
        next = progression.copyWith(
          money: progression.money + bonus,
          moneyEarned: progression.moneyEarned + bonus,
        );
        message = 'Random event: Jackpot! +' + bonus.toString() + ' Money.';
        break;
      case RandomEventType.streakSurge:
        final streak = progression.currentStreak + 2;
        next = progression.copyWith(
          currentStreak: streak,
          bestStreak: max(progression.bestStreak, streak),
        );
        message = 'Random event: Streak Surge! Your streak increased by 2.';
        break;
      case RandomEventType.rangeShuffle:
        newSecret = currentRangeMin +
            _random.nextInt(currentRangeMax - currentRangeMin + 1);
        message = 'Random event: Range Shuffle! The secret number changed.';
        break;
      case RandomEventType.taxRefund:
        final proportional = progression.moneySpent * BigNumber.parse('0.05');
        final bonus = proportional.compareTo(BigNumber.fromInt(100)) < 0
            ? BigNumber.fromInt(100)
            : proportional;
        next = progression.copyWith(
          money: progression.money + bonus,
          moneyEarned: progression.moneyEarned + bonus,
        );
        message = 'Random event: Tax Refund! +' + bonus.toString() + ' Money.';
        break;
      case RandomEventType.cosmicGift:
        const bonus = 100;
        next = progression.copyWith(
          nebula: progression.nebula + BigNumber.fromInt(bonus),
          nebulaEarned: progression.nebulaEarned + BigNumber.fromInt(bonus),
        );
        message = 'Random event: Cosmic Gift! +100 Nebula.';
        break;
    }

    final systems = next.legacySystems;
    next = next.copyWith(
      legacySystems: systems.copyWith(
        lastRandomEventId: event.id,
        randomEventsTriggered: systems.randomEventsTriggered + 1,
      ),
    );
    return RandomEventResult(
      progression: next,
      event: event,
      message: message,
      newSecret: newSecret,
    );
  }
}
