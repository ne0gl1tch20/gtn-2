import 'dart:convert';

import '../../core/creative/creative_mode.dart';
import '../../core/progression/progression_state.dart';
import '../../settings/game_settings.dart';

class SaveData {
  SaveData({
    this.schemaVersion = currentSchemaVersion,
    required this.secret,
    required this.attempts,
    required this.gamesWon,
    this.isComplete = false,
    this.minimum = 1,
    this.maximum = 100,
    ProgressionState? progression,
    GameSettings? settings,
    this.profileName = '',
    this.profileIconId = 'default',
    this.creativeModeEnabled = false,
    this.creativeMode,
  }) : progression = progression ?? ProgressionState.initial,
       settings = settings ?? GameSettings.initial;

  static const currentSchemaVersion = 6;
  static const profileIconIds = <String>[
    'default',
    'star',
    'bolt',
    'crown',
    'planet',
  ];

  final int schemaVersion;
  final int secret;
  final int attempts;
  final int gamesWon;
  final bool isComplete;
  final int minimum;
  final int maximum;
  final ProgressionState progression;
  final GameSettings settings;
  final String profileName;
  final String profileIconId;
  /// Permanently marks this active save as eligible for GTN1-style Creative Save tools.
  /// This is distinct from [creativeMode], which stores an isolated sandbox run.
  final bool creativeModeEnabled;
  final CreativeModeSave? creativeMode;

  SaveData copyWith({
    int? schemaVersion,
    int? secret,
    int? attempts,
    int? gamesWon,
    bool? isComplete,
    int? minimum,
    int? maximum,
    ProgressionState? progression,
    GameSettings? settings,
    String? profileName,
    String? profileIconId,
    bool? creativeModeEnabled,
    CreativeModeSave? creativeMode,
    bool clearCreativeMode = false,
  }) => SaveData(
    schemaVersion: schemaVersion ?? this.schemaVersion,
    secret: secret ?? this.secret,
    attempts: attempts ?? this.attempts,
    gamesWon: gamesWon ?? this.gamesWon,
    isComplete: isComplete ?? this.isComplete,
    minimum: minimum ?? this.minimum,
    maximum: maximum ?? this.maximum,
    progression: progression ?? this.progression,
    settings: settings ?? this.settings,
    profileName: profileName ?? this.profileName,
    profileIconId: profileIconId ?? this.profileIconId,
    creativeModeEnabled: creativeModeEnabled ?? this.creativeModeEnabled,
    creativeMode: clearCreativeMode ? null : creativeMode ?? this.creativeMode,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'secret': secret,
    'attempts': attempts,
    'gamesWon': gamesWon,
    'isComplete': isComplete,
    'minimum': minimum,
    'maximum': maximum,
    'progression': progression.toJson(),
    'settings': settings.toJson(),
    'profileName': profileName,
    'profileIconId': profileIconId,
    'creativeModeEnabled': creativeModeEnabled,
    'creativeMode': creativeMode?.toJson(),
  };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    final secret = json['secret'];
    final attempts = json['attempts'];
    final gamesWon = json['gamesWon'];
    final isComplete = json['isComplete'];
    final minimum = json['minimum'] ?? 1;
    final maximum = json['maximum'] ?? 100;
    final progressionJson = json['progression'];
    final settingsJson = json['settings'];
    final profileName = json['profileName'] ?? '';
    final profileIconId = json['profileIconId'] ?? 'default';
    final creativeModeJson = json['creativeMode'];
    final creativeModeEnabled = json['creativeModeEnabled'] ?? false;
    if (version is! int ||
        version < 1 ||
        version > currentSchemaVersion ||
        secret is! int ||
        attempts is! int ||
        gamesWon is! int ||
        isComplete is! bool ||
        minimum is! int ||
        maximum is! int ||
        minimum < 1 ||
        maximum > 500 ||
        minimum > maximum ||
        secret < minimum ||
        secret > maximum ||
        attempts < 0 ||
        gamesWon < 0 ||
        profileName is! String ||
        profileName.length > 24 ||
        creativeModeEnabled is! bool ||
        profileIconId is! String ||
        !profileIconIds.contains(profileIconId)) {
      throw const FormatException('Unsupported or invalid save data.');
    }
    final progression = progressionJson == null
        ? ProgressionState.initial
        : progressionJson is Map<String, dynamic>
        ? ProgressionState.fromJson(progressionJson)
        : throw const FormatException('Invalid progression save.');
    final creativeMode = creativeModeJson == null
        ? null
        : creativeModeJson is Map<String, dynamic>
        ? CreativeModeSave.decodeAndMigrate(jsonEncode(creativeModeJson))
        : null;
    if (creativeModeJson != null && creativeMode == null) {
      throw const FormatException('Invalid Creative Mode save.');
    }
    final settings = settingsJson == null
        ? GameSettings.initial
        : settingsJson is Map<String, dynamic>
        ? GameSettings.fromJson(settingsJson)
        : throw const FormatException('Invalid settings save.');
    return SaveData(
      schemaVersion: currentSchemaVersion,
      secret: secret,
      attempts: attempts,
      gamesWon: gamesWon,
      isComplete: isComplete,
      minimum: minimum,
      maximum: maximum,
      progression: progression,
      settings: settings,
      profileName: profileName,
      profileIconId: profileIconId,
      creativeModeEnabled: creativeModeEnabled,
      creativeMode: creativeMode,
    );
  }
}
