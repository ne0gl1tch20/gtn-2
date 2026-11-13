import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/trait_extension_runtime.dart';
import 'package:gtn_2/core/scripting/lua_sandbox.dart';

const _runtime = TraitExtensionRuntime();

void main() {
  test('Lua reads declared snapshot and returns a decision', () async {
    final extension = await _validate(
      traitId: 'remote_streak',
      modules: [
        {
          'id': 'logic',
          'type': 'LUA',
          'entrypoint': 'logic.lua',
          'capabilities': ['read_snapshot'],
        },
      ],
      files: {
        'logic.lua': '''
          local count = tonumber(gtn.input.correctGuesses or "0")
          local streak = tonumber(gtn.input.bestStreak or "0")
          return {
            eligible = count >= 100 and streak >= 10,
            effects = {"COSMETIC_BADGE"}
          }
        ''',
      },
    );

    final no = await _runtime.evaluateLua(
      extension: extension,
      moduleId: 'logic',
      snapshot: const {'correctGuesses': '200', 'bestStreak': '9'},
      allowedEffects: const {TraitEffect.cosmeticBadge},
    );
    final yes = await _runtime.evaluateLua(
      extension: extension,
      moduleId: 'logic',
      snapshot: const {'correctGuesses': '100', 'bestStreak': '10'},
      allowedEffects: const {TraitEffect.cosmeticBadge},
    );

    expect(no.eligible, isFalse);
    expect(no.requestedEffects, isEmpty);
    expect(yes.eligible, isTrue);
    expect(yes.requestedEffects, {TraitEffect.cosmeticBadge});
  });

  test('Lua rejects invalid decision shapes', () async {
    final stringDecision = await _validate(
      traitId: 'remote_streak',
      modules: [
        {'id': 'logic', 'type': 'LUA', 'entrypoint': 'logic.lua'},
      ],
      files: {
        'logic.lua': 'return { eligible = "false", effects = {} }',
      },
    );
    await expectLater(
      _runtime.evaluateLua(
        extension: stringDecision,
        moduleId: 'logic',
        snapshot: const {},
        allowedEffects: const {},
      ),
      throwsA(isA<FormatException>()),
    );

    final nonTable = await _validate(
      traitId: 'remote_streak',
      modules: [
        {'id': 'logic', 'type': 'LUA', 'entrypoint': 'logic.lua'},
      ],
      files: {'logic.lua': 'return "eligible"'},
    );
    await expectLater(
      _runtime.evaluateLua(
        extension: nonTable,
        moduleId: 'logic',
        snapshot: const {},
        allowedEffects: const {},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('Lua capabilities gate logging and snapshot reads', () async {
    final noLogging = await _validate(
      traitId: 'remote_streak',
      modules: [
        {'id': 'logic', 'type': 'LUA', 'entrypoint': 'logic.lua'},
      ],
      files: {
        'logic.lua': 'gtn.log("not allowed"); return { eligible = true }',
      },
    );
    await expectLater(
      _runtime.evaluateLua(
        extension: noLogging,
        moduleId: 'logic',
        snapshot: const {},
        allowedEffects: const {},
      ),
      throwsA(isA<LuaScriptException>()),
    );

    await expectLater(
      _runtime.evaluateLua(
        extension: noLogging,
        moduleId: 'logic',
        snapshot: const {'bestStreak': '10'},
        allowedEffects: const {},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('Lua rejects undeclared or excessive effects', () async {
    final extension = await _validate(
      traitId: 'remote_streak',
      modules: [
        {'id': 'logic', 'type': 'LUA', 'entrypoint': 'logic.lua'},
      ],
      files: {
        'logic.lua':
            'return { eligible = true, effects = {"NEBULA_BONUS"} }',
      },
    );
    await expectLater(
      _runtime.evaluateLua(
        extension: extension,
        moduleId: 'logic',
        snapshot: const {},
        allowedEffects: const {TraitEffect.cosmeticBadge},
      ),
      throwsA(isA<FormatException>()),
    );

    final tooManyEffects = await _validate(
      traitId: 'remote_streak',
      modules: [
        {'id': 'logic', 'type': 'LUA', 'entrypoint': 'logic.lua'},
      ],
      files: {
        'logic.lua': '''
          return {
            eligible = true,
            effects = {
              "XP_MULTIPLIER", "NEBULA_BONUS", "STREAK_PROTECTION",
              "COSMETIC_BADGE", "COMBO_REWARD", "RANGE_HINT",
              "MISS_PENALTY_REDUCTION", "RISK_REWARD", "XP_MULTIPLIER"
            }
          }
        ''',
      },
    );
    await expectLater(
      _runtime.evaluateLua(
        extension: tooManyEffects,
        moduleId: 'logic',
        snapshot: const {},
        allowedEffects: TraitEffect.values.toSet(),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('JSON modules are parsed as declarative objects', () async {
    final extension = await _validate(
      traitId: 'remote_rules',
      modules: [
        {
          'id': 'rules',
          'type': 'JSON',
          'entrypoint': 'rules.json',
          'capabilities': ['read_rules'],
        },
      ],
      files: {
        'rules.json':
            '{"minimumBestStreak":25,"effects":["COSMETIC_BADGE"]}',
      },
    );

    expect(
      _runtime.readJsonModule(extension, 'rules')['minimumBestStreak'],
      25,
    );
    expect(
      () => _runtime.javascriptPresentation(extension, 'rules'),
      throwsA(isA<FormatException>()),
    );
  });

  test('JavaScript presentation rejects host APIs', () async {
    const goodSource =
        "function renderTrait(api) { api.setText('status', 'Ready'); }";
    final extension = await _validate(
      traitId: 'remote_view',
      modules: [
        {
          'id': 'view',
          'type': 'JAVASCRIPT',
          'entrypoint': 'view.js',
          'capabilities': ['render_ui'],
        },
      ],
      files: {'view.js': goodSource},
    );

    expect(
      _runtime.javascriptPresentation(extension, 'view'),
      goodSource,
    );
    expect(
      () => _runtime.readJsonModule(extension, 'view'),
      throwsA(isA<FormatException>()),
    );

    for (final unsafeSource in [
      'function renderTrait(api) { window.Android.earnReward(); }',
      "function renderTrait(api) { eval('api'); }",
      "function renderTrait(api) { const f = new Function('return 1'); }",
      "function renderTrait(api) { parent.postMessage({operation:'setText'}); }",
      "function renderTrait(api) { localStorage.setItem('x', 'y'); }",
    ]) {
      await expectLater(
        _runtime.validate(
          manifestText: _manifest(
            traitId: 'remote_view',
            modules: [
              {
                'id': 'view',
                'type': 'JAVASCRIPT',
                'entrypoint': 'view.js',
              },
            ],
          ),
          files: {'view.js': unsafeSource},
          expectedTraitId: 'remote_view',
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('Rejects traversal and invalid module data', () async {
    await expectLater(
      _runtime.validate(
        manifestText: _manifest(
          traitId: 'remote_rules',
          modules: [
            {
              'id': 'rules',
              'type': 'JSON',
              'entrypoint': '../rules.json',
            },
          ],
        ),
        files: const {'../rules.json': '{}'},
        expectedTraitId: 'remote_rules',
      ),
      throwsA(isA<FormatException>()),
    );

    await expectLater(
      _validate(
        traitId: 'remote_rules',
        modules: [
          {'id': 'rules', 'type': 'JSON', 'entrypoint': 'rules.json'},
        ],
        files: const {},
      ),
      throwsA(isA<FormatException>()),
    );

    await expectLater(
      _validate(
        traitId: 'remote_rules',
        modules: [
          {
            'id': 'rules',
            'type': 'JSON',
            'entrypoint': 'rules.json',
            'capabilities': ['award_currency'],
          },
        ],
        files: const {'rules.json': '{}'},
      ),
      throwsA(isA<FormatException>()),
    );

    await expectLater(
      _validate(
        traitId: 'remote_rules',
        modules: [
          {'id': 'rules', 'type': 'WASM', 'entrypoint': 'rules.wasm'},
        ],
        files: const {'rules.wasm': 'module'},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects duplicate module IDs and entrypoints', () async {
    await expectLater(
      _validate(
        traitId: 'remote_rules',
        modules: [
          {'id': 'rules', 'type': 'JSON', 'entrypoint': 'a.json'},
          {'id': 'rules', 'type': 'JSON', 'entrypoint': 'b.json'},
        ],
        files: const {'a.json': '{}', 'b.json': '{}'},
      ),
      throwsA(isA<FormatException>()),
    );

    await expectLater(
      _validate(
        traitId: 'remote_rules',
        modules: [
          {'id': 'first', 'type': 'JSON', 'entrypoint': 'rules.json'},
          {'id': 'second', 'type': 'JSON', 'entrypoint': 'rules.json'},
        ],
        files: const {'rules.json': '{}'},
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('rejects malformed or non-object JSON modules', () async {
    for (final source in ['{broken', '[]']) {
      await expectLater(
        _validate(
          traitId: 'remote_rules',
          modules: [
            {'id': 'rules', 'type': 'JSON', 'entrypoint': 'rules.json'},
          ],
          files: {'rules.json': source},
        ),
        throwsA(isA<FormatException>()),
      );
    }
  });

  test('Rejects wrong identity, schema, and unknown fields', () async {
    await expectLater(
      _runtime.validate(
        manifestText: _manifest(
          traitId: 'other_trait',
          modules: [
            {'id': 'rules', 'type': 'JSON', 'entrypoint': 'rules.json'},
          ],
        ),
        files: const {'rules.json': '{}'},
        expectedTraitId: 'remote_rules',
      ),
      throwsA(isA<FormatException>()),
    );

    await expectLater(
      _runtime.validate(
        manifestText: jsonEncode({
          'schemaVersion': 9,
          'traitId': 'remote_rules',
          'modules': [
            {'id': 'rules', 'type': 'JSON', 'entrypoint': 'rules.json'},
          ],
        }),
        files: const {'rules.json': '{}'},
        expectedTraitId: 'remote_rules',
      ),
      throwsA(isA<FormatException>()),
    );

    await expectLater(
      _runtime.validate(
        manifestText: jsonEncode({
          'schemaVersion': 1,
          'traitId': 'remote_rules',
          'extra': true,
          'modules': [
            {'id': 'rules', 'type': 'JSON', 'entrypoint': 'rules.json'},
          ],
        }),
        files: const {'rules.json': '{}'},
        expectedTraitId: 'remote_rules',
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('enforces module count and source-size limits', () async {
    await expectLater(
      _validate(
        traitId: 'remote_rules',
        modules: [
          for (var index = 0; index < 9; index++)
            {
              'id': 'module_$index',
              'type': 'JSON',
              'entrypoint': 'rules_$index.json',
            },
        ],
        files: {
          for (var index = 0; index < 9; index++) 'rules_$index.json': '{}',
        },
      ),
      throwsA(isA<FormatException>()),
    );

    await expectLater(
      _validate(
        traitId: 'remote_rules',
        modules: [
          {'id': 'rules', 'type': 'JSON', 'entrypoint': 'rules.json'},
        ],
        files: {
          'rules.json': List<String>.filled(
            TraitExtensionRuntime.maxSourceCharacters + 1,
            ' ',
          ).join(),
        },
      ),
      throwsA(isA<FormatException>()),
    );
  });
}

Future<ValidatedTraitExtension> _validate({
  required String traitId,
  required List<Map<String, Object?>> modules,
  required Map<String, String> files,
}) {
  return _runtime.validate(
    manifestText: _manifest(traitId: traitId, modules: modules),
    files: files,
    expectedTraitId: traitId,
  );
}

String _manifest({
  required String traitId,
  required List<Map<String, Object?>> modules,
}) {
  return jsonEncode({
    'schemaVersion': 1,
    'traitId': traitId,
    'modules': modules,
  });
}
