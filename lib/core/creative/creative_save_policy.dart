import '../../data/saves/save_data.dart';
import '../../shop/upgrade_catalog.dart';
import '../numbers/big_number.dart';

/// Source-backed validation and state transformation for GTN1's active-save
/// Creative Save controls. A null result means the transaction was rejected.
class CreativeSavePolicy {
  const CreativeSavePolicy._();

  static const int maxCounter = 1000000000000;
  static const int maxStreak = 1000000;

  static SaveData? updateRange({
    required SaveData current,
    required int minimum,
    required int maximum,
  }) {
    if (!current.creativeModeEnabled ||
        minimum < 1 ||
        maximum < minimum ||
        maximum > 1000000) {
      return null;
    }

    return current.copyWith(
      secret: minimum + ((maximum - minimum) ~/ 2),
      attempts: 0,
      correctGuesses: 0,
      streak: 0,
      isComplete: false,
      minimum: minimum,
      maximum: maximum,
      progression: current.progression.copyWith(currentStreak: 0),
    );
  }

  static SaveData? updateValue({
    required SaveData current,
    required String key,
    required String value,
    required List<GameUpgrade> upgrades,
    required List<GameUpgrade> prestigeUpgrades,
    required List<GameUpgrade> ultraUpgrades,
  }) {
    if (!current.creativeModeEnabled ||
        value.isEmpty ||
        value.length > 100) {
      return null;
    }

    final progression = current.progression;
    switch (key) {
      case 'money':
      case 'prestige':
      case 'ultra':
      case 'nebula':
        final amount = _parseSourceBigNumber(value);
        if (amount == null) return null;
        return current.copyWith(
          progression: switch (key) {
            'money' => progression.copyWith(money: amount),
            'prestige' => progression.copyWith(prestige: amount),
            'ultra' => progression.copyWith(ultra: amount),
            _ => progression.copyWith(nebula: amount),
          },
        );
      case 'attempts':
        final number = int.tryParse(value);
        if (number == null ||
            number < current.correctGuesses ||
            number > maxCounter) {
          return null;
        }
        return current.copyWith(attempts: number);
      case 'correctGuesses':
        final number = int.tryParse(value);
        if (number == null || number < 0 || number > current.attempts) {
          return null;
        }
        return current.copyWith(correctGuesses: number);
      case 'streak':
        final number = int.tryParse(value);
        if (number == null || number < 0 || number > maxStreak) {
          return null;
        }
        final best = current.bestStreak < number ? number : current.bestStreak;
        return current.copyWith(
          streak: number,
          bestStreak: best,
          progression: progression.copyWith(
            currentStreak: number,
            bestStreak: best,
          ),
        );
      case 'bestStreak':
        final number = int.tryParse(value);
        if (number == null || number < current.streak || number > maxStreak) {
          return null;
        }
        return current.copyWith(
          bestStreak: number,
          progression: progression.copyWith(bestStreak: number),
        );
    }

    final separator = key.indexOf(':');
    if (separator <= 0) return null;
    final prefix = key.substring(0, separator + 1);
    final id = key.substring(separator + 1);
    final catalog = switch (prefix) {
      'upgradeLevel:' => upgrades,
      'prestigeUpgradeLevel:' => prestigeUpgrades,
      'ultraUpgradeLevel:' => ultraUpgrades,
      _ => const <GameUpgrade>[],
    };
    if (catalog.isEmpty) return null;
    GameUpgrade? definition;
    for (final upgrade in catalog) {
      if (upgrade.definition.id == id) {
        definition = upgrade;
        break;
      }
    }
    if (definition == null) return null;
    final maximumLevel = definition.definition.maxLevel;
    final level = int.tryParse(value);
    if (maximumLevel == null ||
        level == null ||
        level < 0 ||
        level > maximumLevel) {
      return null;
    }

    return current.copyWith(
      progression: switch (prefix) {
        'upgradeLevel:' => progression.copyWith(
          upgrades: {...progression.upgrades, id: level},
        ),
        'prestigeUpgradeLevel:' => progression.copyWith(
          prestigeUpgrades: {...progression.prestigeUpgrades, id: level},
        ),
        'ultraUpgradeLevel:' => progression.copyWith(
          ultraUpgrades: {...progression.ultraUpgrades, id: level},
        ),
        _ => progression,
      },
    );
  }

  static BigNumber? _parseSourceBigNumber(String input) {
    final match = RegExp(
      r'^([0-9]+(?:\.[0-9]+)?)([A-Za-z]{1,4})?$',
    ).firstMatch(input);
    if (match == null || match.group(0) != input) return null;

    final numeric = match.group(1)!;
    final suffix = match.group(2)?.toUpperCase();
    if (suffix == null) {
      return BigNumber.parse(numeric);
    }

    const exponents = <String, int>{
      'K': 3,
      'M': 6,
      'B': 9,
      'T': 12,
      'QA': 15,
      'QI': 18,
      'SX': 21,
      'SP': 24,
      'OC': 27,
      'NO': 30,
      'DC': 33,
      'UD': 36,
      'DD': 39,
      'TD': 42,
      'QAD': 45,
      'QID': 48,
      'SXD': 51,
      'SPD': 54,
      'OCD': 57,
      'NOD': 60,
      'VG': 63,
      'UVG': 66,
      'DVG': 69,
      'TVG': 72,
      'QAVG': 75,
      'QIVG': 78,
      'SXVG': 81,
      'SPVG': 84,
      'OCVG': 87,
      'NOVG': 90,
      'TG': 93,
      'VGN': 63,
    };
    final exponent = exponents[suffix];
    if (exponent == null) return BigNumber.fromInt(0);

    final decimal = BigNumber.parse(numeric);
    return BigNumber.fromParts(
      decimal.coefficient * BigInt.from(10).pow(exponent),
      decimal.scale,
    );
  }
}
