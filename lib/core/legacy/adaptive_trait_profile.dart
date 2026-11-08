import '../numbers/big_number.dart';

/// Save-backed behavioral memory for GTN1's invisible/adaptive trait system.
class AdaptiveTraitProfile {
  const AdaptiveTraitProfile({
    this.schemaVersion = 1,
    this.totalGuessesObserved = 0,
    this.correctGuessesObserved = 0,
    this.failedGuessesObserved = 0,
    this.closeMissesObserved = 0,
    this.longStreaksObserved = 0,
    this.sessionsObserved = 0,
    this.prestigesObserved = 0,
    this.ultrasObserved = 0,
    this.upgradesPurchasedObserved = 0,
    this.moneyEarnedObserved = '0',
    this.moneySpentObserved = '0',
    this.consistencyScore = 0,
    this.accuracyScore = 0,
    this.riskScore = 0,
    this.persistenceScore = 0,
    this.progressionScore = 0,
    this.helperUses = const {},
    this.helperCooldowns = const {},
    this.awardedBonuses = const {},
  });

  final int schemaVersion;
  final int totalGuessesObserved;
  final int correctGuessesObserved;
  final int failedGuessesObserved;
  final int closeMissesObserved;
  final int longStreaksObserved;
  final int sessionsObserved;
  final int prestigesObserved;
  final int ultrasObserved;
  final int upgradesPurchasedObserved;
  final String moneyEarnedObserved;
  final String moneySpentObserved;
  final double consistencyScore;
  final double accuracyScore;
  final double riskScore;
  final double persistenceScore;
  final double progressionScore;
  final Map<String, int> helperUses;
  final Map<String, int> helperCooldowns;
  final Set<String> awardedBonuses;

  AdaptiveTraitProfile copyWith({
    int? totalGuessesObserved,
    int? correctGuessesObserved,
    int? failedGuessesObserved,
    int? closeMissesObserved,
    int? longStreaksObserved,
    int? sessionsObserved,
    int? prestigesObserved,
    int? ultrasObserved,
    int? upgradesPurchasedObserved,
    String? moneyEarnedObserved,
    String? moneySpentObserved,
    double? consistencyScore,
    double? accuracyScore,
    double? riskScore,
    double? persistenceScore,
    double? progressionScore,
    Map<String, int>? helperUses,
    Map<String, int>? helperCooldowns,
    Set<String>? awardedBonuses,
  }) => AdaptiveTraitProfile(
    schemaVersion: schemaVersion,
    totalGuessesObserved: totalGuessesObserved ?? this.totalGuessesObserved,
    correctGuessesObserved: correctGuessesObserved ?? this.correctGuessesObserved,
    failedGuessesObserved: failedGuessesObserved ?? this.failedGuessesObserved,
    closeMissesObserved: closeMissesObserved ?? this.closeMissesObserved,
    longStreaksObserved: longStreaksObserved ?? this.longStreaksObserved,
    sessionsObserved: sessionsObserved ?? this.sessionsObserved,
    prestigesObserved: prestigesObserved ?? this.prestigesObserved,
    ultrasObserved: ultrasObserved ?? this.ultrasObserved,
    upgradesPurchasedObserved: upgradesPurchasedObserved ?? this.upgradesPurchasedObserved,
    moneyEarnedObserved: moneyEarnedObserved ?? this.moneyEarnedObserved,
    moneySpentObserved: moneySpentObserved ?? this.moneySpentObserved,
    consistencyScore: consistencyScore ?? this.consistencyScore,
    accuracyScore: accuracyScore ?? this.accuracyScore,
    riskScore: riskScore ?? this.riskScore,
    persistenceScore: persistenceScore ?? this.persistenceScore,
    progressionScore: progressionScore ?? this.progressionScore,
    helperUses: helperUses ?? this.helperUses,
    helperCooldowns: helperCooldowns ?? this.helperCooldowns,
    awardedBonuses: awardedBonuses ?? this.awardedBonuses,
  );

  Map<String, Object?> toJson() => {
    'schemaVersion': schemaVersion,
    'totalGuessesObserved': totalGuessesObserved,
    'correctGuessesObserved': correctGuessesObserved,
    'failedGuessesObserved': failedGuessesObserved,
    'closeMissesObserved': closeMissesObserved,
    'longStreaksObserved': longStreaksObserved,
    'sessionsObserved': sessionsObserved,
    'prestigesObserved': prestigesObserved,
    'ultrasObserved': ultrasObserved,
    'upgradesPurchasedObserved': upgradesPurchasedObserved,
    'moneyEarnedObserved': moneyEarnedObserved,
    'moneySpentObserved': moneySpentObserved,
    'consistencyScore': consistencyScore,
    'accuracyScore': accuracyScore,
    'riskScore': riskScore,
    'persistenceScore': persistenceScore,
    'progressionScore': progressionScore,
    'helperUses': helperUses,
    'helperCooldowns': helperCooldowns,
    'awardedBonuses': awardedBonuses.toList()..sort(),
  };

  factory AdaptiveTraitProfile.fromJson(Map<String, dynamic> json) {
    int count(String key) {
      final value = json[key] ?? 0;
      if (value is! int || value < 0) {
        throw FormatException('Invalid adaptive trait profile count: $key');
      }
      return value;
    }

    double score(String key) {
      final value = json[key] ?? 0.0;
      if (value is! num || !value.isFinite || value < 0 || value > 1) {
        throw FormatException('Invalid adaptive trait profile score: $key');
      }
      return value.toDouble();
    }

    Map<String, int> counters(String key) {
      final value = json[key] ?? const <String, dynamic>{};
      if (value is! Map) throw FormatException('Invalid adaptive trait profile map: $key');
      final result = <String, int>{};
      for (final entry in value.entries) {
        if (entry.key is! String || entry.value is! int || (entry.value as int) < 0) {
          throw FormatException('Invalid adaptive trait profile entry: $key');
        }
        result[entry.key as String] = entry.value as int;
      }
      if (result.length > 64) throw FormatException('Adaptive trait profile map is too large: $key');
      return Map.unmodifiable(result);
    }

    Set<String> strings(String key) {
      final value = json[key] ?? const <String>[];
      if (value is! List || value.any((item) => item is! String)) {
        throw FormatException('Invalid adaptive trait profile set: $key');
      }
      if (value.length > 64) throw FormatException('Adaptive trait profile set is too large: $key');
      return Set.unmodifiable(value.cast<String>());
    }

    final version = count('schemaVersion');
    if (version != 1) throw const FormatException('Unsupported adaptive trait profile version.');
    final earned = json['moneyEarnedObserved'] ?? '0';
    final spent = json['moneySpentObserved'] ?? '0';
    if (earned is! String || spent is! String) {
      throw const FormatException('Invalid adaptive trait profile currency.');
    }
    BigNumber.parse(earned);
    BigNumber.parse(spent);
    return AdaptiveTraitProfile(
      schemaVersion: version,
      totalGuessesObserved: count('totalGuessesObserved'),
      correctGuessesObserved: count('correctGuessesObserved'),
      failedGuessesObserved: count('failedGuessesObserved'),
      closeMissesObserved: count('closeMissesObserved'),
      longStreaksObserved: count('longStreaksObserved'),
      sessionsObserved: count('sessionsObserved'),
      prestigesObserved: count('prestigesObserved'),
      ultrasObserved: count('ultrasObserved'),
      upgradesPurchasedObserved: count('upgradesPurchasedObserved'),
      moneyEarnedObserved: earned,
      moneySpentObserved: spent,
      consistencyScore: score('consistencyScore'),
      accuracyScore: score('accuracyScore'),
      riskScore: score('riskScore'),
      persistenceScore: score('persistenceScore'),
      progressionScore: score('progressionScore'),
      helperUses: counters('helperUses'),
      helperCooldowns: counters('helperCooldowns'),
      awardedBonuses: strings('awardedBonuses'),
    );
  }
}
