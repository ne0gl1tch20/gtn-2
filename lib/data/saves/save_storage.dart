import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'save_data.dart';

class SaveStorage {
  SaveStorage({required Directory directory, int slot = 1})
      : slot = slot,
        _file = File(slot == 1 ? '${directory.path}/gtn2-save.json' : '${directory.path}/gtn2-save-slot$slot.json') {
    if (slot < 1 || slot > maxSaveSlots) {
      throw RangeError.range(slot, 1, maxSaveSlots, 'slot');
    }
  }

  static const int maxSaveSlots = 10;

  final int slot;
  final File _file;
  Future<void> _pendingWrite = Future<void>.value();

  static Future<SaveStorage> inApplicationDocuments({int slot = 1}) async {
    final directory = await getApplicationDocumentsDirectory();
    return SaveStorage(directory: directory, slot: slot);
  }

  Future<int> loadActiveSlot() async {
    final activeFile = File('${_file.parent.path}/gtn2-active-slot.json');
    final temporary = File('${activeFile.path}.tmp');
    final backup = File('${activeFile.path}.bak');
    for (final candidate in [activeFile, temporary, backup]) {
      if (!await candidate.exists()) continue;
      try {
        final decoded = jsonDecode(await candidate.readAsString());
        if (decoded is Map<String, dynamic> &&
            decoded['schemaVersion'] == 1 &&
            decoded['slot'] is int) {
          final value = decoded['slot'] as int;
          if (value >= 1 && value <= maxSaveSlots) {
            if (candidate.path != activeFile.path) {
              await _restoreMetadataFile(candidate, activeFile);
            }
            return value;
          }
        }
      } on FormatException {
        // Try the next recovery candidate.
      }
    }
    return 1;
  }

  Future<void> saveActiveSlot(int value) async {
    if (value < 1 || value > maxSaveSlots) {
      throw RangeError.range(value, 1, maxSaveSlots, 'slot');
    }
    final activeFile = File('${_file.parent.path}/gtn2-active-slot.json');
    final temporary = File('${activeFile.path}.tmp');
    final backup = File('${activeFile.path}.bak');
    await activeFile.parent.create(recursive: true);
    await temporary.writeAsString(
      jsonEncode({'schemaVersion': 1, 'slot': value}),
      flush: true,
    );
    var backedUp = false;
    try {
      if (await activeFile.exists()) {
        if (await backup.exists()) await backup.delete();
        await activeFile.rename(backup.path);
        backedUp = true;
      }
      await temporary.rename(activeFile.path);
      if (backedUp && await backup.exists()) await backup.delete();
    } on FileSystemException {
      if (backedUp && !await activeFile.exists() && await backup.exists()) {
        await backup.rename(activeFile.path);
      }
      rethrow;
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Future<void> _restoreMetadataFile(File candidate, File destination) async {
    if (await destination.exists()) {
      final corrupt = File('${destination.path}.corrupt');
      if (await corrupt.exists()) await corrupt.delete();
      await destination.rename(corrupt.path);
    }
    await candidate.rename(destination.path);
  }

  Future<SaveData?> load() async {
    final primary = await _readSave(_file);
    if (primary != null) return primary;

    // A process can be killed after the old save is moved to .bak but before
    // the flushed .tmp file is renamed into place. Prefer that complete new
    // temporary save, then fall back to the last known-good backup.
    final temporary = File('${_file.path}.tmp');
    final temporarySave = await _readSave(temporary);
    if (temporarySave != null) {
      await _restoreRecoveryFile(temporary);
      return temporarySave;
    }

    final backup = File('${_file.path}.bak');
    final backupSave = await _readSave(backup);
    if (backupSave != null) {
      await _restoreRecoveryFile(backup);
      return backupSave;
    }
    return null;
  }

  Future<bool> hasBackup() async =>
      await _readSave(File('${_file.path}.bak')) != null;

  Future<bool> duplicateTo(int targetSlot) => _enqueue(() async {
    final target = SaveStorage(directory: _file.parent, slot: targetSlot);
    if (targetSlot == slot ||
        await target._file.exists() ||
        await File('${target._file.path}.bak').exists()) {
      return false;
    }
    final current = await _readSave(_file);
    if (current == null) return false;
    await target.save(current);
    final sourceBackup = File('${_file.path}.bak');
    final targetBackup = File('${target._file.path}.bak');
    final previous = await _readSave(sourceBackup);
    if (previous != null) {
      await targetBackup.writeAsString(jsonEncode(previous.toJson()), flush: true);
    }
    return true;
  });

  Future<bool> restoreBackup() => _enqueue(() async {
    final backup = File('${_file.path}.bak');
    final previous = await _readSave(_file);
    final recoverable = await _readSave(backup);
    if (previous == null || recoverable == null) return false;
    final temporary = File('${_file.path}.restore-tmp');
    try {
      await _file.rename(temporary.path);
      await backup.rename(_file.path);
      await temporary.rename(backup.path);
      return true;
    } on FileSystemException {
      if (!await _file.exists() && await temporary.exists()) {
        await temporary.rename(_file.path);
      }
      rethrow;
    }
  });

  Future<void> reset() => _enqueue(() async {
    for (final suffix in ['', '.tmp', '.bak', '.corrupt', '.restore-tmp']) {
      final file = File('${_file.path}$suffix');
      if (await file.exists()) await file.delete();
    }
  });

  Future<SaveData?> _readSave(File file) async {
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Save root must be an object.');
      }
      return SaveData.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  Future<void> _restoreRecoveryFile(File candidate) async {
    if (await _file.exists()) {
      final corrupt = File('${_file.path}.corrupt');
      if (await corrupt.exists()) await corrupt.delete();
      await _file.rename(corrupt.path);
    }
    await candidate.rename(_file.path);
  }

  Future<void> save(SaveData data) {
    if (data.schemaVersion != SaveData.currentSchemaVersion ||
        data.minimum < 1 ||
        data.maximum > 500 ||
        data.minimum > data.maximum ||
        data.secret < data.minimum ||
        data.secret > data.maximum ||
        data.attempts < 0 ||
        data.gamesWon < 0) {
      return Future<void>.error(
        ArgumentError('Refusing to write invalid save data.'),
      );
    }
    return _enqueue(() => _write(data));
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final completer = Completer<T>();
    _pendingWrite = _pendingWrite.catchError((Object _) {}).then((_) async {
      try {
        completer.complete(await operation());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
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
      // Retain the previous valid save for explicit one-step restoration.
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
