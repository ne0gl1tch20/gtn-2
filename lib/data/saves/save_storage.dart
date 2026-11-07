import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'save_data.dart';

class SaveStorage {
  SaveStorage({required Directory directory, int slot = 1})
      : assert(slot >= 1 && slot <= 5),
        slot = slot,
        _file = File(slot == 1 ? '${directory.path}/gtn2-save.json' : '${directory.path}/gtn2-save-slot$slot.json');

  final int slot;
  final File _file;
  Future<void> _pendingWrite = Future<void>.value();

  static Future<SaveStorage> inApplicationDocuments({int slot = 1}) async {
    final directory = await getApplicationDocumentsDirectory();
    return SaveStorage(directory: directory, slot: slot);
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

  Future<void> save(SaveData data) {
    if (data.schemaVersion != SaveData.currentSchemaVersion ||
        data.secret < 1 ||
        data.secret > 100 ||
        data.attempts < 0 ||
        data.gamesWon < 0) {
      return Future<void>.error(
        ArgumentError('Refusing to write invalid save data.'),
      );
    }

    // Serialize writes so rapid input cannot race on the same temporary file.
    _pendingWrite = _pendingWrite
        .catchError((Object _) {})
        .then((_) => _write(data));
    return _pendingWrite;
  }

  Future<void> _write(SaveData data) async {
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
