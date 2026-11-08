import 'adaptive_trait_profile.dart';

/// Persisted per-save-slot state for GTN 1 systems that were not in the first Flutter slice.
class LegacySystemsState {
  const LegacySystemsState({
    this.adaptiveTraitProfile = const AdaptiveTraitProfile(),
    this.discoveredTraits = const {},
    this.selectedTraitArms = const {},
    this.activeMutators = const {},
    this.talents = const {},
    this.relicInventory = const {},
    this.equippedRelics = const {},
    this.homeBaseLevel = 0,
    this.dailyQuestDate = '',
    this.dailyQuestGuesses = 0,
    this.dailyQuestCorrectGuesses = 0,
    this.dailyQuestBestStreak = 0,
    this.dailyQuestUpgradePurchases = 0,
    this.claimedDailyQuests = const {},
    this.lastDailyRewardDate = '',
    this.dailyRewardStreak = 0,
    this.lootChests = const {'common': 0, 'rare': 0, 'epic': 0},
    this.lootDropsFound = 0,
    this.lootChestsOpened = 0,
    this.lastLootDropTier,
    this.lootEventId = 0,
    this.completedChallenges = const {},
    this.worldMasteryLevels = const {},
    this.discoveredSecrets = const {},
    this.codexEntries = const {},
    this.activeWorldId = 'verdant_grove',
    this.unlockedWorldIds = const {'verdant_grove'},
    this.endlessRiftTier = 0,
    this.endlessRiftBestTier = 0,
    this.endlessRiftActive = false,
    this.worldBossVictories = 0,
    this.stakesPlaced = 0,
    this.stakesWon = 0,
    this.stakesLost = 0,
    this.musicLibrary = const [],
    this.musicQueue = const [],
    this.musicPlaylists = const {},
    this.musicRepeatMode = 'off',
    this.musicShuffle = false,
    this.currentTrackId,
    this.permanentEventBoosts = 0,
    this.endgameRewardsClaimed = const {},
    this.codexRewardClaimed = false,
    this.activeBossBattleWorldId,
    this.bossBattleMistakes = const {},
    this.liveOpsClaims = const {},
    this.lastRandomEventId,
    this.autoClickerActive = false,
    this.autoClickerSpeed = 1,
    this.botTotalGuesses = 0,
    this.botCorrectGuesses = 0,
    this.botIncorrectGuesses = 0,
    this.botActionSequence = 0,
    this.lastBotGuess,
    this.lastBotFeedback,
    this.lastBotId,
    this.lastSaveTimestamp = 0,
    this.timeTravelPenaltyUntil = 0,
  });

  final AdaptiveTraitProfile adaptiveTraitProfile;
  final Set<String> discoveredTraits;
  final Map<String, String> selectedTraitArms;
  final Set<String> activeMutators;
  final Set<String> talents;
  final Set<String> relicInventory;
  final Set<String> equippedRelics;
  final int homeBaseLevel;
  final String dailyQuestDate;
  final int dailyQuestGuesses;
  final int dailyQuestCorrectGuesses;
  final int dailyQuestBestStreak;
  final int dailyQuestUpgradePurchases;
  final Set<String> claimedDailyQuests;
  final String lastDailyRewardDate;
  final int dailyRewardStreak;
  final Map<String, int> lootChests;
  final int lootDropsFound;
  final int lootChestsOpened;
  final String? lastLootDropTier;
  final int lootEventId;
  final Set<String> completedChallenges;
  final Map<String, int> worldMasteryLevels;
  final Set<String> discoveredSecrets;
  final Set<String> codexEntries;
  final String activeWorldId;
  final Set<String> unlockedWorldIds;
  final int endlessRiftTier;
  final int endlessRiftBestTier;
  final bool endlessRiftActive;
  final int worldBossVictories;
  final int stakesPlaced;
  final int stakesWon;
  final int stakesLost;
  final List<String> musicLibrary;
  final List<String> musicQueue;
  final Map<String, List<String>> musicPlaylists;
  final String musicRepeatMode;
  final bool musicShuffle;
  final String? currentTrackId;
  final int permanentEventBoosts;
  final Set<String> endgameRewardsClaimed;
  final bool codexRewardClaimed;
  final String? activeBossBattleWorldId;
  final Map<String, int> bossBattleMistakes;
  final Map<String, int> liveOpsClaims;
  final String? lastRandomEventId;
  final bool autoClickerActive;
  final double autoClickerSpeed;
  final int botTotalGuesses;
  final int botCorrectGuesses;
  final int botIncorrectGuesses;
  final int botActionSequence;
  final int? lastBotGuess;
  final String? lastBotFeedback;
  final String? lastBotId;
  final int lastSaveTimestamp;
  final int timeTravelPenaltyUntil;

  static const initial = LegacySystemsState();

  LegacySystemsState copyWith({
    AdaptiveTraitProfile? adaptiveTraitProfile,
    Set<String>? discoveredTraits,
    Map<String, String>? selectedTraitArms,
    Set<String>? activeMutators,
    Set<String>? talents,
    Set<String>? relicInventory,
    Set<String>? equippedRelics,
    int? homeBaseLevel,
    String? dailyQuestDate,
    int? dailyQuestGuesses,
    int? dailyQuestCorrectGuesses,
    int? dailyQuestBestStreak,
    int? dailyQuestUpgradePurchases,
    Set<String>? claimedDailyQuests,
    String? lastDailyRewardDate,
    int? dailyRewardStreak,
    Map<String, int>? lootChests,
    int? lootDropsFound,
    int? lootChestsOpened,
    String? lastLootDropTier,
    bool clearLastLootDropTier = false,
    int? lootEventId,
    Set<String>? completedChallenges,
    Map<String, int>? worldMasteryLevels,
    Set<String>? discoveredSecrets,
    Set<String>? codexEntries,
    String? activeWorldId,
    Set<String>? unlockedWorldIds,
    int? endlessRiftTier,
    int? endlessRiftBestTier,
    bool? endlessRiftActive,
    int? worldBossVictories,
    int? stakesPlaced,
    int? stakesWon,
    int? stakesLost,
    List<String>? musicLibrary,
    List<String>? musicQueue,
    Map<String, List<String>>? musicPlaylists,
    String? musicRepeatMode,
    bool? musicShuffle,
    String? currentTrackId,
    bool clearCurrentTrack = false,
    int? permanentEventBoosts,
    Set<String>? endgameRewardsClaimed,
    bool? codexRewardClaimed,
    String? activeBossBattleWorldId,
    bool clearActiveBossBattle = false,
    Map<String, int>? bossBattleMistakes,
    Map<String, int>? liveOpsClaims,
    String? lastRandomEventId,
    bool clearLastRandomEvent = false,
    bool? autoClickerActive,
    double? autoClickerSpeed,
    int? botTotalGuesses,
    int? botCorrectGuesses,
    int? botIncorrectGuesses,
    int? botActionSequence,
    int? lastBotGuess,
    bool clearLastBotGuess = false,
    String? lastBotFeedback,
    bool clearLastBotFeedback = false,
    String? lastBotId,
    bool clearLastBotId = false,
    int? lastSaveTimestamp,
    int? timeTravelPenaltyUntil,
  }) => LegacySystemsState(
    adaptiveTraitProfile: adaptiveTraitProfile ?? this.adaptiveTraitProfile,
    discoveredTraits: discoveredTraits ?? this.discoveredTraits,
    selectedTraitArms: selectedTraitArms ?? this.selectedTraitArms,
    activeMutators: activeMutators ?? this.activeMutators,
    talents: talents ?? this.talents,
    relicInventory: relicInventory ?? this.relicInventory,
    equippedRelics: equippedRelics ?? this.equippedRelics,
    homeBaseLevel: homeBaseLevel ?? this.homeBaseLevel,
    dailyQuestDate: dailyQuestDate ?? this.dailyQuestDate,
    dailyQuestGuesses: dailyQuestGuesses ?? this.dailyQuestGuesses,
    dailyQuestCorrectGuesses: dailyQuestCorrectGuesses ?? this.dailyQuestCorrectGuesses,
    dailyQuestBestStreak: dailyQuestBestStreak ?? this.dailyQuestBestStreak,
    dailyQuestUpgradePurchases: dailyQuestUpgradePurchases ?? this.dailyQuestUpgradePurchases,
    claimedDailyQuests: claimedDailyQuests ?? this.claimedDailyQuests,
    lastDailyRewardDate: lastDailyRewardDate ?? this.lastDailyRewardDate,
    dailyRewardStreak: dailyRewardStreak ?? this.dailyRewardStreak,
    lootChests: lootChests ?? this.lootChests,
    lootDropsFound: lootDropsFound ?? this.lootDropsFound,
    lootChestsOpened: lootChestsOpened ?? this.lootChestsOpened,
    lastLootDropTier: clearLastLootDropTier ? null : lastLootDropTier ?? this.lastLootDropTier,
    lootEventId: lootEventId ?? this.lootEventId,
    completedChallenges: completedChallenges ?? this.completedChallenges,
    worldMasteryLevels: worldMasteryLevels ?? this.worldMasteryLevels,
    discoveredSecrets: discoveredSecrets ?? this.discoveredSecrets,
    codexEntries: codexEntries ?? this.codexEntries,
    activeWorldId: activeWorldId ?? this.activeWorldId,
    unlockedWorldIds: unlockedWorldIds ?? this.unlockedWorldIds,
    endlessRiftTier: endlessRiftTier ?? this.endlessRiftTier,
    endlessRiftBestTier: endlessRiftBestTier ?? this.endlessRiftBestTier,
    endlessRiftActive: endlessRiftActive ?? this.endlessRiftActive,
    worldBossVictories: worldBossVictories ?? this.worldBossVictories,
    stakesPlaced: stakesPlaced ?? this.stakesPlaced,
    stakesWon: stakesWon ?? this.stakesWon,
    stakesLost: stakesLost ?? this.stakesLost,
    musicLibrary: musicLibrary ?? this.musicLibrary,
    musicQueue: musicQueue ?? this.musicQueue,
    musicPlaylists: musicPlaylists ?? this.musicPlaylists,
    musicRepeatMode: musicRepeatMode ?? this.musicRepeatMode,
    musicShuffle: musicShuffle ?? this.musicShuffle,
    currentTrackId: clearCurrentTrack ? null : currentTrackId ?? this.currentTrackId,
    permanentEventBoosts: permanentEventBoosts ?? this.permanentEventBoosts,
    endgameRewardsClaimed: endgameRewardsClaimed ?? this.endgameRewardsClaimed,
    codexRewardClaimed: codexRewardClaimed ?? this.codexRewardClaimed,
    activeBossBattleWorldId: clearActiveBossBattle ? null : activeBossBattleWorldId ?? this.activeBossBattleWorldId,
    bossBattleMistakes: bossBattleMistakes ?? this.bossBattleMistakes,
    liveOpsClaims: liveOpsClaims ?? this.liveOpsClaims,
    lastRandomEventId: clearLastRandomEvent ? null : lastRandomEventId ?? this.lastRandomEventId,
    autoClickerActive: autoClickerActive ?? this.autoClickerActive,
    autoClickerSpeed: autoClickerSpeed ?? this.autoClickerSpeed,
    botTotalGuesses: botTotalGuesses ?? this.botTotalGuesses,
    botCorrectGuesses: botCorrectGuesses ?? this.botCorrectGuesses,
    botIncorrectGuesses: botIncorrectGuesses ?? this.botIncorrectGuesses,
    botActionSequence: botActionSequence ?? this.botActionSequence,
    lastBotGuess: clearLastBotGuess ? null : lastBotGuess ?? this.lastBotGuess,
    lastBotFeedback: clearLastBotFeedback ? null : lastBotFeedback ?? this.lastBotFeedback,
    lastBotId: clearLastBotId ? null : lastBotId ?? this.lastBotId,
    lastSaveTimestamp: lastSaveTimestamp ?? this.lastSaveTimestamp,
    timeTravelPenaltyUntil: timeTravelPenaltyUntil ?? this.timeTravelPenaltyUntil,
  );

  Map<String, Object?> toJson() => {
    'adaptiveTraitProfile': adaptiveTraitProfile.toJson(),
    'discoveredTraits': discoveredTraits.toList()..sort(),
    'selectedTraitArms': selectedTraitArms,
    'activeMutators': activeMutators.toList()..sort(),
    'talents': talents.toList()..sort(),
    'relicInventory': relicInventory.toList()..sort(),
    'equippedRelics': equippedRelics.toList()..sort(),
    'homeBaseLevel': homeBaseLevel,
    'dailyQuestDate': dailyQuestDate,
    'dailyQuestGuesses': dailyQuestGuesses,
    'dailyQuestCorrectGuesses': dailyQuestCorrectGuesses,
    'dailyQuestBestStreak': dailyQuestBestStreak,
    'dailyQuestUpgradePurchases': dailyQuestUpgradePurchases,
    'claimedDailyQuests': claimedDailyQuests.toList()..sort(),
    'lastDailyRewardDate': lastDailyRewardDate,
    'dailyRewardStreak': dailyRewardStreak,
    'lootChests': lootChests,
    'lootDropsFound': lootDropsFound,
    'lootChestsOpened': lootChestsOpened,
    'lastLootDropTier': lastLootDropTier,
    'lootEventId': lootEventId,
    'completedChallenges': completedChallenges.toList()..sort(),
    'worldMasteryLevels': worldMasteryLevels,
    'discoveredSecrets': discoveredSecrets.toList()..sort(),
    'codexEntries': codexEntries.toList()..sort(),
    'activeWorldId': activeWorldId,
    'unlockedWorldIds': unlockedWorldIds.toList(),
    'endlessRiftTier': endlessRiftTier,
    'endlessRiftBestTier': endlessRiftBestTier,
    'endlessRiftActive': endlessRiftActive,
    'worldBossVictories': worldBossVictories,
    'stakesPlaced': stakesPlaced,
    'stakesWon': stakesWon,
    'stakesLost': stakesLost,
    'musicLibrary': musicLibrary,
    'musicQueue': musicQueue,
    'musicPlaylists': musicPlaylists,
    'musicRepeatMode': musicRepeatMode,
    'musicShuffle': musicShuffle,
    'currentTrackId': currentTrackId,
    'permanentEventBoosts': permanentEventBoosts,
    'endgameRewardsClaimed': endgameRewardsClaimed.toList()..sort(),
    'codexRewardClaimed': codexRewardClaimed,
    'activeBossBattleWorldId': activeBossBattleWorldId,
    'bossBattleMistakes': bossBattleMistakes,
    'liveOpsClaims': liveOpsClaims,
    'lastRandomEventId': lastRandomEventId,
    'autoClickerActive': autoClickerActive,
    'autoClickerSpeed': autoClickerSpeed,
    'botTotalGuesses': botTotalGuesses,
    'botCorrectGuesses': botCorrectGuesses,
    'botIncorrectGuesses': botIncorrectGuesses,
    'botActionSequence': botActionSequence,
    'lastBotGuess': lastBotGuess,
    'lastBotFeedback': lastBotFeedback,
    'lastBotId': lastBotId,
    'lastSaveTimestamp': lastSaveTimestamp,
    'timeTravelPenaltyUntil': timeTravelPenaltyUntil,
  };

  factory LegacySystemsState.fromJson(Map<String, dynamic> json) {
    Set<String> strings(String key) {
      final value = json[key];
      if (value == null) return const {};
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('Invalid legacy save list: $key');
      }
      return Set.unmodifiable(value.cast<String>());
    }

    Map<String, int> intMap(String key, {Map<String, int> fallback = const {}}) {
      final value = json[key];
      if (value == null) return fallback;
      if (value is! Map) throw FormatException('Invalid legacy save map: $key');
      final result = <String, int>{};
      for (final entry in value.entries) {
        if (entry.key is! String || entry.value is! int || (entry.value as int) < 0) {
          throw FormatException('Invalid legacy save map entry: $key');
        }
        result[entry.key as String] = entry.value as int;
      }
      return Map.unmodifiable(result);
    }

    int count(String key, {int fallback = 0}) {
      final value = json[key] ?? fallback;
      if (value is! int || value < 0) throw FormatException('Invalid legacy save count: $key');
      return value;
    }

    String string(String key, {String fallback = ''}) {
      final value = json[key] ?? fallback;
      if (value is! String) throw FormatException('Invalid legacy save value: $key');
      return value;
    }

    final rawArms = json['selectedTraitArms'];
    final arms = <String, String>{};
    if (rawArms != null) {
      if (rawArms is! Map) throw const FormatException('Invalid selected trait arms.');
      for (final entry in rawArms.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw const FormatException('Invalid selected trait arm entry.');
        }
        arms[entry.key as String] = entry.value as String;
      }
    }
    final rawPlaylists = json['musicPlaylists'];
    final playlists = <String, List<String>>{};
    if (rawPlaylists != null) {
      if (rawPlaylists is! Map) throw const FormatException('Invalid music playlists.');
      for (final entry in rawPlaylists.entries) {
        final value = entry.value;
        if (entry.key is! String || value is! List || value.any((item) => item is! String)) {
          throw const FormatException('Invalid music playlist entry.');
        }
        playlists[entry.key as String] = List.unmodifiable(value.cast<String>());
      }
    }
    List<String> paths(String key) {
      final value = json[key] ?? const <String>[];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('Invalid music path list: $key');
      }
      return List.unmodifiable(value.cast<String>());
    }

    final chests = intMap('lootChests', fallback: const {'common': 0, 'rare': 0, 'epic': 0});
    if (chests.keys.any((key) => !{'common', 'rare', 'epic'}.contains(key))) {
      throw const FormatException('Unknown loot chest tier.');
    }
    final repeat = string('musicRepeatMode', fallback: 'off');
    if (!{'off', 'one', 'all'}.contains(repeat)) throw const FormatException('Invalid music repeat mode.');
    final shuffle = json['musicShuffle'] ?? false;
    final endless = json['endlessRiftActive'] ?? false;
    if (shuffle is! bool || endless is! bool) throw const FormatException('Invalid legacy boolean.');
    final currentTrack = json['currentTrackId'];
    final lastLootTier = json['lastLootDropTier'];
    if (lastLootTier != null && !{'common', 'rare', 'epic'}.contains(lastLootTier)) {
      throw const FormatException('Invalid last loot drop tier.');
    }
    final codexClaimed = json['codexRewardClaimed'] ?? false;
    final autoActive = json['autoClickerActive'] ?? false;
    final autoSpeed = json['autoClickerSpeed'] ?? 1.0;
    final activeBoss = json['activeBossBattleWorldId'];
    final lastEvent = json['lastRandomEventId'];
    final lastBotGuess = json['lastBotGuess'];
    final lastBotFeedback = json['lastBotFeedback'];
    final lastBotId = json['lastBotId'];
    if ((lastBotGuess != null && (lastBotGuess is! int || lastBotGuess < 1 || lastBotGuess > 500)) ||
        (lastBotFeedback != null && !{'TOO_LOW', 'TOO_HIGH', 'CORRECT'}.contains(lastBotFeedback)) ||
        (lastBotId != null && !{'auto_clicker_basic', 'bot_byte', 'bot_pixel'}.contains(lastBotId))) {
      throw const FormatException('Invalid bot team state.');
    }
    if (codexClaimed is! bool || autoActive is! bool || autoSpeed is! num ||
        !autoSpeed.isFinite || autoSpeed < 1 || autoSpeed > 5 ||
        (activeBoss != null && activeBoss is! String) ||
        (lastEvent != null && lastEvent is! String)) {
      throw const FormatException('Invalid extended legacy state.');
    }
    if (currentTrack != null && currentTrack is! String) throw const FormatException('Invalid current music track.');
    final rawAdaptiveProfile = json['adaptiveTraitProfile'];
    if (rawAdaptiveProfile != null && rawAdaptiveProfile is! Map) {
      throw const FormatException('Invalid adaptive trait profile.');
    }
    final state = LegacySystemsState(
      adaptiveTraitProfile: rawAdaptiveProfile == null
          ? const AdaptiveTraitProfile()
          : AdaptiveTraitProfile.fromJson(Map<String, dynamic>.from(rawAdaptiveProfile as Map)),
      discoveredTraits: strings('discoveredTraits'),
      selectedTraitArms: Map.unmodifiable(arms),
      activeMutators: strings('activeMutators'),
      talents: strings('talents'),
      relicInventory: strings('relicInventory'),
      equippedRelics: strings('equippedRelics'),
      homeBaseLevel: count('homeBaseLevel'),
      dailyQuestDate: string('dailyQuestDate'),
      dailyQuestGuesses: count('dailyQuestGuesses'),
      dailyQuestCorrectGuesses: count('dailyQuestCorrectGuesses'),
      dailyQuestBestStreak: count('dailyQuestBestStreak'),
      dailyQuestUpgradePurchases: count('dailyQuestUpgradePurchases'),
      claimedDailyQuests: strings('claimedDailyQuests'),
      lastDailyRewardDate: string('lastDailyRewardDate'),
      dailyRewardStreak: count('dailyRewardStreak'),
      lootChests: chests,
      lootDropsFound: count('lootDropsFound'),
      lootChestsOpened: count('lootChestsOpened'),
      lastLootDropTier: lastLootTier as String?,
      lootEventId: count('lootEventId'),
      completedChallenges: strings('completedChallenges'),
      worldMasteryLevels: intMap('worldMasteryLevels'),
      discoveredSecrets: strings('discoveredSecrets'),
      codexEntries: strings('codexEntries'),
      activeWorldId: string('activeWorldId', fallback: 'verdant_grove'),
      unlockedWorldIds: json['unlockedWorldIds'] == null
          ? const {'verdant_grove'} : strings('unlockedWorldIds'),
      endlessRiftTier: count('endlessRiftTier'),
      endlessRiftBestTier: count('endlessRiftBestTier'),
      endlessRiftActive: endless,
      worldBossVictories: json['worldBossVictories'] == null ? 0 : count('worldBossVictories'),
      stakesPlaced: count('stakesPlaced'),
      stakesWon: count('stakesWon'),
      stakesLost: count('stakesLost'),
      musicLibrary: paths('musicLibrary'),
      musicQueue: paths('musicQueue'),
      musicPlaylists: Map.unmodifiable(playlists),
      musicRepeatMode: repeat,
      musicShuffle: shuffle,
      currentTrackId: currentTrack as String?,
      permanentEventBoosts: count('permanentEventBoosts'),
      endgameRewardsClaimed: strings('endgameRewardsClaimed'),
      codexRewardClaimed: codexClaimed,
      activeBossBattleWorldId: activeBoss as String?,
      bossBattleMistakes: intMap('bossBattleMistakes'),
      liveOpsClaims: intMap('liveOpsClaims'),
      lastRandomEventId: lastEvent as String?,
      autoClickerActive: autoActive,
      autoClickerSpeed: autoSpeed.toDouble(),
      botTotalGuesses: count('botTotalGuesses'),
      botCorrectGuesses: count('botCorrectGuesses'),
      botIncorrectGuesses: count('botIncorrectGuesses'),
      botActionSequence: count('botActionSequence'),
      lastBotGuess: lastBotGuess as int?,
      lastBotFeedback: lastBotFeedback as String?,
      lastBotId: lastBotId as String?,
      lastSaveTimestamp: count('lastSaveTimestamp'),
      timeTravelPenaltyUntil: count('timeTravelPenaltyUntil'),
    );
    if (state.homeBaseLevel > 20 || state.permanentEventBoosts > 25 || state.equippedRelics.length > 4 ||
        state.stakesWon + state.stakesLost > state.stakesPlaced ||
        state.dailyQuestCorrectGuesses > state.dailyQuestGuesses ||
        state.dailyRewardStreak > 7 ||
        state.botCorrectGuesses + state.botIncorrectGuesses > state.botTotalGuesses) {
      throw const FormatException('Legacy save invariants failed.');
    }
    if (!state.relicInventory.containsAll(state.equippedRelics)) {
      throw const FormatException('Equipped relic is not owned.');
    }
    if (!state.musicLibrary.toSet().containsAll(state.musicQueue) ||
        state.musicPlaylists.values.any((list) => !state.musicLibrary.toSet().containsAll(list))) {
      throw const FormatException('Music queue or playlist references a missing track.');
    }
    return state;
  }
}

/// Bounded, inspectable trait effects from the 320-entry GTN 1 catalog.
class TraitEffectSummary {
  const TraitEffectSummary({
    this.xpMultiplier = 1,
    this.nebulaBonusPerClaim = 0,
    this.streakProtection = false,
    this.correctGuessMultiplier = 1,
    this.missPenaltyRefundRate = 0,
    this.riskMissPenaltyRate = 0,
    this.rangeHint = false,
    this.activeTraitIds = const {},
    this.discoveredHiddenTraitIds = const {},
  });
  final double xpMultiplier;
  final int nebulaBonusPerClaim;
  final bool streakProtection;
  final double correctGuessMultiplier;
  final double missPenaltyRefundRate;
  final double riskMissPenaltyRate;
  final bool rangeHint;
  final Set<String> activeTraitIds;
  final Set<String> discoveredHiddenTraitIds;
}
