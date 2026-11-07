import '../numbers/big_number.dart';

class ProgressionState {
  const ProgressionState({
    this.money = const BigNumber.zero(),
    this.prestige = const BigNumber.zero(),
    this.ultra = const BigNumber.zero(),
    this.nebula = const BigNumber.zero(),
    this.upgrades = const {},
    this.prestigeUpgrades = const {},
    this.ultraUpgrades = const {},
    this.prestigeResets = 0,
    this.ultraResets = 0,
    this.totalGuesses = 0,
    this.correctGuesses = 0,
    this.moneyEarned = const BigNumber.zero(),
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.nebulaEarned = const BigNumber.zero(),
  });

  final BigNumber money, prestige, ultra, nebula;
  final Map<String, int> upgrades, prestigeUpgrades, ultraUpgrades;
  final int prestigeResets, ultraResets, totalGuesses, correctGuesses;
  final BigNumber moneyEarned;
  final int currentStreak, bestStreak;
  final BigNumber nebulaEarned;

  static const initial = ProgressionState();

  Map<String, Object> toJson() => {
        'money': money.toString(),
        'prestige': prestige.toString(),
        'ultra': ultra.toString(),
        'nebula': nebula.toString(),
        'upgrades': upgrades,
        'prestigeUpgrades': prestigeUpgrades,
        'ultraUpgrades': ultraUpgrades,
        'prestigeResets': prestigeResets,
        'ultraResets': ultraResets,
        'totalGuesses': totalGuesses,
        'correctGuesses': correctGuesses,
        'moneyEarned': moneyEarned.toString(),
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'nebulaEarned': nebulaEarned.toString(),
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

    int count(String key) {
      final value = json[key];
      if (value is! int || value < 0) {
        throw FormatException('Invalid statistic: $key');
      }
      return value;
    }

    Map<String, int> levels(String key) {
      final value = json[key];
      if (value is! Map) throw FormatException('Invalid upgrade map: $key');
      final result = <String, int>{};
      for (final entry in value.entries) {
        if (entry.key is! String || entry.value is! int ||
            (entry.value as int) < 0) {
          throw FormatException('Invalid upgrade level: $key');
        }
        result[entry.key as String] = entry.value as int;
      }
      return Map.unmodifiable(result);
    }

    final total = count('totalGuesses');
    final correct = count('correctGuesses');
    final streak = count('currentStreak');
    final best = count('bestStreak');
    if (correct > total || streak > correct || best < streak) {
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
      prestigeResets: count('prestigeResets'),
      ultraResets: count('ultraResets'),
      totalGuesses: total,
      correctGuesses: correct,
      moneyEarned: number('moneyEarned'),
      currentStreak: streak,
      bestStreak: best,
      nebulaEarned: number('nebulaEarned'),
    );
  }

  ProgressionState copyWith({
    BigNumber? money, BigNumber? prestige, BigNumber? ultra, BigNumber? nebula,
    Map<String, int>? upgrades, Map<String, int>? prestigeUpgrades,
    Map<String, int>? ultraUpgrades, int? prestigeResets, int? ultraResets,
    int? totalGuesses, int? correctGuesses, BigNumber? moneyEarned,
    int? currentStreak, int? bestStreak, BigNumber? nebulaEarned,
  }) => ProgressionState(
    money: money ?? this.money,
    prestige: prestige ?? this.prestige,
    ultra: ultra ?? this.ultra,
    nebula: nebula ?? this.nebula,
    upgrades: upgrades ?? this.upgrades,
    prestigeUpgrades: prestigeUpgrades ?? this.prestigeUpgrades,
    ultraUpgrades: ultraUpgrades ?? this.ultraUpgrades,
    prestigeResets: prestigeResets ?? this.prestigeResets,
    ultraResets: ultraResets ?? this.ultraResets,
    totalGuesses: totalGuesses ?? this.totalGuesses,
    correctGuesses: correctGuesses ?? this.correctGuesses,
    moneyEarned: moneyEarned ?? this.moneyEarned,
    currentStreak: currentStreak ?? this.currentStreak,
    bestStreak: bestStreak ?? this.bestStreak,
    nebulaEarned: nebulaEarned ?? this.nebulaEarned,
  );
}
