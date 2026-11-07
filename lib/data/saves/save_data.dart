class SaveData {
  const SaveData({
    this.schemaVersion = currentSchemaVersion,
    required this.secret,
    required this.attempts,
    required this.gamesWon,
    this.isComplete = false,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final int secret;
  final int attempts;
  final int gamesWon;
  final bool isComplete;

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'secret': secret,
        'attempts': attempts,
        'gamesWon': gamesWon,
        'isComplete': isComplete,
      };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    final secret = json['secret'];
    final attempts = json['attempts'];
    final gamesWon = json['gamesWon'];
    final isComplete = json['isComplete'];
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
    return SaveData(
      schemaVersion: version as int,
      secret: secret,
      attempts: attempts,
      gamesWon: gamesWon,
      isComplete: isComplete,
    );
  }
}
