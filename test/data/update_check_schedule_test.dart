import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/updates/update_check_schedule.dart';

void main() {
  group('UpdateCheckSchedule', () {
    final now = DateTime.utc(2026, 11, 15, 2);

    test('None disables automatic checks', () {
      expect(
        UpdateCheckSchedule.shouldCheck(
          intervalHours: 0,
          now: now,
        ),
        isFalse,
      );
    });

    test('first enabled check is due when no prior check exists', () {
      for (final interval in [1, 6, 12, 24, 168]) {
        expect(
          UpdateCheckSchedule.shouldCheck(
            intervalHours: interval,
            now: now,
          ),
          isTrue,
        );
      }
    });

    test('does not check before the selected interval elapses', () {
      expect(
        UpdateCheckSchedule.shouldCheck(
          intervalHours: 6,
          now: now,
          lastCheckedAt: now.subtract(const Duration(hours: 5, minutes: 59)),
        ),
        isFalse,
      );
    });

    test('checks at the exact interval boundary', () {
      expect(
        UpdateCheckSchedule.shouldCheck(
          intervalHours: 6,
          now: now,
          lastCheckedAt: now.subtract(const Duration(hours: 6)),
        ),
        isTrue,
      );
    });

    test('rejects unsupported interval values', () {
      expect(
        UpdateCheckSchedule.shouldCheck(
          intervalHours: 2,
          now: now,
        ),
        isFalse,
      );
    });

    test('persists the last check timestamp', () async {
      final directory = await Directory.systemTemp.createTemp('gtn-update-');
      addTearDown(() => directory.delete(recursive: true));
      await UpdateCheckSchedule.saveLastChecked(directory, now);

      expect(
        await UpdateCheckSchedule.loadLastChecked(directory),
        now,
      );
    });

    test('ignores corrupt persisted schedule data', () async {
      final directory = await Directory.systemTemp.createTemp('gtn-update-');
      addTearDown(() => directory.delete(recursive: true));
      await File(
        '${directory.path}/${UpdateCheckSchedule.stateFileName}',
      ).writeAsString('{broken');

      expect(await UpdateCheckSchedule.loadLastChecked(directory), isNull);
    });
  });
}
