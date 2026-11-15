import 'dart:convert';

import '../../core/game/difficulty_rules.dart';
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
    final statistics = _object(source, 'statistics');
    final extensions = _object(source, 'gtn2Extensions');
    final extensionProgression = _object(extensions, 'progression');
    final extensionLegacy = _object(extensions, 'legacySystems');
    final settingsJson = _object(source, 'settings');
    final traitJson = _object(source, 'traitProfile');
    final adaptiveTraitProfile = _adaptiveTraitProfile(traitJson);
    final upgradeLevels = _map(source, 'upgradeLevels');
    final attempts = _sanitizedCount(source, 'attempts');
    final correctGuesses = _sanitizedCount(
      source,
      'correctGuesses',
    ).clamp(0, attempts).toInt();
    final streak = _sanitizedCount(source, 'streak');
    final bestStreak = _sanitizedCount(source, 'bestStreak') < streak
        ? streak
        : _sanitizedCount(source, 'bestStreak');

    final legacy = <String, dynamic>{
      ...extensionLegacy,
      'adaptiveTraitProfile': adaptiveTraitProfile.toJson(),
      'legacyGtn1Snapshot':
          jsonDecode(jsonEncode(source)) as Map<String, dynamic>,
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
      'activeWorldId': _string(
        source,
        'activeWorldId',
        fallback: 'verdant_grove',
      ),
      'unlockedWorldIds': _set(
        source,
        'unlockedWorldIds',
        fallback: {'verdant_grove'},
      ).toList(),
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
      'musicRepeatMode': _string(
        settingsJson,
        'musicRepeatMode',
        fallback: 'off',
      ),
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
      'lastSaveTimestamp': _sanitizedCount(source, 'lastSaveTimestamp'),
      'timeTravelPenaltyUntil': _sanitizedCount(
        source,
        'timeTravelPenaltyUntil',
      ),
    };

    final progression = ProgressionState(
      money: _sanitizedBigNumber(source, 'money'),
      prestige: _sanitizedBigNumber(source, 'prestige'),
      ultra: _sanitizedBigNumber(source, 'ultra'),
      nebula: _sanitizedBigNumber(source, 'nebula'),
      nebulaItems: _map(extensionProgression, 'nebulaItems'),
      upgrades: upgradeLevels,
      prestigeUpgrades: _map(source, 'prestigeUpgradeLevels'),
      ultraUpgrades: _map(source, 'ultraUpgradeLevels'),
      equippedCosmeticId: _supportedCosmetic(
        _nullableString(source, 'equippedCosmeticId'),
      ),
      defeatedBosses: _set(source, 'defeatedBossIds'),
      prestigeResets: _int(source, 'prestigeCount'),
      ultraResets: _int(source, 'ultraCount'),
      totalGuesses: _int(statistics, 'totalGuesses'),
      correctGuesses: _int(statistics, 'correctGuesses'),
      moneyEarned: _bigNumber(statistics, 'moneyEarned'),
      moneySpent: _bigNumber(statistics, 'moneySpent'),
      randomEventsTriggered: _int(statistics, 'randomEventsTriggered'),
      lastRandomEventId: _supportedRandomEvent(
        _nullableString(source, 'lastRandomEventId'),
      ),
      bossDamage: _map(source, 'bossBattleProgress'),
      currentStreak: streak,
      bestStreak: bestStreak,
      playtimeSeconds: _int(statistics, 'playtimeSeconds'),
      achievements: _set(source, 'achievements'),
      nebulaEarned: _bigNumber(statistics, 'nebulaEarned'),
      legacySystems: LegacySystemsState.fromJson(legacy),
    );

    final rawDifficulty = _string(source, 'difficultyId', fallback: 'classic');
    final difficulty =
        const {'classic', 'hard', 'extreme'}.contains(rawDifficulty)
        ? rawDifficulty
        : 'classic';
    final settings = _settings(settingsJson).copyWith(
      difficultyId: difficulty,
      tutorialCompleted:
          _bool(source, 'tutorialCompleted') ||
          _bool(settingsJson, 'tutorialCompleted'),
    );
    final name = _string(source, 'profileName').trim();
    final creative = _bool(source, 'creativeModeEnabled');
    final minimum = creative
        ? _signedInt(
            source,
            'currentRangeMin',
            fallback: 1,
          ).clamp(1, 1000000).toInt()
        : 1;
    final rawMaximum = _signedInt(source, 'currentRangeMax', fallback: 100);
    final difficultyMaximum = DifficultyRules.rangeMaximum(
      difficulty,
      upgradeLevels['better_range'] ?? 0,
    );
    final maximum = creative
        ? rawMaximum.clamp(minimum, 1000000).toInt()
        : (rawMaximum < difficultyMaximum ? difficultyMaximum : rawMaximum)
              .clamp(1, 500)
              .toInt();
    final data = SaveData(
      secret: _signedInt(
        source,
        'targetNumber',
        fallback: 50,
      ).clamp(minimum, maximum).toInt(),
      attempts: attempts,
      correctGuesses: correctGuesses,
      streak: streak,
      bestStreak: bestStreak,
      gamesWon: _int(
        extensions,
        'gamesWon',
        fallback: _int(source, 'gamesWon'),
      ),
      isComplete: _bool(
        extensions,
        'isComplete',
        fallback: _bool(source, 'isComplete'),
      ),
      minimum: minimum,
      maximum: maximum,
      progression: progression,
      settings: settings,
      profileName: name.substring(0, name.length > 24 ? 24 : name.length),
      profileIconId: _profileIcon(
        _string(source, 'profileIconId', fallback: 'default'),
      ),
      creativeModeEnabled: creative,
    );
    SaveData.fromJson(data.toJson());
    return data;
  }

  /// Rebuilds the pinned GTN1 GameState schema while retaining source-only
  /// fields from the imported snapshot. Current GTN2 values always win.
  static Map<String, dynamic> toGameStateJson(SaveData save) {
    final legacy = save.progression.legacySystems;
    final snapshot = legacy.legacyGtn1Snapshot;
    final source = snapshot.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(jsonEncode(snapshot)) as Map);
    final statistics = _object(source, 'statistics');
    statistics
      ..['totalGuesses'] = save.progression.totalGuesses
      ..['correctGuesses'] = save.progression.correctGuesses
      // GTN2 has no independent failed-guesses counter. Preserve the
      // original GTN1 value when available instead of replacing it with a
      // derived value that may differ from the source's historical statistic.
      ..['failedGuesses'] = statistics.containsKey('failedGuesses')
          ? statistics['failedGuesses']
          : (save.progression.totalGuesses -
                    save.progression.correctGuesses)
                .clamp(0, save.progression.totalGuesses)
                .toInt()
      ..['moneyEarned'] = save.progression.moneyEarned.toString()
      ..['moneySpent'] = save.progression.moneySpent.toString()
      ..['prestigesCount'] = save.progression.prestigeResets
      ..['ultrasCount'] = save.progression.ultraResets
      ..['nebulaEarned'] = _bigNumberToLong(save.progression.nebulaEarned)
      ..['playtimeSeconds'] = save.progression.playtimeSeconds
      ..['randomEventsTriggered'] = save.progression.randomEventsTriggered;

    source
      ..['difficultyId'] = save.settings.difficultyId
      ..['profileName'] = save.profileName
      ..['profileIconId'] = save.profileIconId
      ..['creativeModeEnabled'] = save.creativeModeEnabled
      ..['money'] = save.progression.money.toString()
      ..['prestige'] = save.progression.prestige.toString()
      ..['ultra'] = save.progression.ultra.toString()
      ..['nebula'] = save.progression.nebula.toString()
      ..['currentRangeMin'] = save.minimum
      ..['currentRangeMax'] = save.maximum
      ..['targetNumber'] = save.secret
      ..['attempts'] = save.attempts
      ..['correctGuesses'] = save.correctGuesses
      ..['streak'] = save.streak
      ..['bestStreak'] = save.bestStreak
      ..['upgradeLevels'] = save.progression.upgrades
      ..['prestigeUpgradeLevels'] = save.progression.prestigeUpgrades
      ..['ultraUpgradeLevels'] = save.progression.ultraUpgrades
      ..['equippedCosmeticId'] = save.progression.equippedCosmeticId
      ..['defeatedBossIds'] = save.progression.defeatedBosses.toList()
      ..['prestigeCount'] = save.progression.prestigeResets
      ..['ultraCount'] = save.progression.ultraResets
      ..['achievements'] = save.progression.achievements.toList()
      ..['bossBattleProgress'] = save.progression.bossDamage
      ..['statistics'] = statistics
      ..['settings'] = toGameSettingsJson(save.settings)
      ..['traitProfile'] = legacy.adaptiveTraitProfile.toJson()
      ..['tutorialCompleted'] = save.settings.tutorialCompleted
      ..['lastSaveTimestamp'] = legacy.lastSaveTimestamp
      ..['timeTravelPenaltyUntil'] = legacy.timeTravelPenaltyUntil
      ..['autoClickerActive'] = legacy.autoClickerActive
      ..['autoClickerSpeed'] = legacy.autoClickerSpeed
      ..['lastBotGuess'] = legacy.lastBotGuess
      ..['lastBotFeedback'] = legacy.lastBotFeedback
      ..['lastBotId'] = legacy.lastBotId
      ..['botActionSequence'] = legacy.botActionSequence
      ..['botTotalGuesses'] = legacy.botTotalGuesses
      ..['botCorrectGuesses'] = legacy.botCorrectGuesses
      ..['botIncorrectGuesses'] = legacy.botIncorrectGuesses
      ..['activeMutators'] = legacy.activeMutators.toList()
      ..['discoveredTraitIds'] = legacy.discoveredTraits.toList()
      ..['selectedTraitArms'] = legacy.selectedTraitArms
      ..['relicInventory'] = legacy.relicInventory.toList()
      ..['equippedRelicIds'] = legacy.equippedRelics.toList()
      ..['homeBaseLevel'] = legacy.homeBaseLevel
      ..['dailyQuestDate'] = legacy.dailyQuestDate
      ..['dailyQuestGuesses'] = legacy.dailyQuestGuesses
      ..['dailyQuestCorrectGuesses'] = legacy.dailyQuestCorrectGuesses
      ..['dailyQuestBestStreak'] = legacy.dailyQuestBestStreak
      ..['dailyQuestUpgradePurchases'] = legacy.dailyQuestUpgradePurchases
      ..['claimedDailyQuests'] = legacy.claimedDailyQuests.toList()
      ..['lastDailyRewardDate'] = legacy.lastDailyRewardDate
      ..['dailyRewardStreak'] = legacy.dailyRewardStreak
      ..['lootCommonChests'] = legacy.lootChests['common'] ?? 0
      ..['lootRareChests'] = legacy.lootChests['rare'] ?? 0
      ..['lootEpicChests'] = legacy.lootChests['epic'] ?? 0
      ..['lootDropsFound'] = legacy.lootDropsFound
      ..['lootChestsOpened'] = legacy.lootChestsOpened
      ..['lastLootDropTier'] = legacy.lastLootDropTier
      ..['lootEventId'] = legacy.lootEventId
      ..['completedChallenges'] = legacy.completedChallenges.toList()
      ..['worldMasteryLevels'] = legacy.worldMasteryLevels
      ..['discoveredSecretIds'] = legacy.discoveredSecrets.toList()
      ..['codexEntries'] = legacy.codexEntries.toList()
      ..['activeWorldId'] = legacy.activeWorldId
      ..['unlockedWorldIds'] = legacy.unlockedWorldIds.toList()
      ..['endlessRiftTier'] = legacy.endlessRiftTier
      ..['endlessRiftBestTier'] = legacy.endlessRiftBestTier
      ..['endlessRiftActive'] = legacy.endlessRiftActive
      ..['worldBossVictories'] = legacy.worldBossVictories
      ..['permanentEventBoosts'] = legacy.permanentEventBoosts
      ..['endgameRewardsClaimed'] = legacy.endgameRewardsClaimed.toList()
      ..['codexRewardClaimed'] = legacy.codexRewardClaimed
      ..['activeBossBattleWorldId'] = legacy.activeBossBattleWorldId
      ..['bossBattleMistakes'] = legacy.bossBattleMistakes
      ..['liveOpsClaims'] = legacy.liveOpsClaims
      ..['lastRandomEventId'] = legacy.lastRandomEventId
      ..['gtn2Extensions'] = {
        'gamesWon': save.gamesWon,
        'isComplete': save.isComplete,
        'progression': {'nebulaItems': save.progression.nebulaItems},
        'legacySystems': _legacyExtensionJson(legacy),
      };
    return source;
  }

  /// Encodes the GTN1 GameSettings property names and locale representation.
  static Map<String, dynamic> toGameSettingsJson(GameSettings settings) {
    final localeParts = settings.localeCode.split('_');
    final locale = localeParts.length == 1
        ? localeParts.first
        : '${localeParts.first}-${localeParts.skip(1).map((part) => part.toUpperCase()).join('-')}';
    return {
      'musicEnabled': settings.musicEnabled,
      'soundEnabled': settings.soundEnabled,
      'vibrationEnabled': settings.vibrationEnabled,
      'notificationsEnabled': settings.notificationsEnabled,
      'notificationRemindersEnabled': settings.notificationRemindersEnabled,
      'notificationProgressionEnabled': settings.notificationProgressionEnabled,
      'notificationEventsEnabled': settings.notificationEventsEnabled,
      'notificationIntervalHours': settings.notificationIntervalHours,
      'themeMode': settings.themeMode,
      'numberNotation': settings.numberNotation,
      'locale': locale,
      'reducedMotion': settings.reduceMotion,
      'volume': settings.volume,
      'sfxVolume': settings.sfxVolume,
      'reduceFlashes': settings.reduceFlashes,
      'saveLogsToStorage': settings.saveLogsToStorage,
      'verboseLogging': settings.verboseLogging,
      'backgroundMusicPath': settings.backgroundMusicPath,
      'musicLibraryPaths': settings.musicLibraryPaths,
      'musicQueuePaths': settings.musicQueuePaths,
      'musicPlaylistPaths': settings.musicPlaylistPaths,
      'musicRepeatMode': settings.musicRepeatMode,
      'musicShuffle': settings.musicShuffle,
      'themePreset': settings.themePreset,
      'customPrimaryColor': settings.customPrimaryColor,
      'customSecondaryColor': settings.customSecondaryColor,
      'customTertiaryColor': settings.customTertiaryColor,
      'moreScreenOrder': settings.moreScreenOrder,
      'moreScreenButtonColors': settings.moreScreenButtonColors,
      'webMenuStudioLayout': settings.webMenuStudioLayout,
      'tutorialCompleted': settings.tutorialCompleted,
      'tutorialSeenFeatures': settings.tutorialSeenFeatures.toList(),
      'gtn2UpdateCheckIntervalHours': settings.updateCheckIntervalHours,
      'gtn2TutorialCompleted': settings.tutorialCompleted,
    };
  }

  static Map<String, dynamic> _legacyExtensionJson(LegacySystemsState state) {
    final json = Map<String, dynamic>.from(state.toJson());
    json.remove('legacyGtn1Snapshot');
    return json;
  }

  static int _bigNumberToLong(BigNumber value) {
    if (value.scale != 0) {
      throw const FormatException('GTN1 nebulaEarned requires an integer.');
    }
    final parsed = int.tryParse(value.coefficient.toString());
    if (parsed == null || parsed < 0) {
      throw const FormatException(
        'GTN1 nebulaEarned exceeds the source range.',
      );
    }
    return parsed;
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
      'moneyEarnedObserved': _bigNumber(
        source,
        'moneyEarnedObserved',
      ).toString(),
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
    final migrated = GameSettings(
      darkMode: theme.toLowerCase() != 'light',
      reduceMotion: _bool(source, 'reducedMotion'),
      localeCode: _string(
        source,
        'locale',
        fallback: 'en-US',
      ).replaceAll('-', '_').toLowerCase(),
      themeMode: theme,
      numberNotation: _string(source, 'numberNotation', fallback: 'Standard'),
      musicEnabled: _bool(source, 'musicEnabled', fallback: true),
      soundEnabled: _bool(source, 'soundEnabled', fallback: true),
      vibrationEnabled: _bool(source, 'vibrationEnabled', fallback: true),
      notificationsEnabled: _bool(
        source,
        'notificationsEnabled',
        fallback: true,
      ),
      notificationRemindersEnabled: _bool(
        source,
        'notificationRemindersEnabled',
        fallback: true,
      ),
      notificationProgressionEnabled: _bool(
        source,
        'notificationProgressionEnabled',
        fallback: true,
      ),
      notificationEventsEnabled: _bool(
        source,
        'notificationEventsEnabled',
        fallback: true,
      ),
      notificationIntervalHours: _int(
        source,
        'notificationIntervalHours',
        fallback: 24,
      ),
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
      customPrimaryColor: _string(
        source,
        'customPrimaryColor',
        fallback: '#7C4DFF',
      ),
      customSecondaryColor: _string(
        source,
        'customSecondaryColor',
        fallback: '#00BCD4',
      ),
      customTertiaryColor: _string(
        source,
        'customTertiaryColor',
        fallback: '#00C853',
      ),
      moreScreenOrder: source['moreScreenOrder'] == null
          ? const [
              'world_map',
              'achievements',
              'live_ops',
              'lua_hub',
              'mutators',
              'talent',
              'relics',
              'home_base',
              'codex',
              'endgame',
              'arcade',
              'stats',
              'changelog',
              'settings',
              'about',
              'staking',
              'ultra',
              'prestige',
              'save_slots',
              'music',
            ]
          : _list(source, 'moreScreenOrder'),
      moreScreenButtonColors: _stringMap(source, 'moreScreenButtonColors'),
      webMenuStudioLayout: _nullableString(source, 'webMenuStudioLayout'),
      tutorialCompleted:
          _bool(source, 'tutorialCompleted') ||
          _bool(source, 'gtn2TutorialCompleted'),
      tutorialSeenFeatures: _set(source, 'tutorialSeenFeatures'),
      updateCheckIntervalHours: _int(source, 'gtn2UpdateCheckIntervalHours'),
    );
    return GameSettings.fromJson(migrated.toJson());
  }

  static GameSettings decodeGameSettingsJson(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('GTN1 app preferences must be an object.');
    }
    return _settings(decoded);
  }

  static String? _supportedCosmetic(String? id) =>
      id == null ||
          const {
            'cosmetic_nebula_ring',
            'cosmetic_starfield',
            'cosmetic_pixel_glow',
          }.contains(id)
      ? id
      : null;

  static String? _supportedRandomEvent(String? id) =>
      id == null ||
          const {
            'cash_burst',
            'nebula_rain',
            'jackpot',
            'streak_surge',
            'range_shuffle',
            'tax_refund',
            'cosmic_gift',
          }.contains(id)
      ? id
      : null;

  static String _profileIcon(String id) =>
      SaveData.profileIconIds.contains(id) ? id : 'default';

  static Map<String, dynamic> _object(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value == null) return <String, dynamic>{};
    if (value is! Map) throw FormatException('Invalid GTN1 object: $key');
    return Map<String, dynamic>.from(value);
  }

  static int _int(Map<String, dynamic> source, String key, {int fallback = 0}) {
    final value = source[key] ?? fallback;
    if (value is! int || value < 0) {
      throw FormatException('Invalid GTN1 integer: $key');
    }
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

  static int _signedInt(
    Map<String, dynamic> source,
    String key, {
    int fallback = 0,
  }) {
    final value = source[key] ?? fallback;
    if (value is! int) throw FormatException('Invalid GTN1 integer: $key');
    return value;
  }

  static int _sanitizedCount(
    Map<String, dynamic> source,
    String key, {
    int fallback = 0,
  }) {
    final value = _signedInt(source, key, fallback: fallback);
    return value < 0 ? 0 : value;
  }

  static BigNumber _sanitizedBigNumber(
    Map<String, dynamic> source,
    String key,
  ) {
    final raw = source[key] ?? '0';
    if (raw is! String && raw is! num) {
      throw FormatException('Invalid GTN1 currency: $key');
    }
    final value = BigNumber.parse(raw.toString());
    return value.compareTo(BigNumber.fromInt(0)) < 0
        ? BigNumber.fromInt(0)
        : value;
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
      if (entry.key is! String || entry.value is! int) {
        throw FormatException('Invalid GTN1 integer map: $key');
      }
      final number = entry.value as int;
      if (number < 0) {
        throw FormatException('Invalid GTN1 integer map: $key');
      }
      result[entry.key as String] = number;
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
