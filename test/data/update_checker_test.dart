import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/updates/update_checker.dart';

void main() {
  group('UpdateChecker version comparison', () {
    test('compares numeric version components', () {
      expect(UpdateChecker.compareVersions('2.0.10', '2.0.9'), greaterThan(0));
      expect(UpdateChecker.compareVersions('2.1.0', '2.2.0'), lessThan(0));
      expect(UpdateChecker.compareVersions('2.0.0', '2.0.0'), 0);
    });

    test('detects a newer build when version names match', () {
      expect(
        UpdateChecker.isCurrent(
          remoteVersionName: '2.0.0',
          remoteVersionCode: 14,
          remoteRunNumber: 14,
          installedVersionName: '2.0.0',
          installedVersionCode: 13,
          installedRunNumber: 13,
        ),
        isFalse,
      );
    });

    test('rejects older version codes even with a larger run number', () {
      expect(
        UpdateChecker.isCurrent(
          remoteVersionName: '2.9.0',
          remoteVersionCode: 12,
          remoteRunNumber: 99,
          installedVersionName: '2.0.0',
          installedVersionCode: 13,
          installedRunNumber: 13,
        ),
        isTrue,
      );
    });

    test('version name wins before the run number tie breaker', () {
      expect(
        UpdateChecker.isCurrent(
          remoteVersionName: '2.1.0',
          remoteVersionCode: 13,
          remoteRunNumber: 10,
          installedVersionName: '2.0.0',
          installedVersionCode: 13,
          installedRunNumber: 11,
        ),
        isFalse,
      );
    });
  });
}
