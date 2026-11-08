import 'dart:convert';

import 'package:flutter/services.dart';

typedef TraitAssetLoader = Future<String> Function(String assetPath);

class TraitCatalogEntry {
  const TraitCatalogEntry({
    required this.id,
    required this.catalogId,
    required this.packageFolder,
    required this.category,
    required this.visibility,
    required this.title,
    required this.description,
    required this.effects,
    required this.minimumLevel,
    required this.minimumPrestige,
    required this.minimumCorrectGuesses,
    required this.dependencies,
    required this.conflicts,
    required this.seasonId,
    required this.iconAssetPath,
  });

  final String id;
  final String catalogId;
  final String packageFolder;
  final String category;
  final String visibility;
  final String title;
  final String description;
  final Set<String> effects;
  final int minimumLevel;
  final int minimumPrestige;
  final int minimumCorrectGuesses;
  final Set<String> dependencies;
  final Set<String> conflicts;
  final String? seasonId;
  final String iconAssetPath;

  bool get isHidden => visibility == 'HIDDEN';
}

class TraitCatalogRepository {
  TraitCatalogRepository({TraitAssetLoader? loadAsset})
      : _loadAsset = loadAsset ?? rootBundle.loadString;

  static const manifestAsset = 'assets/gtn1/traits/catalog-manifest.json';
  static const sourceCommit = 'fe9cf567169e19059e0330d08769fe454336ef94';

  final TraitAssetLoader _loadAsset;

  Future<List<TraitCatalogEntry>> load() async {
    final manifest = _decodeObject(await _loadAsset(manifestAsset), manifestAsset);
    if (manifest['schemaVersion'] != 1 ||
        manifest['sourceCommit'] != sourceCommit ||
        manifest['traitCount'] != 320) {
      throw const FormatException(
        'GTN1 trait catalog manifest does not match the pinned source.',
      );
    }
    final rawEntries = manifest['traits'];
    if (rawEntries is! List || rawEntries.length != 320) {
      throw const FormatException(
        'GTN1 trait catalog must contain exactly 320 entries.',
      );
    }

    final ids = <String>{};
    for (final rawEntry in rawEntries) {
      if (rawEntry is! Map) {
        throw const FormatException('Invalid GTN1 trait manifest entry.');
      }
      final entry = Map<String, dynamic>.from(rawEntry);
      final id = _requiredString(entry, 'id');
      if (!ids.add(id)) throw FormatException('Duplicate GTN1 trait ID: $id');
    }

    Future<TraitCatalogEntry> parseEntry(Object? rawEntry) async {
      final entry = Map<String, dynamic>.from(rawEntry as Map);
      final id = _requiredString(entry, 'id');
      final definitionPath = _assetPath(entry, 'definitionPath');
      final rulesPath = _assetPath(entry, 'rulesPath');
      final localizationPath = _assetPath(entry, 'localizationPath');
      final iconPath = _assetPath(entry, 'iconPath');

      final packageData = await Future.wait([
        _loadAsset(definitionPath),
        _loadAsset(rulesPath),
        _loadAsset(localizationPath),
      ]);
      final definition = _decodeObject(packageData[0], definitionPath);
      final rules = _decodeObject(packageData[1], rulesPath);
      final localization = _decodeObject(packageData[2], localizationPath);
      if (definition['id'] != id ||
          rules['id'] != id ||
          localization['id'] != id ||
          definition['catalogId'] != entry['catalogId'] ||
          definition['packageFolder'] != entry['packageFolder'] ||
          definition['category'] != entry['category'] ||
          definition['visibility'] != entry['visibility']) {
        throw FormatException('GTN1 trait package identity mismatch: $id');
      }

      final activation = rules['activation'];
      if (activation is! Map) {
        throw FormatException('GTN1 trait activation rules are missing: $id');
      }
      final season = definition['seasonId'];
      if (season != null && season is! String) {
        throw FormatException('Invalid GTN1 trait season: $id');
      }

      return TraitCatalogEntry(
        id: id,
        catalogId: _requiredString(entry, 'catalogId'),
        packageFolder: _requiredString(entry, 'packageFolder'),
        category: _requiredString(entry, 'category'),
        visibility: _requiredString(entry, 'visibility'),
        title: _requiredString(localization, 'title'),
        description: _requiredString(localization, 'description'),
        effects: _stringSet(definition['effects'], 'effects', id),
        minimumLevel: _requiredInt(activation, 'minimumLevel', id),
        minimumPrestige: _requiredInt(activation, 'minimumPrestige', id),
        minimumCorrectGuesses:
            _requiredInt(activation, 'minimumCorrectGuesses', id),
        dependencies: _stringSet(rules['dependencies'], 'dependencies', id),
        conflicts: _stringSet(rules['conflicts'], 'conflicts', id),
        seasonId: season as String?,
        iconAssetPath: iconPath,
      );
    }

    // Limit concurrent asset reads so low-memory Android devices do not have to
    // decode all 960 JSON files at once.
    final result = <TraitCatalogEntry>[];
    const batchSize = 16;
    for (var start = 0; start < rawEntries.length; start += batchSize) {
      final end = (start + batchSize).clamp(0, rawEntries.length).toInt();
      final batch = rawEntries.sublist(start, end);
      result.addAll(await Future.wait(batch.map(parseEntry)));
    }
    result.sort((a, b) => a.id.compareTo(b.id));
    return List.unmodifiable(result);
  }

  static Map<String, dynamic> _decodeObject(String source, String path) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('Expected a JSON object in $path');
    }
    return decoded;
  }

  static String _requiredString(Map<dynamic, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid $key');
    }
    return value;
  }

  static int _requiredInt(Map<dynamic, dynamic> map, String key, String id) {
    final value = map[key];
    if (value is! int || value < 0) {
      throw FormatException('Invalid $key for GTN1 trait $id');
    }
    return value;
  }

  static Set<String> _stringSet(Object? value, String key, String id) {
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Invalid $key for GTN1 trait $id');
    }
    return Set.unmodifiable(value.cast<String>());
  }

  static String _assetPath(Map<String, dynamic> entry, String key) {
    final relative = _requiredString(entry, key);
    if (relative.startsWith('/') ||
        relative.contains('..') ||
        relative.contains('\\') ||
        relative.isEmpty) {
      throw FormatException('Unsafe GTN1 trait asset path: $relative');
    }
    return 'assets/gtn1/traits/$relative';
  }
}
