class GameSettings {
  const GameSettings({
    this.darkMode = true,
    this.reduceMotion = false,
    this.localeCode = 'en_us',
    this.difficultyId = 'classic',
    this.themeMode = 'System',
    this.numberNotation = 'Standard',
    this.musicEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = true,
    this.notificationRemindersEnabled = true,
    this.notificationProgressionEnabled = true,
    this.notificationEventsEnabled = true,
    this.notificationIntervalHours = 24,
    this.volume = 1,
    this.sfxVolume = 1,
    this.reduceFlashes = false,
    this.saveLogsToStorage = false,
    this.verboseLogging = false,
    this.backgroundMusicPath,
    this.musicLibraryPaths = const [],
    this.musicQueuePaths = const [],
    this.musicPlaylistPaths = const {},
    this.musicRepeatMode = 'off',
    this.musicShuffle = false,
    this.themePreset = 'Neon',
    this.customPrimaryColor = '#7C4DFF',
    this.customSecondaryColor = '#00BCD4',
    this.customTertiaryColor = '#00C853',
    this.moreScreenOrder = const [
      'rewards',
      'journey',
      'shop',
      'home_base',
      'relics',
      'codex',
      'changelog',
      'about',
      'save_slots',
      'music',
      'settings',
      'prestige',
      'ultra',
      'talent',
      'traits',
      'mutators',
      'stats',
      'staking',
    ],
    this.moreScreenButtonColors = const {},
    this.webMenuStudioLayout,
    this.tutorialCompleted = false,
    this.tutorialSeenFeatures = const {},
    this.updateCheckIntervalHours = 0,
  });

  static const initial = GameSettings();

  final bool darkMode;
  final bool reduceMotion;
  final String localeCode;
  final String difficultyId;
  final String themeMode;
  final String numberNotation;
  final bool musicEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final bool notificationRemindersEnabled;
  final bool notificationProgressionEnabled;
  final bool notificationEventsEnabled;
  final int notificationIntervalHours;
  final double volume;
  final double sfxVolume;
  final bool reduceFlashes;
  final bool saveLogsToStorage;
  final bool verboseLogging;
  final String? backgroundMusicPath;
  final List<String> musicLibraryPaths;
  final List<String> musicQueuePaths;
  final Map<String, List<String>> musicPlaylistPaths;
  final String musicRepeatMode;
  final bool musicShuffle;
  final String themePreset;
  final String customPrimaryColor;
  final String customSecondaryColor;
  final String customTertiaryColor;
  final List<String> moreScreenOrder;
  final Map<String, String> moreScreenButtonColors;
  final String? webMenuStudioLayout;
  final bool tutorialCompleted;
  final Set<String> tutorialSeenFeatures;
  final int updateCheckIntervalHours;

  GameSettings copyWith({
    bool? darkMode,
    bool? reduceMotion,
    String? localeCode,
    String? difficultyId,
    String? themeMode,
    String? numberNotation,
    bool? musicEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    bool? notificationRemindersEnabled,
    bool? notificationProgressionEnabled,
    bool? notificationEventsEnabled,
    int? notificationIntervalHours,
    double? volume,
    double? sfxVolume,
    bool? reduceFlashes,
    bool? saveLogsToStorage,
    bool? verboseLogging,
    String? backgroundMusicPath,
    bool clearBackgroundMusicPath = false,
    List<String>? musicLibraryPaths,
    List<String>? musicQueuePaths,
    Map<String, List<String>>? musicPlaylistPaths,
    String? musicRepeatMode,
    bool? musicShuffle,
    String? themePreset,
    String? customPrimaryColor,
    String? customSecondaryColor,
    String? customTertiaryColor,
    List<String>? moreScreenOrder,
    Map<String, String>? moreScreenButtonColors,
    String? webMenuStudioLayout,
    bool clearWebMenuStudioLayout = false,
    bool? tutorialCompleted,
    Set<String>? tutorialSeenFeatures,
    int? updateCheckIntervalHours,
  }) => GameSettings(
    darkMode: darkMode ?? this.darkMode,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    localeCode: localeCode ?? this.localeCode,
    difficultyId: difficultyId ?? this.difficultyId,
    themeMode: themeMode ?? this.themeMode,
    numberNotation: numberNotation ?? this.numberNotation,
    musicEnabled: musicEnabled ?? this.musicEnabled,
    soundEnabled: soundEnabled ?? this.soundEnabled,
    vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    notificationRemindersEnabled:
        notificationRemindersEnabled ?? this.notificationRemindersEnabled,
    notificationProgressionEnabled:
        notificationProgressionEnabled ?? this.notificationProgressionEnabled,
    notificationEventsEnabled:
        notificationEventsEnabled ?? this.notificationEventsEnabled,
    notificationIntervalHours:
        notificationIntervalHours ?? this.notificationIntervalHours,
    volume: volume ?? this.volume,
    sfxVolume: sfxVolume ?? this.sfxVolume,
    reduceFlashes: reduceFlashes ?? this.reduceFlashes,
    saveLogsToStorage: saveLogsToStorage ?? this.saveLogsToStorage,
    verboseLogging: verboseLogging ?? this.verboseLogging,
    backgroundMusicPath: clearBackgroundMusicPath
        ? null
        : backgroundMusicPath ?? this.backgroundMusicPath,
    musicLibraryPaths: musicLibraryPaths ?? this.musicLibraryPaths,
    musicQueuePaths: musicQueuePaths ?? this.musicQueuePaths,
    musicPlaylistPaths: musicPlaylistPaths ?? this.musicPlaylistPaths,
    musicRepeatMode: musicRepeatMode ?? this.musicRepeatMode,
    musicShuffle: musicShuffle ?? this.musicShuffle,
    themePreset: themePreset ?? this.themePreset,
    customPrimaryColor: customPrimaryColor ?? this.customPrimaryColor,
    customSecondaryColor: customSecondaryColor ?? this.customSecondaryColor,
    customTertiaryColor: customTertiaryColor ?? this.customTertiaryColor,
    moreScreenOrder: moreScreenOrder ?? this.moreScreenOrder,
    moreScreenButtonColors:
        moreScreenButtonColors ?? this.moreScreenButtonColors,
    webMenuStudioLayout: clearWebMenuStudioLayout
        ? null
        : webMenuStudioLayout ?? this.webMenuStudioLayout,
    tutorialCompleted: tutorialCompleted ?? this.tutorialCompleted,
    tutorialSeenFeatures: tutorialSeenFeatures ?? this.tutorialSeenFeatures,
    updateCheckIntervalHours:
        updateCheckIntervalHours ?? this.updateCheckIntervalHours,
  );

  Map<String, Object?> toJson() => {
    'darkMode': darkMode,
    'reduceMotion': reduceMotion,
    'localeCode': localeCode,
    'difficultyId': difficultyId,
    'themeMode': themeMode,
    'numberNotation': numberNotation,
    'musicEnabled': musicEnabled,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    'notificationsEnabled': notificationsEnabled,
    'notificationRemindersEnabled': notificationRemindersEnabled,
    'notificationProgressionEnabled': notificationProgressionEnabled,
    'notificationEventsEnabled': notificationEventsEnabled,
    'notificationIntervalHours': notificationIntervalHours,
    'volume': volume,
    'sfxVolume': sfxVolume,
    'reduceFlashes': reduceFlashes,
    'saveLogsToStorage': saveLogsToStorage,
    'verboseLogging': verboseLogging,
    'backgroundMusicPath': backgroundMusicPath,
    'musicLibraryPaths': musicLibraryPaths,
    'musicQueuePaths': musicQueuePaths,
    'musicPlaylistPaths': musicPlaylistPaths,
    'musicRepeatMode': musicRepeatMode,
    'musicShuffle': musicShuffle,
    'themePreset': themePreset,
    'customPrimaryColor': customPrimaryColor,
    'customSecondaryColor': customSecondaryColor,
    'customTertiaryColor': customTertiaryColor,
    'moreScreenOrder': moreScreenOrder,
    'moreScreenButtonColors': moreScreenButtonColors,
    'webMenuStudioLayout': webMenuStudioLayout,
    'tutorialCompleted': tutorialCompleted,
    'tutorialSeenFeatures': tutorialSeenFeatures.toList(),
    'updateCheckIntervalHours': updateCheckIntervalHours,
  };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    T read<T>(String key, T fallback) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is! T) throw FormatException('Invalid setting: $key');
      return value;
    }

    List<String> readStrings(String key) {
      final value = json[key];
      if (value == null) return const [];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('Invalid setting: $key');
      }
      return List.unmodifiable(value.cast<String>());
    }

    Map<String, List<String>> readPlaylists() {
      final value = json['musicPlaylistPaths'];
      if (value == null) return const {};
      if (value is! Map) {
        throw const FormatException('Invalid music playlists.');
      }
      final result = <String, List<String>>{};
      for (final entry in value.entries) {
        if (entry.key is! String ||
            entry.value is! List ||
            (entry.value as List).any((item) => item is! String)) {
          throw const FormatException('Invalid music playlist entry.');
        }
        result[entry.key as String] = List.unmodifiable(
          (entry.value as List).cast<String>(),
        );
      }
      return Map.unmodifiable(result);
    }

    Map<String, String> readColors() {
      final value = json['moreScreenButtonColors'];
      if (value == null) return const {};
      if (value is! Map ||
          value.entries.any(
            (entry) => entry.key is! String || entry.value is! String,
          )) {
        throw const FormatException('Invalid More menu button colors.');
      }
      return Map.unmodifiable(value.cast<String, String>());
    }

    final darkMode = read<bool>('darkMode', true);
    final themeMode = read<String>('themeMode', darkMode ? 'Dark' : 'Light');
    final difficulty = read<String>('difficultyId', 'classic');
    final locale = read<String>('localeCode', 'en_us');
    final volume = read<num>('volume', 1).toDouble();
    final sfxVolume = read<num>('sfxVolume', 1).toDouble();
    final notificationInterval = read<int>('notificationIntervalHours', 24);
    final updateInterval = read<int>('updateCheckIntervalHours', 0);
    final repeat = read<String>('musicRepeatMode', 'off');
    final primary = read<String>('customPrimaryColor', '#7C4DFF');
    final secondary = read<String>('customSecondaryColor', '#00BCD4');
    final tertiary = read<String>('customTertiaryColor', '#00C853');
    final colors = [primary, secondary, tertiary];
    if (!const ['classic', 'hard', 'extreme'].contains(difficulty) ||
        !const ['System', 'Dark', 'Light', 'AMOLED'].contains(themeMode) ||
        !const [
          'Standard',
          'Scientific',
          'Engineering',
        ].contains(read<String>('numberNotation', 'Standard')) ||
        !const [12, 24, 48].contains(notificationInterval) ||
        !const [0, 1, 6, 12, 24, 168].contains(updateInterval) ||
        !const ['off', 'one', 'all'].contains(repeat) ||
        volume < 0 ||
        volume > 1 ||
        sfxVolume < 0 ||
        sfxVolume > 1 ||
        colors.any((color) => !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color))) {
      throw const FormatException('Invalid game settings.');
    }

    final tutorialFeatures = readStrings('tutorialSeenFeatures');
    final moreOrder = readStrings('moreScreenOrder');
    final rawMenuLayout = json['webMenuStudioLayout'];
    final rawMusicPath = json['backgroundMusicPath'];
    if (rawMenuLayout != null && rawMenuLayout is! String ||
        rawMusicPath != null && rawMusicPath is! String) {
      throw const FormatException('Invalid optional settings value.');
    }

    return GameSettings(
      darkMode: themeMode == 'System'
          ? darkMode
          : themeMode == 'Dark' || themeMode == 'AMOLED',
      reduceMotion: read<bool>('reduceMotion', false),
      localeCode: locale,
      difficultyId: difficulty,
      themeMode: themeMode,
      numberNotation: read<String>('numberNotation', 'Standard'),
      musicEnabled: read<bool>('musicEnabled', true),
      soundEnabled: read<bool>('soundEnabled', true),
      vibrationEnabled: read<bool>('vibrationEnabled', true),
      notificationsEnabled: read<bool>('notificationsEnabled', true),
      notificationRemindersEnabled: read<bool>(
        'notificationRemindersEnabled',
        true,
      ),
      notificationProgressionEnabled: read<bool>(
        'notificationProgressionEnabled',
        true,
      ),
      notificationEventsEnabled: read<bool>('notificationEventsEnabled', true),
      notificationIntervalHours: notificationInterval,
      volume: volume,
      sfxVolume: sfxVolume,
      reduceFlashes: read<bool>('reduceFlashes', false),
      saveLogsToStorage: read<bool>('saveLogsToStorage', false),
      verboseLogging: read<bool>('verboseLogging', false),
      backgroundMusicPath: rawMusicPath as String?,
      musicLibraryPaths: readStrings('musicLibraryPaths'),
      musicQueuePaths: readStrings('musicQueuePaths'),
      musicPlaylistPaths: readPlaylists(),
      musicRepeatMode: repeat,
      musicShuffle: read<bool>('musicShuffle', false),
      themePreset: read<String>('themePreset', 'Neon'),
      customPrimaryColor: primary,
      customSecondaryColor: secondary,
      customTertiaryColor: tertiary,
      moreScreenOrder: moreOrder,
      moreScreenButtonColors: readColors(),
      webMenuStudioLayout: rawMenuLayout as String?,
      tutorialCompleted: read<bool>('tutorialCompleted', false),
      tutorialSeenFeatures: tutorialFeatures.toSet(),
      updateCheckIntervalHours: updateInterval,
    );
  }
}
