import 'dart:convert';

import '../../core/creative/creative_mode.dart';
import '../../core/progression/progression_state.dart';
import '../../settings/game_settings.dart';

class SaveData {
  SaveData({
    this.schemaVersion = currentSchemaVersion,
    required this.secret,
    required this.attempts,
    this.correctGuesses = 0,
    this.streak = 0,
    this.bestStreak = 0,
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

  static const currentSchemaVersion = 7;
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
  final int correctGuesses;
  final int streak;
  final int bestStreak;
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
    int? correctGuesses,
    int? streak,
    int? bestStreak,
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
    correctGuesses: correctGuesses ?? this.correctGuesses,
    streak: streak ?? this.streak,
    bestStreak: bestStreak ?? this.bestStreak,
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
    'correctGuesses': correctGuesses,
    'streak': streak,
    'bestStreak': bestStreak,
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
    final legacyProgression = json['progression'];
    final correctGuesses =
        json['correctGuesses'] ??
        (legacyProgression is Map<String, dynamic>
            ? legacyProgression['correctGuesses'] ?? 0
            : 0);
    final streak =
        json['streak'] ??
        (legacyProgression is Map<String, dynamic>
            ? legacyProgression['currentStreak'] ?? 0
            : 0);
    final bestStreak =
        json['bestStreak'] ??
        (legacyProgression is Map<String, dynamic>
            ? legacyProgression['bestStreak'] ?? 0
            : 0);
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
        correctGuesses is! int ||
        streak is! int ||
        bestStreak is! int ||
        gamesWon is! int ||
        isComplete is! bool ||
        minimum is! int ||
        maximum is! int ||
        creativeModeEnabled is! bool ||
        minimum < 1 ||
        maximum > (creativeModeEnabled ? 1000000 : 500) ||
        minimum > maximum ||
        secret < minimum ||
        secret > maximum ||
        attempts < 0 ||
        correctGuesses < 0 ||
        correctGuesses > attempts ||
        streak < 0 ||
        streak > 1000000 ||
        bestStreak < streak ||
        bestStreak > 1000000 ||
        gamesWon < 0 ||
        profileName is! String ||
        profileName.length > 24 ||
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
      correctGuesses: correctGuesses,
      streak: streak,
      bestStreak: bestStreak,
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
