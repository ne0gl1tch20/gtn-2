import 'dart:convert';

import '../scripting/lua_sandbox.dart';

enum TraitEffect {
  xpMultiplier('XP_MULTIPLIER'),
  nebulaBonus('NEBULA_BONUS'),
  streakProtection('STREAK_PROTECTION'),
  cosmeticBadge('COSMETIC_BADGE'),
  comboReward('COMBO_REWARD'),
  rangeHint('RANGE_HINT'),
  missPenaltyReduction('MISS_PENALTY_REDUCTION'),
  riskReward('RISK_REWARD');

  const TraitEffect(this.id);

  final String id;

  static TraitEffect fromId(String id) {
    for (final effect in values) {
      if (effect.id == id) return effect;
    }
    throw FormatException('Lua module requested an unknown effect: $id');
  }
}

class TraitExtensionManifest {
  const TraitExtensionManifest({
    required this.schemaVersion,
    required this.traitId,
    required this.modules,
  });

  final int schemaVersion;
  final String traitId;
  final List<TraitExtensionModule> modules;
}

class TraitExtensionModule {
  const TraitExtensionModule({
    required this.id,
    required this.type,
    required this.entrypoint,
    this.capabilities = const <String>{},
  });

  final String id;
  final String type;
  final String entrypoint;
  final Set<String> capabilities;
}

class ValidatedTraitExtension {
  const ValidatedTraitExtension({
    required this.traitId,
    required this.modules,
  });

  final String traitId;
  final List<ValidatedTraitModule> modules;

  ValidatedTraitModule? module(String id) {
    for (final module in modules) {
      if (module.descriptor.id == id) return module;
    }
    return null;
  }
}

class ValidatedTraitModule {
  const ValidatedTraitModule({
    required this.descriptor,
    required this.source,
  });

  final TraitExtensionModule descriptor;
  final String source;
}

class TraitModuleDecision {
  const TraitModuleDecision({
    required this.eligible,
    required this.requestedEffects,
  });

  final bool eligible;
  final Set<TraitEffect> requestedEffects;
}

/// Validates extension modules before a host can offer them.
/// Lua runs in the bounded sandbox. JSON is declarative. JavaScript is returned
/// as presentation data and is never evaluated by this runtime.
class TraitExtensionRuntime {
  const TraitExtensionRuntime({
    LuaSandbox sandbox = const LuaSandbox(),
  }) : _sandbox = sandbox;

  static const int maxModules = 8;
  static const int maxSourceCharacters = 32768;
  static const int maxInputFields = 64;
  static const int maxPathLength = 160;
  static const int maxEffects = 8;

  static const Map<String, Set<String>> _allowedCapabilities = {
    'LUA': {'log', 'read_snapshot'},
    'JSON': {'read_rules'},
    'JAVASCRIPT': {'render_ui', 'show_local_message'},
  };

  static final RegExp _traitIdPattern =
      RegExp(r'^[a-z][a-z0-9_.-]{1,63}$');
  static final RegExp _moduleIdPattern =
      RegExp(r'^[a-z][a-z0-9_-]{0,47}$');
  static final RegExp _pathSegmentPattern =
      RegExp(r'^[A-Za-z0-9_-][A-Za-z0-9_.-]*$');
  static final RegExp _forbiddenJavaScript = RegExp(
    r'\b(eval|fetch|XMLHttpRequest|WebSocket|importScripts|parent|top|opener|localStorage|sessionStorage|indexedDB|navigator|location|Worker|BroadcastChannel|postMessage)\b|\bnew\s+Function\b|\bFunction\s*\(|\bwindow\s*\.|\bdocument\s*\.|\bandroid\s*\.|\bJava\s*\.',
    caseSensitive: false,
  );

  final LuaSandbox _sandbox;

  Future<ValidatedTraitExtension> validate({
    required String manifestText,
    required Map<String, String> files,
    required String expectedTraitId,
  }) async {
    final manifestJson = _decodeObject(manifestText, 'Extension manifest');
    _ensureKeys(
      manifestJson,
      const {'schemaVersion', 'traitId', 'modules'},
      'Extension manifest',
    );

    final rawSchemaVersion = manifestJson.containsKey('schemaVersion')
        ? manifestJson['schemaVersion']
        : 1;
    if (rawSchemaVersion is! int || rawSchemaVersion != 1) {
      throw const FormatException('Unsupported extension manifest schema.');
    }

    final traitId = _requiredString(manifestJson, 'traitId');
    if (traitId != expectedTraitId || !_traitIdPattern.hasMatch(traitId)) {
      throw const FormatException('Extension trait ID mismatch.');
    }

    final rawModules = manifestJson['modules'];
    if (rawModules is! List ||
        rawModules.isEmpty ||
        rawModules.length > maxModules) {
      throw const FormatException(
        'Extension module count is outside the supported limit.',
      );
    }

    final moduleIds = <String>{};
    final entrypoints = <String>{};
    final descriptors = <TraitExtensionModule>[];
    final validatedModules = <ValidatedTraitModule>[];

    for (final rawModule in rawModules) {
      final moduleJson = _asObject(rawModule, 'Extension module');
      _ensureKeys(
        moduleJson,
        const {'id', 'type', 'entrypoint', 'capabilities'},
        'Extension module',
      );

      final id = _requiredString(moduleJson, 'id');
      if (!_moduleIdPattern.hasMatch(id)) {
        throw const FormatException('Invalid module ID.');
      }
      if (!moduleIds.add(id)) {
        throw const FormatException('Duplicate module ID.');
      }

      final type = _requiredString(moduleJson, 'type').toUpperCase();
      final entrypoint = _requiredString(moduleJson, 'entrypoint');
      if (entrypoint.length > maxPathLength ||
          entrypoint.startsWith('/') ||
          entrypoint.contains('\\') ||
          entrypoint
              .split('/')
              .any((segment) => !_pathSegmentPattern.hasMatch(segment))) {
        throw const FormatException('Invalid module entrypoint.');
      }
      if (!entrypoints.add(entrypoint)) {
        throw const FormatException('Two modules cannot share an entrypoint.');
      }

      final source = files[entrypoint];
      if (source == null) {
        throw FormatException('Missing module entrypoint: $entrypoint');
      }
      if (source.trim().isEmpty || source.length > maxSourceCharacters) {
        throw const FormatException(
          'Module source is empty or too large.',
        );
      }

      final allowedCapabilities = _allowedCapabilities[type];
      if (allowedCapabilities == null) {
        throw FormatException('Unsupported module type: $type');
      }
      final rawCapabilities = moduleJson.containsKey('capabilities')
          ? moduleJson['capabilities']
          : const <Object?>[];
      final capabilities = _stringSet(rawCapabilities, 'capabilities');
      if (!allowedCapabilities.containsAll(capabilities)) {
        throw const FormatException(
          'Module requests an unsupported capability.',
        );
      }

      if (type == 'LUA') {
        if (!entrypoint.toLowerCase().endsWith('.lua')) {
          throw const FormatException(
            'Lua modules must use .lua entrypoints.',
          );
        }
        await _sandbox.validate(
          scriptId: '${traitId}_${id}',
          source: source,
        );
      } else if (type == 'JSON') {
        if (!entrypoint.toLowerCase().endsWith('.json')) {
          throw const FormatException(
            'JSON modules must use .json entrypoints.',
          );
        }
        _decodeObject(source, 'JSON module');
      } else {
        if (!entrypoint.toLowerCase().endsWith('.js')) {
          throw const FormatException(
            'JavaScript modules must use .js entrypoints.',
          );
        }
        if (_forbiddenJavaScript.hasMatch(source)) {
          throw const FormatException(
            'JavaScript module uses a forbidden host or dynamic-code API.',
          );
        }
        if (!source.contains('renderTrait') &&
            !source.contains('registerTraitView')) {
          throw const FormatException(
            'JavaScript UI modules must expose renderTrait(api) or registerTraitView(api).',
          );
        }
      }

      final descriptor = TraitExtensionModule(
        id: id,
        type: type,
        entrypoint: entrypoint,
        capabilities: Set<String>.unmodifiable(capabilities),
      );
      descriptors.add(descriptor);
      validatedModules.add(
        ValidatedTraitModule(descriptor: descriptor, source: source),
      );
    }

    final manifest = TraitExtensionManifest(
      schemaVersion: rawSchemaVersion,
      traitId: traitId,
      modules: List<TraitExtensionModule>.unmodifiable(descriptors),
    );
    return ValidatedTraitExtension(
      traitId: manifest.traitId,
      modules: List<ValidatedTraitModule>.unmodifiable(validatedModules),
    );
  }

  Future<TraitModuleDecision> evaluateLua({
    required ValidatedTraitExtension extension,
    required String moduleId,
    required Map<String, String> snapshot,
    required Set<TraitEffect> allowedEffects,
  }) async {
    final module = _requireModule(extension, moduleId);
    if (module.descriptor.type != 'LUA') {
      throw const FormatException('Requested module is not Lua.');
    }
    if (snapshot.length > maxInputFields) {
      throw const FormatException('Trait snapshot has too many fields.');
    }
    if (snapshot.isNotEmpty &&
        !module.descriptor.capabilities.contains('read_snapshot')) {
      throw const FormatException(
        'Lua module did not declare the read_snapshot capability.',
      );
    }

    final result = await _sandbox.execute(
      scriptId: '${extension.traitId}_${module.descriptor.id}',
      source: module.source,
      input: snapshot,
      capabilities: module.descriptor.capabilities,
    );
    final rawDecision = result.value;
    if (rawDecision is! Map) {
      throw const FormatException('Lua module must return a decision table.');
    }
    final decision = Map<String, Object?>.from(rawDecision);
    final eligibleValue = decision['eligible'];
    if (eligibleValue != null && eligibleValue is! bool) {
      throw const FormatException(
        'Lua module eligibility must be a boolean.',
      );
    }
    final eligible = eligibleValue == true;
    final rawEffects = decision['effects'];
    final requestedEffects = <TraitEffect>[];
    if (rawEffects != null) {
      if (rawEffects is! List || rawEffects.length > maxEffects) {
        throw const FormatException(
          'Lua module returned an invalid effect list.',
        );
      }
      for (final rawEffect in rawEffects) {
        if (rawEffect is! String) {
          throw const FormatException('Lua module returned an invalid effect.');
        }
        final effect = TraitEffect.fromId(rawEffect);
        if (!allowedEffects.contains(effect)) {
          throw const FormatException(
            'Lua module requested an undeclared effect.',
          );
        }
        if (!requestedEffects.contains(effect)) {
          requestedEffects.add(effect);
        }
      }
    }

    return TraitModuleDecision(
      eligible: eligible,
      requestedEffects: eligible
          ? Set<TraitEffect>.unmodifiable(requestedEffects)
          : const <TraitEffect>{},
    );
  }

  Map<String, Object?> readJsonModule(
    ValidatedTraitExtension extension,
    String moduleId,
  ) {
    final module = _requireModule(extension, moduleId);
    if (module.descriptor.type != 'JSON') {
      throw const FormatException('Requested module is not JSON.');
    }
    return Map<String, Object?>.unmodifiable(
      _decodeObject(module.source, 'JSON module'),
    );
  }

  String javascriptPresentation(
    ValidatedTraitExtension extension,
    String moduleId,
  ) {
    final module = _requireModule(extension, moduleId);
    if (module.descriptor.type != 'JAVASCRIPT') {
      throw const FormatException('Requested module is not JavaScript.');
    }
    return module.source;
  }

  static ValidatedTraitModule _requireModule(
    ValidatedTraitExtension extension,
    String moduleId,
  ) {
    final module = extension.module(moduleId);
    if (module == null) {
      throw const FormatException('Unknown extension module.');
    }
    return module;
  }

  static Map<String, Object?> _decodeObject(String source, String context) {
    final decoded = jsonDecode(source);
    if (decoded is! Map) {
      throw FormatException('$context must be a JSON object.');
    }
    return Map<String, Object?>.from(decoded);
  }

  static Map<String, Object?> _asObject(Object? value, String context) {
    if (value is! Map) {
      throw FormatException('$context must be a JSON object.');
    }
    return Map<String, Object?>.from(value);
  }

  static void _ensureKeys(
    Map<String, Object?> value,
    Set<String> allowed,
    String context,
  ) {
    if (value.keys.any((key) => !allowed.contains(key))) {
      throw FormatException('$context contains an unsupported field.');
    }
  }

  static String _requiredString(Map<String, Object?> value, String key) {
    final result = value[key];
    if (result is! String || result.isEmpty) {
      throw FormatException('Missing or invalid $key.');
    }
    return result;
  }

  static Set<String> _stringSet(Object? value, String context) {
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('Invalid $context.');
    }
    return Set<String>.from(value.cast<String>());
  }
}
