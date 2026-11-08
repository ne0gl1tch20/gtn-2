import 'dart:convert';

import 'package:flutter/services.dart';

import '../core/numbers/big_number.dart';
import '../core/progression/progression_engine.dart';

class GameUpgrade {
  const GameUpgrade({
    required this.definition,
    required this.name,
    required this.description,
    required this.effectPerLevel,
  });

  final UpgradeDefinition definition;
  final String name;
  final String description;
  final double effectPerLevel;

  /// Only upgrades with a verified, wired GTN1 gameplay effect appear in the shop.
  bool get gameplayImplemented =>
      definition.id == 'reward_multiplier' || definition.id == 'better_range';

  String get effectDescription => switch (definition.id) {
        'reward_multiplier' => '+25% correct-guess reward per level',
        'better_range' => '-5 maximum target range per level',
        'prestige_money_boost' => '+50% Money earnings per level',
        'prestige_gain_boost' => '+20% Prestige reward per level',
        'prestige_starting_capital' => '+1,000 starting Money per level',
        'ultra_money_boost' => '+200% Money earnings per level',
        'ultra_gain_boost' => '+50% Ultra reward per level',
        'ultra_nebula_boost' => 'Nebula rewards gain +1× per level',
        _ => 'Source catalog entry; gameplay behavior is not yet ported',
      };
}

class UpgradeCatalog {
  UpgradeCatalog._();

  static List<GameUpgrade> _all = const [];
  static List<GameUpgrade> _prestige = const [];
  static List<GameUpgrade> _ultra = const [];
  static bool _loaded = false;

  static List<GameUpgrade> get all => List.unmodifiable(_all);
  static List<GameUpgrade> get prestige => List.unmodifiable(_prestige);
  static List<GameUpgrade> get ultra => List.unmodifiable(_ultra);

  static List<GameUpgrade> get availableForGameplay =>
      List.unmodifiable(_all.where((item) => item.gameplayImplemented));

  static Future<void> load() async {
    if (_loaded) return;
    Future<List<GameUpgrade>> readCatalog(String path, int expectedCount) async {
      final source = await rootBundle.loadString(path);
      final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['upgrades'] is! List) {
      throw FormatException('Unsupported GTN1 upgrade catalog: $path');
    }

    final parsed = <GameUpgrade>[];
    final ids = <String>{};
    for (final raw in decoded['upgrades'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid GTN1 upgrade definition.');
      }
      final id = raw['id'];
      final name = raw['name'];
      final description = raw['description'];
      final maxLevel = raw['maxLevel'];
      final baseCost = raw['baseCost'];
      final growthRate = raw['costMultiplier'];
      final effect = raw['effectPerLevel'];
      if (id is! String ||
          id.isEmpty ||
          !ids.add(id) ||
          name is! String ||
          description is! String ||
          maxLevel is! int ||
          maxLevel < 1 ||
          baseCost is! String ||
          growthRate is! num ||
          growthRate <= 0 ||
          effect is! num) {
        throw FormatException('Invalid or duplicate GTN1 upgrade: $id');
      }
      parsed.add(GameUpgrade(
        definition: UpgradeDefinition(
          id: id,
          baseCost: BigNumber.parse(baseCost),
          growthRate: BigNumber.parse(growthRate.toString()),
          maxLevel: maxLevel,
        ),
        name: name,
        description: description,
        effectPerLevel: effect.toDouble(),
      ));
    }
    if (parsed.length != expectedCount) {
      throw FormatException('Expected $expectedCount GTN1 upgrades in $path, found ${parsed.length}.');
    }
    return List.unmodifiable(parsed);
    }

    final normal = await readCatalog('assets/game/upgrades.json', 11);
    final prestige = await readCatalog('assets/game/prestige_upgrades.json', 3);
    final ultra = await readCatalog('assets/game/ultra_upgrades.json', 3);
    _all = normal;
    _prestige = prestige;
    _ultra = ultra;
    _loaded = true;
  }

  static GameUpgrade byId(String id) =>
      _all.firstWhere((upgrade) => upgrade.definition.id == id);
}
