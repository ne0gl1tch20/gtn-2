import '../legacy/legacy_systems_state.dart';
import '../numbers/big_number.dart';

const Set<String> _randomEventSaveIds = {
  'cash_burst',
  'nebula_rain',
  'jackpot',
  'streak_surge',
  'range_shuffle',
  'tax_refund',
  'cosmic_gift',
};

class ProgressionState {
  ProgressionState({
    BigNumber? money,
    BigNumber? prestige,
    BigNumber? ultra,
    BigNumber? nebula,
    this.upgrades = const {},
    this.prestigeUpgrades = const {},
    this.ultraUpgrades = const {},
    this.nebulaItems = const {},
    this.bossDamage = const {},
    this.defeatedBosses = const {},
    this.prestigeResets = 0,
    this.ultraResets = 0,
    this.totalGuesses = 0,
    this.correctGuesses = 0,
    BigNumber? moneyEarned,
    BigNumber? moneySpent,
    this.randomEventsTriggered = 0,
    this.lastRandomEventId,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.playtimeSeconds = 0,
    this.achievements = const {},
    BigNumber? nebulaEarned,
    LegacySystemsState? legacySystems,
  }) : money = money ?? BigNumber.fromInt(0),
       prestige = prestige ?? BigNumber.fromInt(0),
       ultra = ultra ?? BigNumber.fromInt(0),
       nebula = nebula ?? BigNumber.fromInt(0),
       moneyEarned = moneyEarned ?? BigNumber.fromInt(0),
       moneySpent = moneySpent ?? BigNumber.fromInt(0),
       nebulaEarned = nebulaEarned ?? BigNumber.fromInt(0),
       legacySystems = legacySystems ?? LegacySystemsState.initial;

  final BigNumber money, prestige, ultra, nebula;
  final Map<String, int> upgrades,
      prestigeUpgrades,
      ultraUpgrades,
      nebulaItems,
      bossDamage;
  final Set<String> defeatedBosses;
  final int prestigeResets, ultraResets, totalGuesses, correctGuesses;
  final BigNumber moneyEarned, moneySpent;
  final int randomEventsTriggered;
  final String? lastRandomEventId;
  final int currentStreak, bestStreak, playtimeSeconds;
  final Set<String> achievements;
  final BigNumber nebulaEarned;
  final LegacySystemsState legacySystems;

  static final initial = ProgressionState();

  Map<String, Object> toJson() => {
    'money': money.toString(),
    'prestige': prestige.toString(),
    'ultra': ultra.toString(),
    'nebula': nebula.toString(),
    'upgrades': upgrades,
    'prestigeUpgrades': prestigeUpgrades,
    'ultraUpgrades': ultraUpgrades,
    'nebulaItems': nebulaItems,
    'bossDamage': bossDamage,
    'defeatedBosses': defeatedBosses.toList(),
    'prestigeResets': prestigeResets,
    'ultraResets': ultraResets,
    'totalGuesses': totalGuesses,
    'correctGuesses': correctGuesses,
    'moneyEarned': moneyEarned.toString(),
    'moneySpent': moneySpent.toString(),
    'randomEventsTriggered': randomEventsTriggered,
    if (lastRandomEventId != null) 'lastRandomEventId': lastRandomEventId!,
    'currentStreak': currentStreak,
    'bestStreak': bestStreak,
    'playtimeSeconds': playtimeSeconds,
    'achievements': achievements.toList()..sort(),
    'nebulaEarned': nebulaEarned.toString(),
    'legacySystems': legacySystems.toJson(),
  };

  factory ProgressionState.fromJson(Map<String, dynamic> json) {
    BigNumber number(String key) {
      final value = json[key];
      if (value is! String) throw FormatException('Invalid currency: $key');
      final parsed = BigNumber.parse(value);
      if (parsed.compareTo(BigNumber.fromInt(0)) < 0) {
        throw FormatException('Negative currency: $key');
      }
      return parsed;
    }

    BigNumber optionalNumber(String key) =>
        json[key] == null ? BigNumber.fromInt(0) : number(key);

    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) {
        throw FormatException('Invalid statistic: $key');
      }
      return value;
    }

    int optionalCount(String key) => json[key] == null ? 0 : count(key);

    Map<String, int> levels(String key, {bool optional = false}) {
      final value = json[key];
      if (value == null && optional) return const {};
      if (value is! Map) throw FormatException('Invalid upgrade map: $key');
      final result = <String, int>{};
      for (final entry in value.entries) {
        if (entry.key is! String ||
            entry.value is! int ||
            (entry.value as int) < 0) {
          throw FormatException('Invalid upgrade level: $key');
        }
        result[entry.key as String] = entry.value as int;
      }
      return Map.unmodifiable(result);
    }

    final rawLegacy = json['legacySystems'];
    final legacySystems = rawLegacy == null
        ? LegacySystemsState.initial.copyWith(worldUnlockMigrationPending: true)
        : rawLegacy is Map<String, dynamic>
        ? LegacySystemsState.fromJson(rawLegacy)
        : throw const FormatException('Invalid legacy systems save.');

    final rawBossDamage = json['bossDamage'];
    final bossDamage = <String, int>{};
    if (rawBossDamage != null) {
      if (rawBossDamage is! Map) {
        throw const FormatException('Invalid boss damage map.');
      }
      for (final entry in rawBossDamage.entries) {
        if (entry.key is! String ||
            entry.value is! int ||
            (entry.value as int) < 0) {
          throw const FormatException('Invalid boss damage entry.');
        }
        bossDamage[entry.key as String] = entry.value as int;
      }
    }
    final rawDefeated = json['defeatedBosses'];
    final defeatedBosses = <String>{};
    if (rawDefeated != null) {
      if (rawDefeated is! List ||
          rawDefeated.any((value) => value is! String)) {
        throw const FormatException('Invalid defeated boss list.');
      }
      defeatedBosses.addAll(rawDefeated.cast<String>());
    }

    final rawAchievements = json['achievements'];
    final achievements = <String>{};
    if (rawAchievements != null) {
      if (rawAchievements is! List ||
          rawAchievements.any((value) => value is! String || value.isEmpty)) {
        throw const FormatException('Invalid achievement list.');
      }
      achievements.addAll(rawAchievements.cast<String>());
    }
    final rawLastRandomEventId = json['lastRandomEventId'];
    if (rawLastRandomEventId != null &&
        (rawLastRandomEventId is! String ||
            !_randomEventSaveIds.contains(rawLastRandomEventId))) {
      throw const FormatException('Invalid random event ID.');
    }
    final total = count('totalGuesses');
    final correct = count('correctGuesses');
    final streak = count('currentStreak');
    final best = count('bestStreak');
    if (correct > total || best < streak) {
      throw const FormatException('Inconsistent progression statistics.');
    }
    return ProgressionState(
      money: number('money'),
      prestige: number('prestige'),
      ultra: number('ultra'),
      nebula: number('nebula'),
      upgrades: levels('upgrades'),
      prestigeUpgrades: levels('prestigeUpgrades'),
      ultraUpgrades: levels('ultraUpgrades'),
      nebulaItems: levels('nebulaItems', optional: true),
      bossDamage: Map.unmodifiable(bossDamage),
      defeatedBosses: Set.unmodifiable(defeatedBosses),
      prestigeResets: count('prestigeResets'),
      ultraResets: count('ultraResets'),
      totalGuesses: total,
      correctGuesses: correct,
      moneyEarned: number('moneyEarned'),
      moneySpent: optionalNumber('moneySpent'),
      randomEventsTriggered: optionalCount('randomEventsTriggered'),
      lastRandomEventId: rawLastRandomEventId as String?,
      currentStreak: streak,
      bestStreak: best,
      playtimeSeconds: json['playtimeSeconds'] == null
          ? 0
          : count('playtimeSeconds'),
      achievements: Set.unmodifiable(achievements),
      nebulaEarned: number('nebulaEarned'),
      legacySystems: legacySystems,
    );
  }

  ProgressionState copyWith({
    BigNumber? money,
    BigNumber? prestige,
    BigNumber? ultra,
    BigNumber? nebula,
    Map<String, int>? upgrades,
    Map<String, int>? prestigeUpgrades,
    Map<String, int>? ultraUpgrades,
    Map<String, int>? nebulaItems,
    Map<String, int>? bossDamage,
    Set<String>? defeatedBosses,
    int? prestigeResets,
    int? ultraResets,
    int? totalGuesses,
    int? correctGuesses,
    BigNumber? moneyEarned,
    BigNumber? moneySpent,
    int? randomEventsTriggered,
    String? lastRandomEventId,
    bool clearLastRandomEventId = false,
    int? currentStreak,
    int? bestStreak,
    int? playtimeSeconds,
    Set<String>? achievements,
    BigNumber? nebulaEarned,
    LegacySystemsState? legacySystems,
  }) => ProgressionState(
    money: money ?? this.money,
    prestige: prestige ?? this.prestige,
    ultra: ultra ?? this.ultra,
    nebula: nebula ?? this.nebula,
    upgrades: upgrades ?? this.upgrades,
    prestigeUpgrades: prestigeUpgrades ?? this.prestigeUpgrades,
    ultraUpgrades: ultraUpgrades ?? this.ultraUpgrades,
    nebulaItems: nebulaItems ?? this.nebulaItems,
    bossDamage: bossDamage ?? this.bossDamage,
    defeatedBosses: defeatedBosses ?? this.defeatedBosses,
    prestigeResets: prestigeResets ?? this.prestigeResets,
    ultraResets: ultraResets ?? this.ultraResets,
    totalGuesses: totalGuesses ?? this.totalGuesses,
    correctGuesses: correctGuesses ?? this.correctGuesses,
    moneyEarned: moneyEarned ?? this.moneyEarned,
    moneySpent: moneySpent ?? this.moneySpent,
    randomEventsTriggered: randomEventsTriggered ?? this.randomEventsTriggered,
    lastRandomEventId: clearLastRandomEventId
        ? null
        : lastRandomEventId ?? this.lastRandomEventId,
    currentStreak: currentStreak ?? this.currentStreak,
    bestStreak: bestStreak ?? this.bestStreak,
    playtimeSeconds: playtimeSeconds ?? this.playtimeSeconds,
    achievements: achievements ?? this.achievements,
    nebulaEarned: nebulaEarned ?? this.nebulaEarned,
    legacySystems: legacySystems ?? this.legacySystems,
  );
}
