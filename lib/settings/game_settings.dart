class GameSettings {
  const GameSettings({this.darkMode = true, this.reduceMotion = false, this.localeCode = 'en_us', this.difficultyId = 'classic'});

  static const initial = GameSettings();

  final bool darkMode;
  final bool reduceMotion;
  final String localeCode;
  final String difficultyId;

  GameSettings copyWith({bool? darkMode, bool? reduceMotion, String? localeCode, String? difficultyId}) => GameSettings(
        darkMode: darkMode ?? this.darkMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        localeCode: localeCode ?? this.localeCode,
        difficultyId: difficultyId ?? this.difficultyId,
      );

  Map<String, Object> toJson() => {
        'darkMode': darkMode,
        'reduceMotion': reduceMotion,
        'localeCode': localeCode,
        'difficultyId': difficultyId,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    final darkMode = json['darkMode'];
    final reduceMotion = json['reduceMotion'];
    final localeCode = json['localeCode'] ?? 'en_us';
    final difficultyId = json['difficultyId'] ?? 'classic';
    if (darkMode is! bool || reduceMotion is! bool || localeCode is! String ||
        difficultyId is! String || !const ['classic', 'hard', 'extreme'].contains(difficultyId)) {
      throw const FormatException('Invalid game settings.');
    }
    return GameSettings(darkMode: darkMode, reduceMotion: reduceMotion, localeCode: localeCode, difficultyId: difficultyId);
  }
}
