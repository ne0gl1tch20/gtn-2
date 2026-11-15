import 'dart:convert';

import '../../core/creative/creative_mode.dart';
import '../../settings/game_settings.dart';
import 'legacy_gtn1_save_adapter.dart';
import 'save_data.dart';

/// The exact GTN1 EncryptedBackupBundle v2/v3 JSON contract.
class LegacyGtn1BackupBundle {
  const LegacyGtn1BackupBundle({
    required this.formatVersion,
    required this.appPreferences,
    required this.activeSlot,
    required this.slots,
    required this.backups,
    required this.creativeSlots,
  });

  final int formatVersion;
  final GameSettings appPreferences;
  final int activeSlot;
  final Map<int, SaveData> slots;
  final Map<int, SaveData> backups;
  final Map<int, CreativeModeSave> creativeSlots;

  static const maxSlots = 10;

  static LegacyGtn1BackupBundle decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('GTN1 backup bundle root must be an object.');
    }
    final version = decoded['formatVersion'] ?? 3;
    final active = decoded['activeSlot'];
    final preferences = decoded['appPreferencesJson'];
    if (version is! int || version < 2 || version > 3 ||
        active is! int || preferences is! String) {
      throw const FormatException('Unsupported GTN1 backup bundle header.');
    }

    final settings = LegacyGtn1SaveAdapter.decodeGameSettingsJson(preferences);
    final slots = _decodeSaveMap(decoded['slots'], 'slots', settings);
    final backups = _decodeSaveMap(decoded['backups'], 'backups', settings);
    final creative = _decodeCreativeMap(decoded['creativeSlots']);


    return LegacyGtn1BackupBundle(
      formatVersion: version,
      appPreferences: settings,
      activeSlot: active.clamp(1, maxSlots).toInt(),
      slots: Map.unmodifiable(slots),
      backups: Map.unmodifiable(backups),
      creativeSlots: Map.unmodifiable(creative),
    );
  }

  String encode() {
    final slotJson = <String, String>{};
    for (final entry in slots.entries) {
      if (entry.key < 1 || entry.key > maxSlots) {
        throw const FormatException('Invalid GTN2 save slot index.');
      }
      slotJson['${entry.key}'] =
          jsonEncode(LegacyGtn1SaveAdapter.toGameStateJson(entry.value.copyWith(settings: appPreferences)));
    }
    final backupJson = <String, String>{};
    for (final entry in backups.entries) {
      if (entry.key < 1 || entry.key > maxSlots) {
        throw const FormatException('Invalid GTN2 backup slot index.');
      }
      backupJson['${entry.key}'] =
          jsonEncode(LegacyGtn1SaveAdapter.toGameStateJson(entry.value.copyWith(settings: appPreferences)));
    }
    final creativeJson = <String, String>{};
    for (final entry in slots.entries) {
      final creative = entry.value.creativeMode;
      if (creative != null) {
        creativeJson['${entry.key}'] = CreativeModeSave.encode(creative);
      }
    }
    for (final entry in creativeSlots.entries) {
      creativeJson['${entry.key}'] = CreativeModeSave.encode(entry.value);
    }
    return jsonEncode({
      'formatVersion': 3,
      'appPreferencesJson':
          jsonEncode(LegacyGtn1SaveAdapter.toGameSettingsJson(appPreferences)),
      'activeSlot': activeSlot.clamp(1, maxSlots).toInt(),
      'slots': slotJson,
      'backups': backupJson,
      'creativeSlots': creativeJson,
    });
  }

  static Map<int, SaveData> _decodeSaveMap(
    Object? raw,
    String label,
    GameSettings settings,
  ) {
    if (raw == null) return {};
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw FormatException('Invalid GTN1 $label map.');
    }
    final result = <int, SaveData>{};
    for (final entry in raw.entries) {
      final slot = int.tryParse(entry.key as String);
      final value = entry.value;
      if (slot == null || slot < 1 || slot > maxSlots || value is! String) {
        throw FormatException('Invalid GTN1 $label entry.');
      }
      final decoded = LegacyGtn1SaveAdapter.decodeGameState(value);
      final systems = decoded.progression.legacySystems.copyWith(
        musicLibrary: settings.musicLibraryPaths,
        musicQueue: settings.musicQueuePaths,
        musicPlaylists: settings.musicPlaylistPaths,
        musicRepeatMode: settings.musicRepeatMode,
        musicShuffle: settings.musicShuffle,
        currentTrackId: settings.backgroundMusicPath,
        clearCurrentTrack: settings.backgroundMusicPath == null,
      );
      final save = decoded.copyWith(
        settings: settings,
        progression: decoded.progression.copyWith(legacySystems: systems),
      );
      SaveData.fromJson(save.toJson());
      result[slot] = save;
    }
    return result;
  }

  static Map<int, CreativeModeSave> _decodeCreativeMap(Object? raw) {
    if (raw == null) return {};
    if (raw is! Map || raw.keys.any((key) => key is! String)) {
      throw const FormatException('Invalid GTN1 Creative Mode slot map.');
    }
    final result = <int, CreativeModeSave>{};
    for (final entry in raw.entries) {
      final slot = int.tryParse(entry.key as String);
      if (slot == null || slot < 1 || slot > maxSlots || entry.value is! String) {
        throw const FormatException('Invalid GTN1 Creative Mode slot entry.');
      }
      final decoded = CreativeModeSave.decodeAndMigrate(entry.value as String);
      if (decoded == null) {
        throw const FormatException('Invalid GTN1 Creative Mode save.');
      }
      result[slot] = decoded;
    }
    return result;
  }
}
