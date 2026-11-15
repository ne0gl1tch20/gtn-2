import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/creative/creative_mode.dart';
import '../../settings/game_settings.dart';
import 'legacy_gtn1_backup_bundle.dart';
import 'legacy_gtn1_save_adapter.dart';
import 'legacy_gtn1_save_codec.dart';
import 'portable_save_backup.dart';
import 'save_data.dart';
import 'save_storage.dart';

class BundleImportResult {
  const BundleImportResult({
    required this.activeSlot,
    required this.importedSlots,
    required this.isFullBundle,
  });

  final int activeSlot;
  final int importedSlots;
  final bool isFullBundle;
}

/// Reads/writes GTN1 v3 bundles and commits all ten GTN2 slots as one
/// rollback-capable filesystem transaction.
class SaveBundleStorage {
  SaveBundleStorage({required this.directory});

  final Directory directory;

  static const _transactionName = '.gtn2-bundle-import-txn';
  static const _preferencesName = 'gtn2-app-preferences.json';

  static Future<SaveBundleStorage> inApplicationDocuments() async =>
      SaveBundleStorage(directory: await getApplicationDocumentsDirectory());

  static Future<void> recoverPendingImport(Directory directory) async {
    final transaction = Directory('${directory.path}/$_transactionName');
    if (!await transaction.exists()) return;
    final committed = File('${transaction.path}/committed');
    if (await committed.exists()) {
      await transaction.delete(recursive: true);
      return;
    }

    final manifestFile = File('${transaction.path}/manifest.json');
    if (!await manifestFile.exists()) {
      await transaction.delete(recursive: true);
      return;
    }
    final decoded = jsonDecode(await manifestFile.readAsString());
    if (decoded is! Map<String, dynamic> || decoded['files'] is! List) {
      throw const FormatException('Cannot recover interrupted save import.');
    }
    final rollback = Directory('${transaction.path}/rollback');
    for (final entry in decoded['files'] as List) {
      if (entry is! Map ||
          entry['name'] is! String ||
          entry['existed'] is! bool) {
        throw const FormatException('Invalid save import recovery manifest.');
      }
      final name = entry['name'] as String;
      if (name.contains('/') || name.contains('\\')) {
        throw const FormatException('Unsafe save import recovery path.');
      }
      final target = File('${directory.path}/$name');
      final backup = File('${rollback.path}/$name');
      if (entry['existed'] == true) {
        if (!await backup.exists()) {
          throw FileSystemException('Missing save rollback copy', backup.path);
        }
        if (await target.exists()) await target.delete();
        await backup.copy(target.path);
      } else if (await target.exists()) {
        await target.delete();
      }
    }
    await transaction.delete(recursive: true);
  }

  static Future<GameSettings?> loadAppPreferences(Directory directory) async {
    final file = File('${directory.path}/$_preferencesName');
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) return null;
      return GameSettings.fromJson(decoded);
    } on FormatException {
      return null;
    }
  }

  static Future<void> saveAppPreferences(
    Directory directory,
    GameSettings settings,
  ) async {
    await directory.create(recursive: true);
    final file = File('${directory.path}/$_preferencesName');
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(settings.toJson()), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<String> exportPortableBackup({
    required int activeSlot,
    required GameSettings appPreferences,
    required String passphrase,
  }) async {
    await recoverPendingImport(directory);
    final slots = <int, SaveData>{};
    final backups = <int, SaveData>{};
    for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++) {
      final storage = SaveStorage(directory: directory, slot: slot);
      final primary = await storage.loadPrimary();
      final backup = await storage.loadBackup();
      if (primary != null) slots[slot] = primary;
      if (backup != null) backups[slot] = backup;
    }
    final bundle = LegacyGtn1BackupBundle(
      formatVersion: 3,
      appPreferences: appPreferences,
      activeSlot: activeSlot,
      slots: slots,
      backups: backups,
      creativeSlots: {
        for (final entry in slots.entries)
          if (entry.value.creativeMode != null)
            entry.key: entry.value.creativeMode!,
      },
    );
    return PortableSaveBackup.encryptGtn1Payload(bundle.encode(), passphrase);
  }

  Future<BundleImportResult?> importBackup({
    required String input,
    required String passphrase,
    required int legacyTargetSlot,
  }) async {
    await recoverPendingImport(directory);
    String? cleartext = await PortableSaveBackup.decryptGtn1Payload(
      input.trim(),
      passphrase,
    );
    var fullBundle = true;
    if (cleartext == null) {
      cleartext = LegacyGtn1SaveCodec.decode(input.trim()) ?? input.trim();
    }

    LegacyGtn1BackupBundle bundle;
    final decoded = jsonDecode(cleartext);
    if (decoded is Map<String, dynamic> &&
        decoded.containsKey('appPreferencesJson') &&
        decoded.containsKey('activeSlot')) {
      bundle = LegacyGtn1BackupBundle.decode(cleartext);
    } else if (decoded is Map<String, dynamic>) {
      fullBundle = false;
      final imported = LegacyGtn1SaveAdapter.fromGameStateJson(decoded);
      final settings = imported.settings;
      final slots = <int, SaveData>{};
      final backups = <int, SaveData>{};
      for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++) {
        final storage = SaveStorage(directory: directory, slot: slot);
        final current = await storage.loadPrimary();
        final backup = await storage.loadBackup();
        if (current != null) slots[slot] = current;
        if (backup != null) backups[slot] = backup;
      }
      final target = legacyTargetSlot.clamp(1, SaveStorage.maxSaveSlots).toInt();
      final existingCreative = slots[target]?.creativeMode;
      slots[target] = imported.copyWith(
        settings: settings,
        creativeMode: imported.creativeMode ?? existingCreative,
      );
      bundle = LegacyGtn1BackupBundle(
        formatVersion: 3,
        appPreferences: settings,
        activeSlot: target,
        slots: slots,
        backups: backups,
        creativeSlots: {
          for (final entry in slots.entries)
            if (entry.value.creativeMode != null)
              entry.key: entry.value.creativeMode!,
        },
      );
    } else {
      throw const FormatException('Import is not a GTN1 save or backup bundle.');
    }

    await _applyBundle(bundle);
    return BundleImportResult(
      activeSlot: bundle.activeSlot,
      importedSlots: bundle.slots.length,
      isFullBundle: fullBundle,
    );
  }

  Future<void> _applyBundle(LegacyGtn1BackupBundle bundle) async {
    await directory.create(recursive: true);
    final transaction = Directory('${directory.path}/$_transactionName');
    if (await transaction.exists()) {
      throw StateError('A save import transaction is already active.');
    }
    final rollback = Directory('${transaction.path}/rollback');
    final staged = Directory('${transaction.path}/staged');
    await rollback.create(recursive: true);
    await staged.create(recursive: true);

    final targets = <String, String?>{};
    for (var slot = 1; slot <= SaveStorage.maxSaveSlots; slot++) {
      final filename = slot == 1
          ? 'gtn2-save.json'
          : 'gtn2-save-slot$slot.json';
      final primary = bundle.slots[slot];
      final backup = bundle.backups[slot];
      targets[filename] = primary == null
          ? null
          : jsonEncode(primary.copyWith(settings: bundle.appPreferences).toJson());
      targets['$filename.bak'] = backup == null
          ? null
          : jsonEncode(backup.copyWith(settings: bundle.appPreferences).toJson());
      targets['$filename.tmp'] = null;
      targets['$filename.restore-tmp'] = null;
    }
    targets['gtn2-active-slot.json'] =
        jsonEncode({'schemaVersion': 1, 'slot': bundle.activeSlot});
    targets['gtn2-active-slot.json.tmp'] = null;
    targets['gtn2-app-preferences.json'] =
        jsonEncode(bundle.appPreferences.toJson());
    targets['gtn2-app-preferences.json.tmp'] = null;

    final manifest = <Map<String, Object>>[];
    try {
      for (final name in targets.keys) {
        final target = File('${directory.path}/$name');
        final existed = await target.exists();
        manifest.add({'name': name, 'existed': existed});
        if (existed) await target.copy('${rollback.path}/$name');
      }
      await File('${transaction.path}/manifest.json').writeAsString(
        jsonEncode({'files': manifest}),
        flush: true,
      );

      for (final entry in targets.entries) {
        final target = File('${directory.path}/${entry.key}');
        if (await target.exists()) await target.delete();
        final content = entry.value;
        if (content != null) {
          final stagedFile = File('${staged.path}/${entry.key}');
          await stagedFile.parent.create(recursive: true);
          await stagedFile.writeAsString(content, flush: true);
          await stagedFile.rename(target.path);
        }
      }
      await File('${transaction.path}/committed').writeAsString('yes', flush: true);
      await transaction.delete(recursive: true);
    } catch (_) {
      await recoverPendingImport(directory);
      rethrow;
    }
  }
}
