import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/seasonal/seasonal_theme_calendar.dart';

void main() {
  group('GTN1 seasonal theme calendar parity', () {
    test('New Year and Christmas windows cross the year boundary', () {
      expect(
        SeasonalThemeCalendar.primaryTheme(DateTime(2026, 12, 26))?.id,
        'new_year',
      );
      expect(
        SeasonalThemeCalendar.primaryTheme(DateTime(2027, 1, 7))?.id,
        'new_year',
      );
      expect(SeasonalThemeCalendar.primaryTheme(DateTime(2027, 1, 8)), isNull);
      expect(
        SeasonalThemeCalendar.primaryTheme(DateTime(2026, 12, 1))?.id,
        'christmas',
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 1, 6))
            .any((theme) => theme.id == 'christmas'),
        isTrue,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 1, 7))
            .any((theme) => theme.id == 'christmas'),
        isFalse,
      );
    });

    test('fixed recurring windows include start and exclude end', () {
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 2, 7))
            .any((theme) => theme.id == 'valentines'),
        isTrue,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 2, 15))
            .any((theme) => theme.id == 'valentines'),
        isTrue,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 2, 16))
            .any((theme) => theme.id == 'valentines'),
        isFalse,
      );
      expect(
        SeasonalThemeCalendar.primaryTheme(DateTime(2027, 10, 15))?.id,
        'halloween',
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 11, 1))
            .any((theme) => theme.id == 'halloween'),
        isTrue,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 11, 2))
            .any((theme) => theme.id == 'halloween'),
        isFalse,
      );
    });

    test('Philippines-only themes stay region-scoped', () {
      final date = DateTime(2027, 6, 12);
      expect(
        SeasonalThemeCalendar.activeThemes(date)
            .any((theme) => theme.id == 'philippine_independence_day'),
        isTrue,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(
          date,
          SeasonalThemeCalendarConfig(regionCode: 'US'),
        ).any(
          (theme) =>
              theme.id.startsWith('philippine_') ||
              theme.id == 'back_to_school',
        ),
        isFalse,
      );
    });

    test('Philippine summer ends before the school window begins', () {
      final active = SeasonalThemeCalendar.activeThemes(DateTime(2027, 6, 15));
      expect(active.any((theme) => theme.id == 'back_to_school'), isTrue);
      expect(active.any((theme) => theme.id == 'philippine_summer'), isFalse);
    });

    test('Lunar New Year windows cover the fifteen-day inclusive event', () {
      expect(
        SeasonalThemeCalendar.primaryTheme(DateTime(2027, 2, 6))?.id,
        'lunar_new_year',
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 2, 20))
            .any((theme) => theme.id == 'lunar_new_year'),
        isTrue,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 2, 21))
            .any((theme) => theme.id == 'lunar_new_year'),
        isFalse,
      );
      expect(
        SeasonalThemeCalendar.primaryTheme(DateTime(2028, 1, 26))?.id,
        'lunar_new_year',
      );
    });

    test('custom Lunar New Year window uses exclusive end', () {
      final config = SeasonalThemeCalendarConfig(
        lunarNewYearWindows: {
          2027: SeasonalDateWindow(
            start: DateTime(2027, 2, 5),
            endExclusive: DateTime(2027, 2, 8),
          ),
        },
      );
      expect(
        SeasonalThemeCalendar.primaryTheme(DateTime(2027, 2, 6), config)?.id,
        'lunar_new_year',
      );
      expect(
        SeasonalThemeCalendar.activeThemes(
          DateTime(2027, 2, 8),
          config,
        ).any((theme) => theme.id == 'lunar_new_year'),
        isFalse,
      );
    });

    test('Easter includes Good Friday through Easter Sunday only', () {
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 3, 26))
            .any((theme) => theme.id == 'easter'),
        isTrue,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 3, 28))
            .any((theme) => theme.id == 'easter'),
        isTrue,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(DateTime(2027, 3, 29))
            .any((theme) => theme.id == 'easter'),
        isFalse,
      );
    });

    test('winter is opt-in and can cross the year boundary', () {
      final date = DateTime(2027, 1, 15);
      expect(
        SeasonalThemeCalendar.activeThemes(date)
            .any((theme) => theme.id == 'winter'),
        isFalse,
      );
      expect(
        SeasonalThemeCalendar.activeThemes(
          date,
          SeasonalThemeCalendarConfig(regionCode: 'US', winterEnabled: true),
        ).any((theme) => theme.id == 'winter'),
        isTrue,
      );
    });

    test('invalid configuration and date windows are rejected', () {
      expect(
        () => SeasonalThemeCalendarConfig(regionCode: 'P'),
        throwsArgumentError,
      );
      expect(
        () => SeasonalThemeCalendarConfig(
          backToSchoolStart: SeasonalMonthDay(6, 1),
          backToSchoolEndExclusive: SeasonalMonthDay(6, 1),
        ),
        throwsArgumentError,
      );
      expect(
        () => SeasonalDateWindow(
          start: DateTime(2027, 2, 8),
          endExclusive: DateTime(2027, 2, 8),
        ),
        throwsArgumentError,
      );
    });
  });
}
