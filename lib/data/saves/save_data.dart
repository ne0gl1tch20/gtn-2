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
  })  : progression = progression ?? ProgressionState.initial,
        settings = settings ?? GameSettings.initial;

  static const currentSchemaVersion = 4;

  final int schemaVersion;
  final int secret;
  final int attempts;
  final int gamesWon;
  final bool isComplete;
  final int minimum;
  final int maximum;
  final ProgressionState progression;
  final GameSettings settings;

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'secret': secret,
        'attempts': attempts,
        'gamesWon': gamesWon,
        'isComplete': isComplete,
        'minimum': minimum,
        'maximum': maximum,
        'progression': progression.toJson(),
        'settings': settings.toJson(),
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
    if (version is! int || (version != 1 && version != 2 && version != 3 && version != currentSchemaVersion) ||
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
        gamesWon < 0) {
      throw const FormatException('Unsupported or invalid save data.');
    }
    final progression = progressionJson == null
        ? ProgressionState.initial
        : progressionJson is Map<String, dynamic>
            ? ProgressionState.fromJson(progressionJson)
            : throw const FormatException('Invalid progression save.');
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
    );
  }
}
