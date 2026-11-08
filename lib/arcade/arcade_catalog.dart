import 'dart:convert';

import 'package:flutter/services.dart';

class ArcadeGameDefinition {
  const ArcadeGameDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.rewardMultiplier,
  });

  final String id;
  final String name;
  final String description;
  final double rewardMultiplier;
}

class ArcadeCatalog {
  ArcadeCatalog._();

  static const assetPath = 'assets/game/minigames.json';
  static const expectedIds = [
    'quick_guess',
    'reaction_test',
    'lucky_number',
    'memory_match',
    'number_rush',
    'math_blitz',
    'memory_grid',
  ];

  static Future<List<ArcadeGameDefinition>> load({
    Future<String> Function(String path)? loadAsset,
  }) async {
    final source = await (loadAsset ?? rootBundle.loadString)(assetPath);
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['minigames'] is! List) {
      throw const FormatException('Unsupported GTN1 Arcade catalog.');
    }

    final games = <ArcadeGameDefinition>[];
    final ids = <String>{};
    for (final raw in decoded['minigames'] as List) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid GTN1 minigame definition.');
      }
      final id = raw['id'];
      final name = raw['name'];
      final description = raw['description'];
      final multiplier = raw['rewardMultiplier'];
      if (id is! String ||
          id.isEmpty ||
          !ids.add(id) ||
          name is! String ||
          description is! String ||
          multiplier is! num ||
          multiplier <= 0) {
        throw FormatException('Invalid or duplicate GTN1 minigame: $id');
      }
      games.add(ArcadeGameDefinition(
        id: id,
        name: name,
        description: description,
        rewardMultiplier: multiplier.toDouble(),
      ));
    }

    if (games.length != expectedIds.length ||
        !games.map((game) => game.id).toSet().containsAll(expectedIds)) {
      throw FormatException(
        'GTN1 Arcade catalog must contain exactly ${expectedIds.length} supported games.',
      );
    }
    return List.unmodifiable(games);
  }
}
