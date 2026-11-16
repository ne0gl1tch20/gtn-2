/// Rotating weekly challenges ported from GTN1's MutatorsScreen.kt and
/// DesktopMutatorsContent.kt. IDs are scoped to the ISO week-year.
class WeeklyChallengeDefinition {
  const WeeklyChallengeDefinition({
    required this.id,
    required this.kind,
    required this.target,
    required this.rewardNebula,
  });

  final String id;
  final String kind;
  final int target;
  final int rewardNebula;
}

class _WeeklyChallengeTemplate {
  const _WeeklyChallengeTemplate(this.kind, this.target, this.rewardNebula);

  final String kind;
  final int target;
  final int rewardNebula;
}

class WeeklyChallengeCatalog {
  WeeklyChallengeCatalog._();

  static const _pool = <_WeeklyChallengeTemplate>[
    _WeeklyChallengeTemplate('correct', 75, 75),
    _WeeklyChallengeTemplate('streak', 15, 90),
    _WeeklyChallengeTemplate('money', 10000000, 100),
    _WeeklyChallengeTemplate('guesses', 250, 80),
    _WeeklyChallengeTemplate('prestige', 2, 125),
    _WeeklyChallengeTemplate('ultra', 1, 175),
    _WeeklyChallengeTemplate('frenzy', 25, 110),
    _WeeklyChallengeTemplate('playtime', 3600, 95),
  ];

  /// Returns the ISO week-based year and week number for a local calendar date.
  ///
  /// The date is normalized to UTC using its calendar components so DST
  /// transitions cannot shift a week boundary.
  static ({int year, int week}) isoWeek(DateTime date) {
    final day = DateTime.utc(date.year, date.month, date.day);
    final monday = day.subtract(Duration(days: day.weekday - 1));
    final thursday = monday.add(const Duration(days: 3));
    final weekYear = thursday.year;
    final januaryFourth = DateTime.utc(weekYear, 1, 4);
    final firstMonday = januaryFourth.subtract(
      Duration(days: januaryFourth.weekday - 1),
    );
    final week = monday.difference(firstMonday).inDays ~/ 7 + 1;
    return (year: weekYear, week: week);
  }

  /// Returns the same three deterministic challenges used by GTN1 this week.
  static List<WeeklyChallengeDefinition> forDate(DateTime date) {
    final calendarWeek = isoWeek(date);
    final offset = (calendarWeek.week - 1) % _pool.length;
    return List.unmodifiable(
      List.generate(3, (index) {
        final template = _pool[(offset + index * 2) % _pool.length];
        return WeeklyChallengeDefinition(
          id: 'weekly_${calendarWeek.year}_${calendarWeek.week}_${template.kind}',
          kind: template.kind,
          target: template.target,
          rewardNebula: template.rewardNebula,
        );
      }),
    );
  }
}
