import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'save_data.dart';

class SaveStorage {
  SaveStorage({required Directory directory})
      : _file = File('${directory.path}/gtn2-save.json');

  final File _file;

  static Future<SaveStorage> inApplicationDocuments() async {
    final directory = await getApplicationDocumentsDirectory();
    return SaveStorage(directory: directory);
  }

  Future<SaveData?> load() async {
    if (!await _file.exists()) return null;
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Save root must be an object.');
      }
      return SaveData.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> save(SaveData data) async {
    if (data.schemaVersion != SaveData.currentSchemaVersion ||
        data.secret < 1 ||
        data.secret > 100 ||
        data.attempts < 0 ||
        data.gamesWon < 0) {
      throw ArgumentError('Refusing to write invalid save data.');
    }

    await _file.parent.create(recursive: true);
    final temporary = File('${_file.path}.tmp');
    final backup = File('${_file.path}.bak');
    await temporary.writeAsString(jsonEncode(data.toJson()), flush: true);

    var backedUp = false;
    try {
      if (await _file.exists()) {
        if (await backup.exists()) await backup.delete();
        await _file.rename(backup.path);
        backedUp = true;
      }
      await temporary.rename(_file.path);
      if (backedUp && await backup.exists()) await backup.delete();
    } on FileSystemException {
      if (backedUp && !await _file.exists() && await backup.exists()) {
        await backup.rename(_file.path);
      }
      rethrow;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }
}
