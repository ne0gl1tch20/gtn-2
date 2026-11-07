class SaveData {
  const SaveData({
    this.schemaVersion = currentSchemaVersion,
    required this.secret,
    required this.attempts,
    required this.gamesWon,
  });

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final int secret;
  final int attempts;
  final int gamesWon;

  Map<String, Object> toJson() => {
        'schemaVersion': schemaVersion,
        'secret': secret,
        'attempts': attempts,
        'gamesWon': gamesWon,
      };

  factory SaveData.fromJson(Map<String, dynamic> json) {
    final version = json['schemaVersion'];
    final secret = json['secret'];
    final attempts = json['attempts'];
    final gamesWon = json['gamesWon'];
    if (version != currentSchemaVersion ||
        secret is! int ||
        attempts is! int ||
        gamesWon is! int ||
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
    );
  }
}
