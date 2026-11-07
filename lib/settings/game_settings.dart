class GameSettings {
  const GameSettings({this.darkMode = true, this.reduceMotion = false, this.localeCode = 'en_us'});

  static const initial = GameSettings();

  final bool darkMode;
  final bool reduceMotion;
  final String localeCode;

  GameSettings copyWith({bool? darkMode, bool? reduceMotion, String? localeCode}) => GameSettings(
        darkMode: darkMode ?? this.darkMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
        localeCode: localeCode ?? this.localeCode,
      );

  Map<String, Object> toJson() => {
        'darkMode': darkMode,
        'reduceMotion': reduceMotion,
        'localeCode': localeCode,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    final darkMode = json['darkMode'];
    final reduceMotion = json['reduceMotion'];
    final localeCode = json['localeCode'] ?? 'en_us';
    if (darkMode is! bool || reduceMotion is! bool || localeCode is! String) {
      throw const FormatException('Invalid game settings.');
    }
    return GameSettings(darkMode: darkMode, reduceMotion: reduceMotion, localeCode: localeCode);
  }
}
