import 'dart:convert';
import 'dart:io';

/// Mirrors GTN1's update interval choices and last-check throttling.
class UpdateCheckSchedule {
  UpdateCheckSchedule._();

  static const supportedIntervals = {0, 1, 6, 12, 24, 168};
  static const stateFileName = 'gtn2-update-check-state.json';

  static bool shouldCheck({
    required int intervalHours,
    required DateTime now,
    DateTime? lastCheckedAt,
  }) {
    if (!supportedIntervals.contains(intervalHours) || intervalHours == 0) {
      return false;
    }
    if (lastCheckedAt == null) return true;
    return now.difference(lastCheckedAt) >= Duration(hours: intervalHours);
  }

  static Future<DateTime?> loadLastChecked(Directory directory) async {
    final file = File('${directory.path}/$stateFileName');
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic> ||
          decoded['lastCheckedAt'] is! String) {
        return null;
      }
      return DateTime.tryParse(decoded['lastCheckedAt'] as String);
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  static Future<void> saveLastChecked(
    Directory directory,
    DateTime checkedAt,
  ) async {
    await directory.create(recursive: true);
    final file = File('${directory.path}/$stateFileName');
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
      jsonEncode({'lastCheckedAt': checkedAt.toUtc().toIso8601String()}),
      flush: true,
    );
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }
}
