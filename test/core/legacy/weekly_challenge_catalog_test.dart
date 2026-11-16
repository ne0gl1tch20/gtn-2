import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/legacy_systems_engine.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/core/legacy/weekly_challenge_catalog.dart';
import 'package:gtn_2/core/numbers/big_number.dart';
import 'package:gtn_2/core/progression/progression_state.dart';

void main() {
  group('WeeklyChallengeCatalog', () {
    test('uses ISO week-year IDs across calendar-year boundaries', () {
      final newYear = WeeklyChallengeCatalog.isoWeek(DateTime(2021, 1, 1));
      expect(newYear.year, 2020);
      expect(newYear.week, 53);

      final firstWeek = WeeklyChallengeCatalog.isoWeek(DateTime(2026, 1, 1));
      expect(firstWeek.year, 2026);
      expect(firstWeek.week, 1);
    });

    test('returns three deterministic source-matched challenges per week', () {
      final challenges = WeeklyChallengeCatalog.forDate(
        DateTime(2026, 11, 16),
      );

      expect(
        challenges.map((challenge) => challenge.id).toList(),
        [
          'weekly_2026_47_frenzy',
          'weekly_2026_47_correct',
          'weekly_2026_47_money',
        ],
      );
      expect(
        challenges.map((challenge) => challenge.rewardNebula).toList(),
        [110, 75, 100],
      );
      expect(challenges.map((challenge) => challenge.target).toList(), [
        25,
        75,
        10000000,
      ]);
    });

    test('rotates every challenge kind through the eight-week pool', () {
      final firstWeek = DateTime(2025, 12, 29);
      final kinds = <String>{};

      for (var week = 0; week < 8; week++) {
        final date = firstWeek.add(Duration(days: week * 7));
        final challenges = WeeklyChallengeCatalog.forDate(date);
        expect(challenges, hasLength(3));
        kinds.addAll(challenges.map((challenge) => challenge.kind));
      }

      expect(
        kinds,
        {
          'correct',
          'streak',
          'money',
          'guesses',
          'prestige',
          'ultra',
          'frenzy',
          'playtime',
        },
      );
    });
  });

  group('LegacySystemsEngine weekly challenge claims', () {
    const engine = LegacySystemsEngine();

    final eligibleProgression = ProgressionState.initial.copyWith(
      money: BigNumber.fromInt(10000000),
      correctGuesses: 100,
      bestStreak: 30,
      totalGuesses: 500,
      prestigeResets: 2,
      ultraResets: 1,
      playtimeSeconds: 3600,
    );

    test('validates all eight objective kinds and exact boosted rewards', () {
      final firstWeek = DateTime(2025, 12, 29);

      for (var week = 0; week < 8; week++) {
        final today = firstWeek.add(Duration(days: week * 7));
        for (final challenge in WeeklyChallengeCatalog.forDate(today)) {
          final result = engine.claimWeeklyChallenge(
            progression: eligibleProgression,
            systems: LegacySystemsState.initial,
            challengeId: challenge.id,
            today: today,
            nebulaBoostOwned: true,
          );

          expect(result.accepted, isTrue, reason: challenge.id);
          expect(
            result.progression.nebula,
            BigNumber.fromInt(challenge.rewardNebula * 2),
            reason: challenge.id,
          );
          expect(
            result.progression.nebulaEarned,
            BigNumber.fromInt(challenge.rewardNebula * 2),
            reason: challenge.id,
          );
          expect(
            result.systems.completedChallenges,
            contains(challenge.id),
            reason: challenge.id,
          );
        }
      }
    });

    test('rejects incomplete, stale, unknown and duplicate claims', () {
      final today = DateTime(2026, 11, 16);
      final challenge = WeeklyChallengeCatalog.forDate(today).first;

      final incomplete = engine.claimWeeklyChallenge(
        progression: ProgressionState.initial,
        systems: LegacySystemsState.initial,
        challengeId: challenge.id,
        today: today,
      );
      expect(incomplete.accepted, isFalse);

      final accepted = engine.claimWeeklyChallenge(
        progression: eligibleProgression,
        systems: LegacySystemsState.initial,
        challengeId: challenge.id,
        today: today,
      );
      expect(accepted.accepted, isTrue);

      final duplicate = engine.claimWeeklyChallenge(
        progression: accepted.progression,
        systems: accepted.systems,
        challengeId: challenge.id,
        today: today,
      );
      expect(duplicate.accepted, isFalse);
      expect(duplicate.progression, accepted.progression);

      final stale = engine.claimWeeklyChallenge(
        progression: eligibleProgression,
        systems: LegacySystemsState.initial,
        challengeId: challenge.id,
        today: today.add(const Duration(days: 7)),
      );
      expect(stale.accepted, isFalse);

      final unknown = engine.claimWeeklyChallenge(
        progression: eligibleProgression,
        systems: LegacySystemsState.initial,
        challengeId: 'weekly_2026_47_unknown',
        today: today,
      );
      expect(unknown.accepted, isFalse);
    });

    test('compares Money progress as BigNumber without integer truncation', () {
      final today = DateTime(2026, 11, 16);
      final moneyChallenge = WeeklyChallengeCatalog.forDate(today).singleWhere(
        (challenge) => challenge.kind == 'money',
      );
      final progression = ProgressionState.initial.copyWith(
        money: BigNumber.parse('10000000.0001'),
      );

      expect(
        engine.weeklyChallengeProgress(progression, 'money'),
        progression.money,
      );
      final result = engine.claimWeeklyChallenge(
        progression: progression,
        systems: LegacySystemsState.initial,
        challengeId: moneyChallenge.id,
        today: today,
      );
      expect(result.accepted, isTrue);
    });
  });
}
