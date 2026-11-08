import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/data/updates/update_checker.dart';

void main() {
  group('Android signing certificate fingerprints', () {
    test('accepts compact and colon-separated SHA-256 fingerprints', () {
      const compact = '79780effaa1db32f4264394db822a6b85dac33dc387b0f1163e6f0b8ffc94b83';
      const separated = '79:78:0E:FF:AA:1D:B3:2F:42:64:39:4D:B8:22:A6:B8:5D:AC:33:DC:38:7B:0F:11:63:E6:F0:B8:FF:C9:4B:83';
      expect(UpdateChecker.isValidCertificateFingerprint(compact), isTrue);
      expect(UpdateChecker.isValidCertificateFingerprint(separated), isTrue);
      expect(UpdateChecker.normalizeCertificateFingerprint(separated), compact);
    });

    test('rejects malformed and truncated fingerprints', () {
      expect(UpdateChecker.isValidCertificateFingerprint('not-a-fingerprint'), isFalse);
      expect(UpdateChecker.isValidCertificateFingerprint(List.filled(63, 'a').join()), isFalse);
      expect(UpdateChecker.isValidCertificateFingerprint(List.filled(64, 'g').join()), isFalse);
    });
  });

  group('UpdateChecker version comparison', () {
    test('compares numeric version components', () {
      expect(UpdateChecker.compareVersions('2.0.10', '2.0.9'), greaterThan(0));
      expect(UpdateChecker.compareVersions('2.1.0', '2.2.0'), lessThan(0));
      expect(UpdateChecker.compareVersions('2.0.0', '2.0.0'), 0);
    });

    test('detects a newer build when version names match', () {
      expect(UpdateChecker.isCurrent(
        remoteVersionName: '2.0.0', remoteVersionCode: 14, remoteRunNumber: 14,
        installedVersionName: '2.0.0', installedVersionCode: 13, installedRunNumber: 13,
      ), isFalse);
    });

    test('rejects older version codes even with a larger run number', () {
      expect(UpdateChecker.isCurrent(
        remoteVersionName: '2.9.0', remoteVersionCode: 12, remoteRunNumber: 99,
        installedVersionName: '2.0.0', installedVersionCode: 13, installedRunNumber: 13,
      ), isTrue);
    });

    test('version name wins before the run number tie breaker', () {
      expect(UpdateChecker.isCurrent(
        remoteVersionName: '2.1.0', remoteVersionCode: 13, remoteRunNumber: 10,
        installedVersionName: '2.0.0', installedVersionCode: 13, installedRunNumber: 11,
      ), isFalse);
    });
  });
}
