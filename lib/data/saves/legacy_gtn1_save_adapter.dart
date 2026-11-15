import 'dart:convert';

import '../../core/legacy/adaptive_trait_profile.dart';
import '../../core/legacy/legacy_systems_state.dart';
import '../../core/numbers/big_number.dart';
import '../../core/progression/progression_state.dart';
import '../../settings/game_settings.dart';
import 'save_data.dart';

/// Strict adapter for a single GTN1 GameState JSON document.
///
/// Fields are translated only where GTN2 has an equivalent persisted
/// representation. Non-default GTN1 fields without an equivalent cause a
/// FormatException instead of being silently discarded.
class LegacyGtn1SaveAdapter {
  LegacyGtn1SaveAdapter._();

  static SaveData decodeGameState(String sourceJson) {
    final decoded = jsonDecode(sourceJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('GTN1 save root must be an object.');
    }
    return fromGameStateJson(decoded);
  }

  static SaveData fromGameStateJson(Map<String, dynamic> source) {
    final unsupported = <String>[];

    void rejectWhen(bool condition, String field) {
      if (condition) unsupported.add(field);
    }

    final statistics = _object(source, 'statistics');
    final settingsJson = _object(source, 'settings');
    final traitJson = _object(source, 'traitProfile');

    // The GTN1 trait profile and GTN2 adaptive profile share this exact
    // persisted contract. Keep it rather than dropping behavioral memory.
    final adaptiveTraitProfile = _adaptiveTraitProfile(traitJson);

    // These source values have no equivalent in the current GTN2 save model.
    rejectWhen(_int(statistics, 'failedGuesses') != 0, 'statistics.failedGuesses');
    rejectWhen(_int(statistics, 'arcadePlayed') != 0, 'statistics.arcadePlayed');
    rejectWhen(_map(statistics, 'arcadeBestScores').isNotEmpty, 'statistics.arcadeBestScores');
    rejectWhen(_set(source, 'shopPurchases').isNotEmpty, 'shopPurchases');
    rejectWhen(_set(source, 'prestigeShopPurchases').isNotEmpty, 'prestigeShopPurchases');
    rejectWhen(_set(source, 'ultraShopPurchases').isNotEmpty, 'ultraShopPurchases');
    rejectWhen(_string(source, 'buyMultiplier', fallback: '1') != '1', 'buyMultiplier');
    rejectWhen(_int(source, 'creativeAttemptLimit') != 0, 'creativeAttemptLimit');
    rejectWhen(_number(source, 'creativeRewardMultiplier', fallback: 1) != 1, 'creativeRewardMultiplier');
    rejectWhen(_map(source, 'bossBattleProgress').isNotEmpty, 'bossBattleProgress');

    final legacy = <String, dynamic>{
      'adaptiveTraitProfile': adaptiveTraitProfile.toJson(),
      'discoveredTraits': _set(source, 'discoveredTraitIds').toList(),
      'selectedTraitArms': _stringMap(source, 'selectedTraitArms'),
      'activeMutators': _set(source, 'activeMutators').toList(),
      'talents': _set(source, 'talents').toList(),
      'relicInventory': _set(source, 'relicInventory').toList(),
      'equippedRelics': _set(source, 'equippedRelicIds').toList(),
      'homeBaseLevel': _int(source, 'homeBaseLevel'),
      'dailyQuestDate': _string(source, 'dailyQuestDate'),
      'dailyQuestGuesses': _int(source, 'dailyQuestGuesses'),
      'dailyQuestCorrectGuesses': _int(source, 'dailyQuestCorrectGuesses'),
      'dailyQuestBestStreak': _int(source, 'dailyQuestBestStreak'),
      'dailyQuestUpgradePurchases': _int(source, 'dailyQuestUpgradePurchases'),
      'claimedDailyQuests': _set(source, 'claimedDailyQuests').toList(),
      'lastDailyRewardDate': _string(source, 'lastDailyRewardDate'),
      'dailyRewardStreak': _int(source, 'dailyRewardStreak'),
      'lootChests': {
        'common': _int(source, 'lootCommonChests'),
        'rare': _int(source, 'lootRareChests'),
        'epic': _int(source, 'lootEpicChests'),
      },
      'lootDropsFound': _int(source, 'lootDropsFound'),
      'lootChestsOpened': _int(source, 'lootChestsOpened'),
      'lastLootDropTier': source['lastLootDropTier'],
      'lootEventId': _int(source, 'lootEventId'),
      'completedChallenges': _set(source, 'completedChallenges').toList(),
      'worldMasteryLevels': _map(source, 'worldMasteryLevels'),
      'discoveredSecrets': _set(source, 'discoveredSecretIds').toList(),
      'codexEntries': _set(source, 'codexEntries').toList(),
      'activeWorldId': _string(source, 'activeWorldId', fallback: 'verdant_grove'),
      'unlockedWorldIds': _set(source, 'unlockedWorldIds', fallback: {'verdant_grove'}).toList(),
      'endlessRiftTier': _int(source, 'endlessRiftTier'),
      'endlessRiftBestTier': _int(source, 'endlessRiftBestTier'),
      'endlessRiftActive': _bool(source, 'endlessRiftActive'),
      'worldBossVictories': _int(source, 'worldBossVictories'),
      'stakesPlaced': _int(source, 'stakesPlaced'),
      'stakesWon': _int(source, 'stakesWon'),
      'stakesLost': _int(source, 'stakesLost'),
      'musicLibrary': _list(settingsJson, 'musicLibraryPaths'),
      'musicQueue': _list(settingsJson, 'musicQueuePaths'),
      'musicPlaylists': _mapOfLists(settingsJson, 'musicPlaylistPaths'),
      'musicRepeatMode': _string(settingsJson, 'musicRepeatMode', fallback: 'off'),
      'musicShuffle': _bool(settingsJson, 'musicShuffle'),
      'permanentEventBoosts': _int(source, 'permanentEventBoosts'),
      'endgameRewardsClaimed': _set(source, 'endgameRewardsClaimed').toList(),
      'codexRewardClaimed': _bool(source, 'codexRewardClaimed'),
      'activeBossBattleWorldId': source['activeBossBattleWorldId'],
      'bossBattleMistakes': _map(source, 'bossBattleMistakes'),
      'liveOpsClaims': _map(source, 'liveOpsClaims'),
      'lastRandomEventId': source['lastRandomEventId'],
      'autoClickerActive': _bool(source, 'autoClickerActive'),
      'autoClickerSpeed': _number(source, 'autoClickerSpeed', fallback: 1),
      'lastBotGuess': source['lastBotGuess'],
      'lastBotFeedback': source['lastBotFeedback'],
      'lastBotId': source['lastBotId'],
      'botActionSequence': _int(source, 'botActionSequence'),
      'botTotalGuesses': _int(source, 'botTotalGuesses'),
      'botCorrectGuesses': _int(source, 'botCorrectGuesses'),
      'botIncorrectGuesses': _int(source, 'botIncorrectGuesses'),
      'lastSaveTimestamp': _int(source, 'lastSavedAt'),
      'timeTravelPenaltyUntil': _int(source, 'timeTravelPenaltyUntil'),
    };

    final progression = ProgressionState(
      money: _bigNumber(source, 'money'),
      prestige: _bigNumber(source, 'prestige'),
      ultra: _bigNumber(source, 'ultra'),
      nebula: _bigNumber(source, 'nebulaCurrency'),
      upgrades: _map(source, 'upgradeLevels'),
      prestigeUpgrades: _map(source, 'prestigeUpgradeLevels'),
      ultraUpgrades: _map(source, 'ultraUpgradeLevels'),
      equippedCosmeticId: _nullableString(source, 'equippedCosmeticId'),
      defeatedBosses: _set(source, 'defeatedBosses'),
      prestigeResets: _int(source, 'prestigeCount'),
      ultraResets: _int(source, 'ultraCount'),
      totalGuesses: _int(statistics, 'totalGuesses'),
      correctGuesses: _int(statistics, 'correctGuesses'),
      moneyEarned: _bigNumber(statistics, 'moneyEarned'),
      moneySpent: _bigNumber(statistics, 'moneySpent'),
      randomEventsTriggered: _int(statistics, 'randomEventsTriggered'),
      lastRandomEventId: _nullableString(source, 'lastRandomEventId'),
      currentStreak: _int(source, 'currentStreak'),
      bestStreak: _int(source, 'bestStreak'),
      playtimeSeconds: _int(statistics, 'playtimeSeconds'),
      achievements: _set(source, 'achievements'),
      nebulaEarned: _bigNumber(statistics, 'nebulaEarned'),
      legacySystems: LegacySystemsState.fromJson(legacy),
    );

    if (unsupported.isNotEmpty) {
      throw FormatException(
        'GTN1 save contains fields that GTN2 cannot preserve yet: ${unsupported.join(', ')}',
      );
    }

    final settings = _settings(settingsJson).copyWith(
      difficultyId: _string(source, 'difficultyId', fallback: 'classic'),
    );
    final name = _string(source, 'profileName').trim();
    final data = SaveData(
      secret: _int(source, 'targetNumber', fallback: 50),
      attempts: _int(source, 'attempts'),
      correctGuesses: _int(source, 'correctGuesses'),
      streak: _int(source, 'currentStreak'),
      bestStreak: _int(source, 'bestStreak'),
      gamesWon: _int(source, 'gamesWon'),
      isComplete: _bool(source, 'isComplete'),
      minimum: _int(source, 'currentRangeMin', fallback: 1),
      maximum: _int(source, 'currentRangeMax', fallback: 100),
      progression: progression,
      settings: settings,
      profileName: name.substring(0, name.length.clamp(0, 24)),
      profileIconId: _profileIcon(_string(source, 'profileIconId', fallback: 'default')),
      creativeModeEnabled: _bool(source, 'creativeModeEnabled'),
    );
    SaveData.fromJson(data.toJson());
    return data;
  }

  static AdaptiveTraitProfile _adaptiveTraitProfile(
    Map<String, dynamic> source,
  ) {
    final json = <String, dynamic>{
      'schemaVersion': _int(source, 'schemaVersion', fallback: 1),
      'totalGuessesObserved': _int(source, 'totalGuessesObserved'),
      'correctGuessesObserved': _int(source, 'correctGuessesObserved'),
      'failedGuessesObserved': _int(source, 'failedGuessesObserved'),
      'closeMissesObserved': _int(source, 'closeMissesObserved'),
      'longStreaksObserved': _int(source, 'longStreaksObserved'),
      'sessionsObserved': _int(source, 'sessionsObserved'),
      'prestigesObserved': _int(source, 'prestigesObserved'),
      'ultrasObserved': _int(source, 'ultrasObserved'),
      'upgradesPurchasedObserved': _int(source, 'upgradesPurchasedObserved'),
      'moneyEarnedObserved': _bigNumber(source, 'moneyEarnedObserved').toString(),
      'moneySpentObserved': _bigNumber(source, 'moneySpentObserved').toString(),
      'consistencyScore': _number(source, 'consistencyScore'),
      'accuracyScore': _number(source, 'accuracyScore'),
      'riskScore': _number(source, 'riskScore'),
      'persistenceScore': _number(source, 'persistenceScore'),
      'progressionScore': _number(source, 'progressionScore'),
      'helperUses': _map(source, 'helperUses'),
      'helperCooldowns': _map(source, 'helperCooldowns'),
      'awardedBonuses': _set(source, 'awardedBonuses').toList(),
    };
    return AdaptiveTraitProfile.fromJson(json);
  }

  static GameSettings _settings(Map<String, dynamic> source) {
    final theme = _string(source, 'themeMode', fallback: 'System');
    return GameSettings(
      darkMode: theme.toLowerCase() != 'light',
      reduceMotion: _bool(source, 'reducedMotion'),
      localeCode: _string(source, 'locale', fallback: 'en-US')
          .replaceAll('-', '_')
          .toLowerCase(),
      themeMode: theme,
      numberNotation: _string(source, 'numberNotation', fallback: 'Standard'),
      musicEnabled: _bool(source, 'musicEnabled', fallback: true),
      soundEnabled: _bool(source, 'soundEnabled', fallback: true),
      vibrationEnabled: _bool(source, 'vibrationEnabled', fallback: true),
      notificationsEnabled: _bool(source, 'notificationsEnabled', fallback: true),
      notificationRemindersEnabled: _bool(source, 'notificationRemindersEnabled', fallback: true),
      notificationProgressionEnabled: _bool(source, 'notificationProgressionEnabled', fallback: true),
      notificationEventsEnabled: _bool(source, 'notificationEventsEnabled', fallback: true),
      notificationIntervalHours: _int(source, 'notificationIntervalHours', fallback: 24),
      volume: _number(source, 'volume', fallback: 1),
      sfxVolume: _number(source, 'sfxVolume', fallback: 1),
      reduceFlashes: _bool(source, 'reduceFlashes'),
      saveLogsToStorage: _bool(source, 'saveLogsToStorage'),
      verboseLogging: _bool(source, 'verboseLogging'),
      backgroundMusicPath: _nullableString(source, 'backgroundMusicPath'),
      musicLibraryPaths: _list(source, 'musicLibraryPaths'),
      musicQueuePaths: _list(source, 'musicQueuePaths'),
      musicPlaylistPaths: _mapOfLists(source, 'musicPlaylistPaths'),
      musicRepeatMode: _string(source, 'musicRepeatMode', fallback: 'off'),
      musicShuffle: _bool(source, 'musicShuffle'),
      themePreset: _string(source, 'themePreset', fallback: 'Neon'),
      customPrimaryColor: _string(source, 'customPrimaryColor', fallback: '#7C4DFF'),
      customSecondaryColor: _string(source, 'customSecondaryColor', fallback: '#00BCD4'),
      customTertiaryColor: _string(source, 'customTertiaryColor', fallback: '#00C853'),
      moreScreenOrder: _list(source, 'moreScreenOrder'),
      moreScreenButtonColors: _stringMap(source, 'moreScreenButtonColors'),
      webMenuStudioLayout: _nullableString(source, 'webMenuStudioLayout'),
      tutorialCompleted: _bool(source, 'tutorialCompleted'),
      tutorialSeenFeatures: _set(source, 'tutorialSeenFeatures'),
    );
  }

  static String _profileIcon(String id) =>
      SaveData.profileIconIds.contains(id) ? id : 'default';

  static Map<String, dynamic> _object(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) return const {};
    if (value is! Map) throw FormatException('Invalid GTN1 object: $key');
    return Map<String, dynamic>.from(value);
  }

  static int _int(Map<String, dynamic> source, String key, {int fallback = 0}) {
    final value = source[key] ?? fallback;
    if (value is! int || value < 0) throw FormatException('Invalid GTN1 integer: $key');
    return value;
  }

  static double _number(
    Map<String, dynamic> source,
    String key, {
    double fallback = 0,
  }) {
    final value = source[key] ?? fallback;
    if (value is! num || !value.isFinite) {
      throw FormatException('Invalid GTN1 number: $key');
    }
    return value.toDouble();
  }

  static bool _bool(
    Map<String, dynamic> source,
    String key, {
    bool fallback = false,
  }) {
    final value = source[key] ?? fallback;
    if (value is! bool) throw FormatException('Invalid GTN1 boolean: $key');
    return value;
  }

  static String _string(
    Map<String, dynamic> source,
    String key, {
    String fallback = '',
  }) {
    final value = source[key] ?? fallback;
    if (value is! String) throw FormatException('Invalid GTN1 string: $key');
    return value;
  }

  static String? _nullableString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) return null;
    if (value is! String) throw FormatException('Invalid GTN1 string: $key');
    return value;
  }

  static BigNumber _bigNumber(Map<String, dynamic> source, String key) {
    final value = source[key] ?? '0';
    if (value is! String && value is! num) {
      throw FormatException('Invalid GTN1 currency: $key');
    }
    final parsed = BigNumber.parse(value.toString());
    if (parsed.compareTo(BigNumber.fromInt(0)) < 0) {
      throw FormatException('Negative GTN1 currency: $key');
    }
    return parsed;
  }

  static Set<String> _set(
    Map<String, dynamic> source,
    String key, {
    Set<String> fallback = const {},
  }) {
    final value = source[key];
    if (value == null) return fallback;
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Invalid GTN1 string set: $key');
    }
    return value.cast<String>().toSet();
  }

  static List<String> _list(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) return const [];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Invalid GTN1 string list: $key');
    }
    return value.cast<String>();
  }

  static Map<String, int> _map(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) return const {};
    if (value is! Map) throw FormatException('Invalid GTN1 map: $key');
    final result = <String, int>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! int || entry.value < 0) {
        throw FormatException('Invalid GTN1 integer map: $key');
      }
      result[entry.key as String] = entry.value as int;
    }
    return result;
  }

  static Map<String, String> _stringMap(
    Map<String, dynamic> source,
    String key,
  ) {
    final value = source[key];
    if (value == null) return const {};
    if (value is! Map) throw FormatException('Invalid GTN1 string map: $key');
    final result = <String, String>{};
    for (final entry in value.entries) {
      if (entry.key is! String || entry.value is! String) {
        throw FormatException('Invalid GTN1 string map: $key');
      }
      result[entry.key as String] = entry.value as String;
    }
    return result;
  }

  static Map<String, List<String>> _mapOfLists(
    Map<String, dynamic> source,
    String key,
  ) {
    final value = source[key];
    if (value == null) return const {};
    if (value is! Map) throw FormatException('Invalid GTN1 playlist map: $key');
    final result = <String, List<String>>{};
    for (final entry in value.entries) {
      if (entry.key is! String ||
          entry.value is! List ||
          (entry.value as List).any((item) => item is! String)) {
        throw FormatException('Invalid GTN1 playlist map: $key');
      }
      result[entry.key as String] = (entry.value as List).cast<String>();
    }
    return result;
  }
}
