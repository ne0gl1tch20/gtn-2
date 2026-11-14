/// Preview calendar rules ported from GTN1's SeasonalThemeCalendar.kt.
library;

class SeasonalMonthDay {
  const SeasonalMonthDay(this.month, this.day);

  final int month;
  final int day;

  bool get isValid {
    if (month < 1 || month > 12 || day < 1 || day > 31) return false;
    final normalized = DateTime(2000, month, day);
    return normalized.month == month && normalized.day == day;
  }

  bool operator <=(SeasonalMonthDay other) =>
      month < other.month || (month == other.month && day <= other.day);

  @override
  bool operator ==(Object other) =>
      other is SeasonalMonthDay && month == other.month && day == other.day;

  @override
  int get hashCode => Object.hash(month, day);
}

class SeasonalDateWindow {
  SeasonalDateWindow({required this.start, required this.endExclusive}) {
    if (!endExclusive.isAfter(start)) {
      throw ArgumentError(
        'Seasonal date window must have a positive duration.',
      );
    }
  }

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && day.isBefore(endExclusive);
  }
}

class SeasonalThemeCalendarConfig {
  SeasonalThemeCalendarConfig({
    this.regionCode = 'PH',
    this.backToSchoolStart = const SeasonalMonthDay(6, 1),
    this.backToSchoolEndExclusive = const SeasonalMonthDay(7, 1),
    this.winterEnabled = false,
    this.winterStart = const SeasonalMonthDay(12, 1),
    this.winterEndExclusive = const SeasonalMonthDay(3, 1),
    Map<int, SeasonalDateWindow>? lunarNewYearWindows,
  }) : lunarNewYearWindows = Map.unmodifiable(
         lunarNewYearWindows ?? SeasonalThemeCalendar.lunarNewYearWindows,
       ) {
    if (!RegExp(r'^[A-Za-z0-9_-]{2,16}$').hasMatch(regionCode)) {
      throw ArgumentError.value(
        regionCode,
        'regionCode',
        'Region code is invalid.',
      );
    }
    if (!backToSchoolStart.isValid ||
        !backToSchoolEndExclusive.isValid ||
        backToSchoolStart == backToSchoolEndExclusive) {
      throw ArgumentError(
        'Back-to-school window must have a positive duration.',
      );
    }
    if (!winterStart.isValid ||
        !winterEndExclusive.isValid ||
        winterStart == winterEndExclusive) {
      throw ArgumentError('Winter window must have a positive duration.');
    }
  }

  final String regionCode;
  final SeasonalMonthDay backToSchoolStart;
  final SeasonalMonthDay backToSchoolEndExclusive;
  final bool winterEnabled;
  final SeasonalMonthDay winterStart;
  final SeasonalMonthDay winterEndExclusive;
  final Map<int, SeasonalDateWindow> lunarNewYearWindows;
}

class ActiveSeasonalTheme {
  const ActiveSeasonalTheme({
    required this.id,
    required this.start,
    required this.endExclusive,
    required this.priority,
  });

  final String id;
  final DateTime start;
  final DateTime endExclusive;
  final int priority;

  bool contains(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return !day.isBefore(start) && day.isBefore(endExclusive);
  }
}

class _RecurringSeasonalWindow {
  const _RecurringSeasonalWindow(
    this.id,
    this.start,
    this.endExclusive,
    this.priority, {
    this.philippinesOnly = false,
  });

  final String id;
  final SeasonalMonthDay start;
  final SeasonalMonthDay endExclusive;
  final int priority;
  final bool philippinesOnly;
}

class SeasonalThemeCalendar {
  SeasonalThemeCalendar._();

  static final Map<int, SeasonalDateWindow> lunarNewYearWindows =
      Map.unmodifiable({
        for (final entry in const <int, (int, int)>{
          2026: (2, 17),
          2027: (2, 6),
          2028: (1, 26),
          2029: (2, 13),
          2030: (2, 3),
          2031: (1, 23),
          2032: (2, 11),
          2033: (1, 31),
          2034: (2, 19),
          2035: (2, 8),
        }.entries)
          entry.key: SeasonalDateWindow(
            start: DateTime(entry.key, entry.value.$1, entry.value.$2),
            endExclusive: DateTime(
              entry.key,
              entry.value.$1,
              entry.value.$2,
            ).add(const Duration(days: 15)),
          ),
      });

  static const List<_RecurringSeasonalWindow> _recurring = [
    _RecurringSeasonalWindow(
      'new_year',
      SeasonalMonthDay(12, 26),
      SeasonalMonthDay(1, 8),
      110,
    ),
    _RecurringSeasonalWindow(
      'christmas',
      SeasonalMonthDay(12, 1),
      SeasonalMonthDay(1, 7),
      100,
    ),
    _RecurringSeasonalWindow(
      'halloween',
      SeasonalMonthDay(10, 15),
      SeasonalMonthDay(11, 2),
      90,
    ),
    _RecurringSeasonalWindow(
      'valentines',
      SeasonalMonthDay(2, 7),
      SeasonalMonthDay(2, 16),
      70,
    ),
    _RecurringSeasonalWindow(
      'philippine_summer',
      SeasonalMonthDay(3, 1),
      SeasonalMonthDay(6, 1),
      50,
      philippinesOnly: true,
    ),
    _RecurringSeasonalWindow(
      'philippine_independence_day',
      SeasonalMonthDay(6, 12),
      SeasonalMonthDay(6, 13),
      80,
      philippinesOnly: true,
    ),
  ];

  static List<ActiveSeasonalTheme> activeThemes(
    DateTime date, [
    SeasonalThemeCalendarConfig? config,
  ]) {
    final settings = config ?? SeasonalThemeCalendarConfig();
    final day = DateTime(date.year, date.month, date.day);
    final isPhilippines = settings.regionCode.toUpperCase() == 'PH';
    final active = <ActiveSeasonalTheme>[];

    for (final rule in _recurring) {
      if (rule.philippinesOnly && !isPhilippines) continue;
      final theme = _recurringForDate(rule, day);
      if (theme != null) active.add(theme);
    }

    if (isPhilippines) {
      final rule = _RecurringSeasonalWindow(
        'back_to_school',
        settings.backToSchoolStart,
        settings.backToSchoolEndExclusive,
        60,
        philippinesOnly: true,
      );
      final theme = _recurringForDate(rule, day);
      if (theme != null) active.add(theme);
    }

    final lunar = settings.lunarNewYearWindows[day.year];
    if (lunar != null && lunar.contains(day)) {
      active.add(
        ActiveSeasonalTheme(
          id: 'lunar_new_year',
          start: lunar.start,
          endExclusive: lunar.endExclusive,
          priority: 85,
        ),
      );
    }

    final easter = _easterWindow(day.year);
    if (easter.contains(day)) {
      active.add(
        ActiveSeasonalTheme(
          id: 'easter',
          start: easter.start,
          endExclusive: easter.endExclusive,
          priority: 95,
        ),
      );
    }

    if (settings.winterEnabled) {
      final rule = _RecurringSeasonalWindow(
        'winter',
        settings.winterStart,
        settings.winterEndExclusive,
        40,
      );
      final theme = _recurringForDate(rule, day);
      if (theme != null) active.add(theme);
    }

    final unique =
        <String, ActiveSeasonalTheme>{
          for (final theme in active) theme.id: theme,
        }.values.toList()..sort((a, b) {
          final priority = b.priority.compareTo(a.priority);
          return priority != 0 ? priority : a.id.compareTo(b.id);
        });
    return List.unmodifiable(unique);
  }

  static ActiveSeasonalTheme? primaryTheme(
    DateTime date, [
    SeasonalThemeCalendarConfig? config,
  ]) {
    final themes = activeThemes(date, config);
    return themes.isEmpty ? null : themes.first;
  }

  static ActiveSeasonalTheme? _recurringForDate(
    _RecurringSeasonalWindow rule,
    DateTime date,
  ) {
    for (var year = date.year - 1; year <= date.year; year++) {
      final start = DateTime(year, rule.start.month, rule.start.day);
      final crossesYear = !(rule.start <= rule.endExclusive);
      final end = DateTime(
        crossesYear ? year + 1 : year,
        rule.endExclusive.month,
        rule.endExclusive.day,
      );
      if (!date.isBefore(start) && date.isBefore(end)) {
        return ActiveSeasonalTheme(
          id: rule.id,
          start: start,
          endExclusive: end,
          priority: rule.priority,
        );
      }
    }
    return null;
  }

  static SeasonalDateWindow _easterWindow(int year) {
    final sunday = _gregorianEasterSunday(year);
    return SeasonalDateWindow(
      start: sunday.subtract(const Duration(days: 2)),
      endExclusive: sunday.add(const Duration(days: 1)),
    );
  }

  static DateTime _gregorianEasterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }
}
