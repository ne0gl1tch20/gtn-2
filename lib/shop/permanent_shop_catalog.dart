import 'dart:convert';

import 'package:flutter/services.dart';

class PermanentShopItem {
  const PermanentShopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
  });

  final String id;
  final String name;
  final String description;
  final int cost;
}

class PermanentShopCatalog {
  PermanentShopCatalog._();

  static List<PermanentShopItem> _prestige = const [];
  static List<PermanentShopItem> _ultra = const [];
  static bool _loaded = false;

  static List<PermanentShopItem> get prestige =>
      List.unmodifiable(_prestige);
  static List<PermanentShopItem> get ultra => List.unmodifiable(_ultra);

  static Future<void> load() async {
    if (_loaded) return;

    Future<List<PermanentShopItem>> read(String path, int expectedCount) async {
      final source = await rootBundle.loadString(path);
      final decoded = jsonDecode(source);
      if (decoded is! Map<String, dynamic> ||
          decoded['schemaVersion'] != 1 ||
          decoded['shopItems'] is! List) {
        throw FormatException('Unsupported GTN1 permanent shop catalog: $path');
      }

      final items = <PermanentShopItem>[];
      final ids = <String>{};
      for (final raw in decoded['shopItems'] as List) {
        if (raw is! Map<String, dynamic>) {
          throw const FormatException('Invalid GTN1 permanent shop item.');
        }
        final id = raw['id'];
        final name = raw['name'];
        final description = raw['description'];
        final cost = raw['cost'];
        if (id is! String ||
            id.isEmpty ||
            !ids.add(id) ||
            name is! String ||
            description is! String ||
            cost is! int ||
            cost <= 0) {
          throw FormatException('Invalid or duplicate permanent shop item: $id');
        }
        items.add(PermanentShopItem(
          id: id,
          name: name,
          description: description,
          cost: cost,
        ));
      }
      if (items.length != expectedCount) {
        throw FormatException(
          'Expected $expectedCount permanent shop items in $path, '
          'found ${items.length}.',
        );
      }
      return List.unmodifiable(items);
    }

    final prestige = await read('assets/game/prestige_shop.json', 2);
    final ultra = await read('assets/game/ultra_shop.json', 3);
    _prestige = prestige;
    _ultra = ultra;
    _loaded = true;
  }
}
