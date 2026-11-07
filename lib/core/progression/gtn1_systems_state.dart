import '../numbers/big_number.dart';

/// Persistent state for the GTN 1 systems that were absent from the first Flutter port.
/// All rewards and unlocks are calculated by Dart code, never trusted from UI payloads.
class TraitProfileState {
  const TraitProfileState({
    this.totalGuessesObserved = 0,
    this.correctGuessesObserved = 0,
    this.failedGuessesObserved = 0,
    this.longStreaksObserved = 0,
    this.prestigesObserved = 0,
    this.ultrasObserved = 0,
    this.upgradesPurchasedObserved = 0,
    this.consistencyScore = 0,
    this.accuracyScore = 0,
    this.riskScore = 0,
    this.persistenceScore = 0,
    this.progressionScore = 0,
    this.moneyEarnedObserved,
    this.helperUses = const {},
    this.helperCooldowns = const {},
    this.awardedBonuses = const {},
  });

  final int totalGuessesObserved;
  final int correctGuessesObserved;
  final int failedGuessesObserved;
  final int longStreaksObserved;
  final int prestigesObserved;
  final int ultrasObserved;
  final int upgradesPurchasedObserved;
  final double consistencyScore;
  final double accuracyScore;
  final double riskScore;
  final double persistenceScore;
  final double progressionScore;
  final BigNumber? moneyEarnedObserved;
  final Map<String, int> helperUses;
  final Map<String, int> helperCooldowns;
  final Set<String> awardedBonuses;

  Map<String, Object?> toJson() => {
    'totalGuessesObserved': totalGuessesObserved,
    'correctGuessesObserved': correctGuessesObserved,
    'failedGuessesObserved': failedGuessesObserved,
    'longStreaksObserved': longStreaksObserved,
    'prestigesObserved': prestigesObserved,
    'ultrasObserved': ultrasObserved,
    'upgradesPurchasedObserved': upgradesPurchasedObserved,
    'consistencyScore': consistencyScore,
    'accuracyScore': accuracyScore,
    'riskScore': riskScore,
    'persistenceScore': persistenceScore,
    'progressionScore': progressionScore,
    'moneyEarnedObserved': (moneyEarnedObserved ?? BigNumber.fromInt(0)).toString(),
    'helperUses': helperUses,
    'helperCooldowns': helperCooldowns,
    'awardedBonuses': awardedBonuses.toList(),
  };

  factory TraitProfileState.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key] ?? 0;
      if (value is! int || value < 0) throw FormatException('Invalid trait profile counter: $key');
      return value;
    }
    double score(String key) {
      final value = json[key] ?? 0;
      if (value is! num || !value.isFinite || value < 0 || value > 1) {
        throw FormatException('Invalid trait profile score: $key');
      }
      return value.toDouble();
    }
    Map<String, int> counters(String key) {
      final value = json[key] ?? const <String, dynamic>{};
      if (value is! Map) throw FormatException('Invalid trait profile map: $key');
      final result = <String, int>{};
      for (final entry in value.entries) {
        if (entry.key is! String || entry.value is! int || entry.value < 0) {
          throw FormatException('Invalid trait profile entry: $key');
        }
        result[entry.key as String] = entry.value as int;
      }
      return Map.unmodifiable(result);
    }
    Set<String> ids(String key) {
      final value = json[key] ?? const <dynamic>[];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('Invalid trait profile IDs: $key');
      }
      return Set.unmodifiable(value.cast<String>());
    }
    final rawMoney = json['moneyEarnedObserved'] ?? '0';
    if (rawMoney is! String) throw const FormatException('Invalid trait profile money.');
    return TraitProfileState(
      totalGuessesObserved: count('totalGuessesObserved'),
      correctGuessesObserved: count('correctGuessesObserved'),
      failedGuessesObserved: count('failedGuessesObserved'),
      longStreaksObserved: count('longStreaksObserved'),
      prestigesObserved: count('prestigesObserved'),
      ultrasObserved: count('ultrasObserved'),
      upgradesPurchasedObserved: count('upgradesPurchasedObserved'),
      consistencyScore: score('consistencyScore'),
      accuracyScore: score('accuracyScore'),
      riskScore: score('riskScore'),
      persistenceScore: score('persistenceScore'),
      progressionScore: score('progressionScore'),
      moneyEarnedObserved: BigNumber.parse(rawMoney),
      helperUses: counters('helperUses'),
      helperCooldowns: counters('helperCooldowns'),
      awardedBonuses: ids('awardedBonuses'),
    );
  }
}

class Gtn1SystemsState {
  const Gtn1SystemsState({
    this.activeMutators = const {},
    this.unlockedTalents = const {},
    this.discoveredTraits = const {},
    this.selectedTraitArms = const {},
    this.traitProfile = const TraitProfileState(),
    this.relicInventory = const {},
    this.equippedRelics = const {},
    this.homeBaseLevel = 0,
    this.activeWorldId = 'verdant_grove',
    this.unlockedWorldIds = const {'verdant_grove'},
    this.worldMasteryLevels = const {},
    this.discoveredSecrets = const {},
    this.codexEntries = const {},
    this.codexRewardClaimed = false,
    this.endgameRewardsClaimed = const {},
    this.endlessRiftTier = 0,
    this.endlessRiftBestTier = 0,
    this.endlessRiftActive = false,
    this.dailyQuestDate = '',
    this.dailyQuestGuesses = 0,
    this.dailyQuestCorrectGuesses = 0,
    this.dailyQuestBestStreak = 0,
    this.dailyQuestUpgradePurchases = 0,
    this.claimedDailyQuests = const {},
    this.lastDailyRewardDate = '',
    this.dailyRewardStreak = 0,
    this.lootCommonChests = 0,
    this.lootRareChests = 0,
    this.lootEpicChests = 0,
    this.lootDropsFound = 0,
    this.lootChestsOpened = 0,
    this.lastLootDropTier,
    this.lootEventId = 0,
    this.achievements = const {},
    this.completedChallenges = const {},
    this.liveOpsClaims = const {},
    this.permanentEventBoosts = 0,
    this.lastRandomEventId,
    this.stakeWins = 0,
    this.stakeLosses = 0,
    this.stakeMoneyWagered,
    this.stakeMoneyWon,
    this.profileName = '',
    this.profileIconId = 'default',
    this.ownedCosmetics = const {},
    this.equippedCosmeticId,
    this.creativeModeEnabled = false,
    this.creativeRangeMin = 1,
    this.creativeRangeMax = 100,
    this.creativeAttemptLimit = 0,
    this.creativeRewardMultiplier = 1,
    this.autoClickerActive = false,
    this.autoClickerSpeed = 1,
    this.botLevels = const {},
    this.botTotalGuesses = 0,
    this.botCorrectGuesses = 0,
    this.botIncorrectGuesses = 0,
    this.playtimeSeconds = 0,
    this.randomEventsTriggered = 0,
  });

  final Set<String> activeMutators;
  final Set<String> unlockedTalents;
  final Set<String> discoveredTraits;
  final Map<String, String> selectedTraitArms;
  final TraitProfileState traitProfile;
  final Set<String> relicInventory;
  final Set<String> equippedRelics;
  final int homeBaseLevel;
  final String activeWorldId;
  final Set<String> unlockedWorldIds;
  final Map<String, int> worldMasteryLevels;
  final Set<String> discoveredSecrets;
  final Set<String> codexEntries;
  final bool codexRewardClaimed;
  final Set<String> endgameRewardsClaimed;
  final int endlessRiftTier;
  final int endlessRiftBestTier;
  final bool endlessRiftActive;
  final String dailyQuestDate;
  final int dailyQuestGuesses;
  final int dailyQuestCorrectGuesses;
  final int dailyQuestBestStreak;
  final int dailyQuestUpgradePurchases;
  final Set<String> claimedDailyQuests;
  final String lastDailyRewardDate;
  final int dailyRewardStreak;
  final int lootCommonChests;
  final int lootRareChests;
  final int lootEpicChests;
  final int lootDropsFound;
  final int lootChestsOpened;
  final String? lastLootDropTier;
  final int lootEventId;
  final Set<String> achievements;
  final Set<String> completedChallenges;
  final Map<String, int> liveOpsClaims;
  final int permanentEventBoosts;
  final String? lastRandomEventId;
  final int stakeWins;
  final int stakeLosses;
  final BigNumber? stakeMoneyWagered;
  final BigNumber? stakeMoneyWon;
  final String profileName;
  final String profileIconId;
  final Set<String> ownedCosmetics;
  final String? equippedCosmeticId;
  final bool creativeModeEnabled;
  final int creativeRangeMin;
  final int creativeRangeMax;
  final int creativeAttemptLimit;
  final int creativeRewardMultiplier;
  final bool autoClickerActive;
  final double autoClickerSpeed;
  final Map<String, int> botLevels;
  final int botTotalGuesses;
  final int botCorrectGuesses;
  final int botIncorrectGuesses;
  final int playtimeSeconds;
  final int randomEventsTriggered;

  Gtn1SystemsState copyWith({
    Set<String>? activeMutators,
    Set<String>? unlockedTalents,
    Set<String>? discoveredTraits,
    Map<String, String>? selectedTraitArms,
    TraitProfileState? traitProfile,
    Set<String>? relicInventory,
    Set<String>? equippedRelics,
    int? homeBaseLevel,
    String? activeWorldId,
    Set<String>? unlockedWorldIds,
    Map<String, int>? worldMasteryLevels,
    Set<String>? discoveredSecrets,
    Set<String>? codexEntries,
    bool? codexRewardClaimed,
    Set<String>? endgameRewardsClaimed,
    int? endlessRiftTier,
    int? endlessRiftBestTier,
    bool? endlessRiftActive,
    String? dailyQuestDate,
    int? dailyQuestGuesses,
    int? dailyQuestCorrectGuesses,
    int? dailyQuestBestStreak,
    int? dailyQuestUpgradePurchases,
    Set<String>? claimedDailyQuests,
    String? lastDailyRewardDate,
    int? dailyRewardStreak,
    int? lootCommonChests,
    int? lootRareChests,
    int? lootEpicChests,
    int? lootDropsFound,
    int? lootChestsOpened,
    String? lastLootDropTier,
    int? lootEventId,
    Set<String>? achievements,
    Set<String>? completedChallenges,
    Map<String, int>? liveOpsClaims,
    int? permanentEventBoosts,
    String? lastRandomEventId,
    int? stakeWins,
    int? stakeLosses,
    BigNumber? stakeMoneyWagered,
    BigNumber? stakeMoneyWon,
    String? profileName,
    String? profileIconId,
    Set<String>? ownedCosmetics,
    String? equippedCosmeticId,
    bool? creativeModeEnabled,
    int? creativeRangeMin,
    int? creativeRangeMax,
    int? creativeAttemptLimit,
    int? creativeRewardMultiplier,
    bool? autoClickerActive,
    double? autoClickerSpeed,
    Map<String, int>? botLevels,
    int? botTotalGuesses,
    int? botCorrectGuesses,
    int? botIncorrectGuesses,
    int? playtimeSeconds,
    int? randomEventsTriggered,
  }) => Gtn1SystemsState(
    activeMutators: activeMutators ?? this.activeMutators,
    unlockedTalents: unlockedTalents ?? this.unlockedTalents,
    discoveredTraits: discoveredTraits ?? this.discoveredTraits,
    selectedTraitArms: selectedTraitArms ?? this.selectedTraitArms,
    traitProfile: traitProfile ?? this.traitProfile,
    relicInventory: relicInventory ?? this.relicInventory,
    equippedRelics: equippedRelics ?? this.equippedRelics,
    homeBaseLevel: homeBaseLevel ?? this.homeBaseLevel,
    activeWorldId: activeWorldId ?? this.activeWorldId,
    unlockedWorldIds: unlockedWorldIds ?? this.unlockedWorldIds,
    worldMasteryLevels: worldMasteryLevels ?? this.worldMasteryLevels,
    discoveredSecrets: discoveredSecrets ?? this.discoveredSecrets,
    codexEntries: codexEntries ?? this.codexEntries,
    codexRewardClaimed: codexRewardClaimed ?? this.codexRewardClaimed,
    endgameRewardsClaimed: endgameRewardsClaimed ?? this.endgameRewardsClaimed,
    endlessRiftTier: endlessRiftTier ?? this.endlessRiftTier,
    endlessRiftBestTier: endlessRiftBestTier ?? this.endlessRiftBestTier,
    endlessRiftActive: endlessRiftActive ?? this.endlessRiftActive,
    dailyQuestDate: dailyQuestDate ?? this.dailyQuestDate,
    dailyQuestGuesses: dailyQuestGuesses ?? this.dailyQuestGuesses,
    dailyQuestCorrectGuesses: dailyQuestCorrectGuesses ?? this.dailyQuestCorrectGuesses,
    dailyQuestBestStreak: dailyQuestBestStreak ?? this.dailyQuestBestStreak,
    dailyQuestUpgradePurchases: dailyQuestUpgradePurchases ?? this.dailyQuestUpgradePurchases,
    claimedDailyQuests: claimedDailyQuests ?? this.claimedDailyQuests,
    lastDailyRewardDate: lastDailyRewardDate ?? this.lastDailyRewardDate,
    dailyRewardStreak: dailyRewardStreak ?? this.dailyRewardStreak,
    lootCommonChests: lootCommonChests ?? this.lootCommonChests,
    lootRareChests: lootRareChests ?? this.lootRareChests,
    lootEpicChests: lootEpicChests ?? this.lootEpicChests,
    lootDropsFound: lootDropsFound ?? this.lootDropsFound,
    lootChestsOpened: lootChestsOpened ?? this.lootChestsOpened,
    lastLootDropTier: lastLootDropTier ?? this.lastLootDropTier,
    lootEventId: lootEventId ?? this.lootEventId,
    achievements: achievements ?? this.achievements,
    completedChallenges: completedChallenges ?? this.completedChallenges,
    liveOpsClaims: liveOpsClaims ?? this.liveOpsClaims,
    permanentEventBoosts: permanentEventBoosts ?? this.permanentEventBoosts,
    lastRandomEventId: lastRandomEventId ?? this.lastRandomEventId,
    stakeWins: stakeWins ?? this.stakeWins,
    stakeLosses: stakeLosses ?? this.stakeLosses,
    stakeMoneyWagered: stakeMoneyWagered ?? this.stakeMoneyWagered,
    stakeMoneyWon: stakeMoneyWon ?? this.stakeMoneyWon,
    profileName: profileName ?? this.profileName,
    profileIconId: profileIconId ?? this.profileIconId,
    ownedCosmetics: ownedCosmetics ?? this.ownedCosmetics,
    equippedCosmeticId: equippedCosmeticId ?? this.equippedCosmeticId,
    creativeModeEnabled: creativeModeEnabled ?? this.creativeModeEnabled,
    creativeRangeMin: creativeRangeMin ?? this.creativeRangeMin,
    creativeRangeMax: creativeRangeMax ?? this.creativeRangeMax,
    creativeAttemptLimit: creativeAttemptLimit ?? this.creativeAttemptLimit,
    creativeRewardMultiplier: creativeRewardMultiplier ?? this.creativeRewardMultiplier,
    autoClickerActive: autoClickerActive ?? this.autoClickerActive,
    autoClickerSpeed: autoClickerSpeed ?? this.autoClickerSpeed,
    botLevels: botLevels ?? this.botLevels,
    botTotalGuesses: botTotalGuesses ?? this.botTotalGuesses,
    botCorrectGuesses: botCorrectGuesses ?? this.botCorrectGuesses,
    botIncorrectGuesses: botIncorrectGuesses ?? this.botIncorrectGuesses,
    playtimeSeconds: playtimeSeconds ?? this.playtimeSeconds,
    randomEventsTriggered: randomEventsTriggered ?? this.randomEventsTriggered,
  );

  Map<String, Object?> toJson() => {
    'activeMutators': activeMutators.toList(),
    'unlockedTalents': unlockedTalents.toList(),
    'discoveredTraits': discoveredTraits.toList(),
    'selectedTraitArms': selectedTraitArms,
    'traitProfile': traitProfile.toJson(),
    'relicInventory': relicInventory.toList(),
    'equippedRelics': equippedRelics.toList(),
    'homeBaseLevel': homeBaseLevel,
    'activeWorldId': activeWorldId,
    'unlockedWorldIds': unlockedWorldIds.toList(),
    'worldMasteryLevels': worldMasteryLevels,
    'discoveredSecrets': discoveredSecrets.toList(),
    'codexEntries': codexEntries.toList(),
    'codexRewardClaimed': codexRewardClaimed,
    'endgameRewardsClaimed': endgameRewardsClaimed.toList(),
    'endlessRiftTier': endlessRiftTier,
    'endlessRiftBestTier': endlessRiftBestTier,
    'endlessRiftActive': endlessRiftActive,
    'dailyQuestDate': dailyQuestDate,
    'dailyQuestGuesses': dailyQuestGuesses,
    'dailyQuestCorrectGuesses': dailyQuestCorrectGuesses,
    'dailyQuestBestStreak': dailyQuestBestStreak,
    'dailyQuestUpgradePurchases': dailyQuestUpgradePurchases,
    'claimedDailyQuests': claimedDailyQuests.toList(),
    'lastDailyRewardDate': lastDailyRewardDate,
    'dailyRewardStreak': dailyRewardStreak,
    'lootCommonChests': lootCommonChests,
    'lootRareChests': lootRareChests,
    'lootEpicChests': lootEpicChests,
    'lootDropsFound': lootDropsFound,
    'lootChestsOpened': lootChestsOpened,
    'lastLootDropTier': lastLootDropTier,
    'lootEventId': lootEventId,
    'achievements': achievements.toList(),
    'completedChallenges': completedChallenges.toList(),
    'liveOpsClaims': liveOpsClaims,
    'permanentEventBoosts': permanentEventBoosts,
    'lastRandomEventId': lastRandomEventId,
    'stakeWins': stakeWins,
    'stakeLosses': stakeLosses,
    'stakeMoneyWagered': (stakeMoneyWagered ?? BigNumber.fromInt(0)).toString(),
    'stakeMoneyWon': (stakeMoneyWon ?? BigNumber.fromInt(0)).toString(),
    'profileName': profileName,
    'profileIconId': profileIconId,
    'ownedCosmetics': ownedCosmetics.toList(),
    'equippedCosmeticId': equippedCosmeticId,
    'creativeModeEnabled': creativeModeEnabled,
    'creativeRangeMin': creativeRangeMin,
    'creativeRangeMax': creativeRangeMax,
    'creativeAttemptLimit': creativeAttemptLimit,
    'creativeRewardMultiplier': creativeRewardMultiplier,
    'autoClickerActive': autoClickerActive,
    'autoClickerSpeed': autoClickerSpeed,
    'botLevels': botLevels,
    'botTotalGuesses': botTotalGuesses,
    'botCorrectGuesses': botCorrectGuesses,
    'botIncorrectGuesses': botIncorrectGuesses,
    'playtimeSeconds': playtimeSeconds,
    'randomEventsTriggered': randomEventsTriggered,
  };

  factory Gtn1SystemsState.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key] ?? 0;
      if (value is! int || value < 0) throw FormatException('Invalid systems counter: $key');
      return value;
    }
    bool flag(String key) {
      final value = json[key] ?? false;
      if (value is! bool) throw FormatException('Invalid systems flag: $key');
      return value;
    }
    String string(String key, String fallback) {
      final value = json[key] ?? fallback;
      if (value is! String) throw FormatException('Invalid systems string: $key');
      return value;
    }
    Set<String> ids(String key, {Set<String> fallback = const {}}) {
      final value = json[key] ?? fallback.toList();
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('Invalid systems IDs: $key');
      }
      return Set.unmodifiable(value.cast<String>());
    }
    Map<String, int> counters(String key) {
      final value = json[key] ?? const <String, dynamic>{};
      if (value is! Map) throw FormatException('Invalid systems map: $key');
      final result = <String, int>{};
      for (final entry in value.entries) {
        if (entry.key is! String || entry.value is! int || entry.value < 0) {
          throw FormatException('Invalid systems map entry: $key');
        }
        result[entry.key as String] = entry.value as int;
      }
      return Map.unmodifiable(result);
    }
    Map<String, String> strings(String key) {
      final value = json[key] ?? const <String, dynamic>{};
      if (value is! Map) throw FormatException('Invalid systems map: $key');
      final result = <String, String>{};
      for (final entry in value.entries) {
        if (entry.key is! String || entry.value is! String) {
          throw FormatException('Invalid systems map entry: $key');
        }
        result[entry.key as String] = entry.value as String;
      }
      return Map.unmodifiable(result);
    }
    double decimal(String key, double fallback) {
      final value = json[key] ?? fallback;
      if (value is! num || !value.isFinite || value < 0) {
        throw FormatException('Invalid systems decimal: $key');
      }
      return value.toDouble();
    }
    BigNumber currency(String key) {
      final value = json[key] ?? '0';
      if (value is! String) throw FormatException('Invalid systems currency: $key');
      final parsed = BigNumber.parse(value);
      if (parsed.compareTo(BigNumber.fromInt(0)) < 0) throw FormatException('Negative systems currency: $key');
      return parsed;
    }
    final rawArms = strings('selectedTraitArms');
    final rawTraitProfile = json['traitProfile'];
    if (rawTraitProfile != null && rawTraitProfile is! Map<String, dynamic>) {
      throw const FormatException('Invalid trait profile.');
    }
    final minimum = count('creativeRangeMin');
    final maximum = (json['creativeRangeMax'] ?? 100) as int;
    if (minimum < 1 || maximum < minimum || maximum > 1000000) {
      throw const FormatException('Invalid creative range.');
    }
    final speed = decimal('autoClickerSpeed', 1);
    if (speed > 1000) throw const FormatException('Invalid auto-clicker speed.');
    return Gtn1SystemsState(
      activeMutators: ids('activeMutators'),
      unlockedTalents: ids('unlockedTalents'),
      discoveredTraits: ids('discoveredTraits'),
      selectedTraitArms: rawArms,
      traitProfile: rawTraitProfile == null ? const TraitProfileState() : TraitProfileState.fromJson(rawTraitProfile),
      relicInventory: ids('relicInventory'),
      equippedRelics: ids('equippedRelics'),
      homeBaseLevel: count('homeBaseLevel').clamp(0, 20),
      activeWorldId: string('activeWorldId', 'verdant_grove'),
      unlockedWorldIds: ids('unlockedWorldIds', fallback: const {'verdant_grove'}),
      worldMasteryLevels: counters('worldMasteryLevels'),
      discoveredSecrets: ids('discoveredSecrets'),
      codexEntries: ids('codexEntries'),
      codexRewardClaimed: flag('codexRewardClaimed'),
      endgameRewardsClaimed: ids('endgameRewardsClaimed'),
      endlessRiftTier: count('endlessRiftTier'),
      endlessRiftBestTier: count('endlessRiftBestTier'),
      endlessRiftActive: flag('endlessRiftActive'),
      dailyQuestDate: string('dailyQuestDate', ''),
      dailyQuestGuesses: count('dailyQuestGuesses'),
      dailyQuestCorrectGuesses: count('dailyQuestCorrectGuesses'),
      dailyQuestBestStreak: count('dailyQuestBestStreak'),
      dailyQuestUpgradePurchases: count('dailyQuestUpgradePurchases'),
      claimedDailyQuests: ids('claimedDailyQuests'),
      lastDailyRewardDate: string('lastDailyRewardDate', ''),
      dailyRewardStreak: count('dailyRewardStreak').clamp(0, 7),
      lootCommonChests: count('lootCommonChests'),
      lootRareChests: count('lootRareChests'),
      lootEpicChests: count('lootEpicChests'),
      lootDropsFound: count('lootDropsFound'),
      lootChestsOpened: count('lootChestsOpened'),
      lastLootDropTier: json['lastLootDropTier'] as String?,
      lootEventId: count('lootEventId'),
      achievements: ids('achievements'),
      completedChallenges: ids('completedChallenges'),
      liveOpsClaims: counters('liveOpsClaims'),
      permanentEventBoosts: count('permanentEventBoosts').clamp(0, 25),
      lastRandomEventId: json['lastRandomEventId'] as String?,
      stakeWins: count('stakeWins'),
      stakeLosses: count('stakeLosses'),
      stakeMoneyWagered: currency('stakeMoneyWagered'),
      stakeMoneyWon: currency('stakeMoneyWon'),
      profileName: string('profileName', ''),
      profileIconId: string('profileIconId', 'default'),
      ownedCosmetics: ids('ownedCosmetics'),
      equippedCosmeticId: json['equippedCosmeticId'] as String?,
      creativeModeEnabled: flag('creativeModeEnabled'),
      creativeRangeMin: minimum,
      creativeRangeMax: maximum,
      creativeAttemptLimit: count('creativeAttemptLimit'),
      creativeRewardMultiplier: count('creativeRewardMultiplier').clamp(1, 1000),
      autoClickerActive: flag('autoClickerActive'),
      autoClickerSpeed: speed,
      botLevels: counters('botLevels'),
      botTotalGuesses: count('botTotalGuesses'),
      botCorrectGuesses: count('botCorrectGuesses'),
      botIncorrectGuesses: count('botIncorrectGuesses'),
      playtimeSeconds: count('playtimeSeconds'),
      randomEventsTriggered: count('randomEventsTriggered'),
    );
  }
}
