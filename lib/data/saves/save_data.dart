import '../../core/progression/progression_state.dart';

class SaveData {
  SaveData({
    this.schemaVersion = currentSchemaVersion,
    required this.secret,
    required this.attempts,
    required this.gamesWon,
    this.isComplete = false,
    ProgressionState? progression,
  }) : progression = progression ?? ProgressionState.initial;

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final int secret;
  final int attempts;
  final int gamesWon;
  final bool isComplete;
  final ProgressionState progression;

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'secret': secret,
        'attempts': attempts,
        'gamesWon': gamesWon,
        'isComplete': isComplete,
        'progression': progression.toJson(),
      };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    final secret = json['secret'];
    final attempts = json['attempts'];
    final gamesWon = json['gamesWon'];
    final isComplete = json['isComplete'];
    final progressionJson = json['progression'];
    if (version != currentSchemaVersion ||
        secret is! int ||
        attempts is! int ||
        gamesWon is! int ||
        isComplete is! bool ||
        secret < 1 ||
        secret > 100 ||
        attempts < 0 ||
        gamesWon < 0) {
      throw const FormatException('Unsupported or invalid save data.');
    }
    final progression = progressionJson == null
        ? ProgressionState.initial
        : progressionJson is Map<String, dynamic>
            ? ProgressionState.fromJson(progressionJson)
            : throw const FormatException('Invalid progression save.');
    return SaveData(
      schemaVersion: version as int,
      secret: secret,
      attempts: attempts,
      gamesWon: gamesWon,
      isComplete: isComplete,
      progression: progression,
    );
  }
}
