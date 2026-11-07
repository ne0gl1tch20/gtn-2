class GameSettings {
  const GameSettings({this.darkMode = true, this.reduceMotion = false});

  static const initial = GameSettings();

  final bool darkMode;
  final bool reduceMotion;

  GameSettings copyWith({bool? darkMode, bool? reduceMotion}) => GameSettings(
        darkMode: darkMode ?? this.darkMode,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  Map<String, Object> toJson() => {
        'darkMode': darkMode,
        'reduceMotion': reduceMotion,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    final darkMode = json['darkMode'];
    final reduceMotion = json['reduceMotion'];
    if (darkMode is! bool || reduceMotion is! bool) {
      throw const FormatException('Invalid game settings.');
    }
    return GameSettings(darkMode: darkMode, reduceMotion: reduceMotion);
  }
}
