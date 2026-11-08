import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/trait_catalog_repository.dart';

void main() {
  test('loads all 320 source-backed trait definitions and package metadata', () async {
    final assets = <String, String>{};
    final entries = <Map<String, Object?>>[];
    for (var index = 0; index < 320; index++) {
      final id = 'trait_$index';
      final package = 'catalogs/test/$id';
      final definitionPath = '$package/trait.json';
      final rulesPath = '$package/rules.json';
      final localizationPath = '$package/locales/en.json';
      final iconPath = '$package/icon.svg';
      entries.add({
        'id': id,
        'catalogId': 'test',
        'packageFolder': id,
        'category': 'PROGRESSION',
        'visibility': 'VISIBLE',
        'definitionPath': definitionPath,
        'rulesPath': rulesPath,
        'localizationPath': localizationPath,
        'iconPath': iconPath,
      });
      assets['assets/gtn1/traits/$definitionPath'] = jsonEncode({
        'id': id,
        'effects': ['COSMETIC_BADGE'],
        'seasonId': null,
      });
      assets['assets/gtn1/traits/$rulesPath'] = jsonEncode({
        'id': id,
        'activation': {
          'minimumLevel': 1,
          'minimumPrestige': 0,
          'minimumCorrectGuesses': index,
        },
        'dependencies': <String>[],
        'conflicts': <String>[],
      });
      assets['assets/gtn1/traits/$localizationPath'] = jsonEncode({
        'id': id,
        'title': 'Trait $index',
        'description': 'Description $index',
      });
    }
    assets[TraitCatalogRepository.manifestAsset] = jsonEncode({
      'schemaVersion': 1,
      'sourceCommit': TraitCatalogRepository.sourceCommit,
      'traitCount': 320,
      'traits': entries,
    });

    final catalog = await TraitCatalogRepository(
      loadAsset: (path) async => assets[path]!,
    ).load();

    expect(catalog, hasLength(320));
    expect(catalog.first.id, 'trait_0');
    expect(catalog.first.title, 'Trait 0');
    expect(catalog.last.minimumCorrectGuesses, 319);
    expect(catalog.first.effects, contains('COSMETIC_BADGE'));
    expect(catalog.first.iconAssetPath, 'assets/gtn1/traits/catalogs/test/trait_0/icon.svg');
  });

  test('rejects a trait package that tries to escape the bundled asset root', () async {
    final entries = List.generate(320, (index) => <String, Object?>{
      'id': 'trait_$index',
      'catalogId': 'test',
      'packageFolder': 'trait_$index',
      'category': 'PROGRESSION',
      'visibility': 'VISIBLE',
      'definitionPath': '../outside.json',
      'rulesPath': 'catalogs/test/rules.json',
      'localizationPath': 'catalogs/test/locales/en.json',
      'iconPath': 'catalogs/test/icon.svg',
    });
    final assets = <String, String>{
      TraitCatalogRepository.manifestAsset: jsonEncode({
        'schemaVersion': 1,
        'sourceCommit': TraitCatalogRepository.sourceCommit,
        'traitCount': 320,
        'traits': entries,
      }),
    };
    await expectLater(
      TraitCatalogRepository(loadAsset: (path) async => assets[path]!).load(),
      throwsFormatException,
    );
  });

  test('rejects a manifest from a different GTN1 revision', () async {
    final assets = <String, String>{
      TraitCatalogRepository.manifestAsset: jsonEncode({
        'schemaVersion': 1,
        'sourceCommit': '0' * 40,
        'traitCount': 320,
        'traits': List.filled(320, <String, Object?>{}),
      }),
    };
    await expectLater(
      TraitCatalogRepository(loadAsset: (path) async => assets[path]!).load(),
      throwsFormatException,
    );
  });
}
