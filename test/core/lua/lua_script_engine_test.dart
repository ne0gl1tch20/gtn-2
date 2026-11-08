import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/lua/lua_script_engine.dart';

const _manifest = '''
{
  "schemaVersion": 1,
  "hostApiVersion": 1,
  "scripts": [
    {
      "id": "number_rush",
      "file": "minigames/number_rush.lua",
      "title": "Number Rush",
      "description": "A quick Lua-powered number challenge.",
      "featured": true,
      "hostApiVersion": 1
    }
  ]
}
''';

const _script = r'''
gtn.log("Number Rush loaded")
return {
  title = "Number Rush",
  description = "One quick question.",
  prompt = "Which number is prime?",
  options = { "21", "29", "39", "51" },
  correct_option = 2,
  success_message = "Correct!",
  failure_message = "Not quite."
}
''';

LuaScriptCatalogRepository _repository({
  String manifest = _manifest,
  String script = _script,
}) {
  return LuaScriptCatalogRepository(
    loadAsset: (path) async {
      if (path == LuaScriptCatalogRepository.manifestPath) return manifest;
      if (path == 'assets/gtn1/scripts/minigames/number_rush.lua') {
        return script;
      }
      throw StateError('Unexpected asset path: $path');
    },
  );
}

void main() {
  group('GTN1 Lua script catalog', () {
    test('loads and validates the pinned host API and script entry', () async {
      final scripts = await _repository().listScripts();

      expect(scripts, hasLength(1));
      expect(scripts.single.id, 'number_rush');
      expect(scripts.single.featured, isTrue);
      expect(scripts.single.hostApiVersion, 1);
      expect(await _repository().readScript(scripts.single), _script);
    });

    test('rejects script paths that attempt directory traversal', () async {
      const invalidManifest = '''
      {"schemaVersion":1,"hostApiVersion":1,"scripts":[
        {"id":"bad_path","file":"../secret.lua","title":"Bad","description":"Bad path","featured":true,"hostApiVersion":1}
      ]}
      ''';

      await expectLater(
        _repository(manifest: invalidManifest).listScripts(),
        throwsFormatException,
      );
    });

    test('rejects duplicate script IDs', () async {
      const duplicateManifest = '''
      {"schemaVersion":1,"hostApiVersion":1,"scripts":[
        {"id":"same","file":"minigames/a.lua","title":"A","description":"A","featured":true},
        {"id":"same","file":"minigames/b.lua","title":"B","description":"B","featured":false}
      ]}
      ''';

      await expectLater(
        _repository(manifest: duplicateManifest).listScripts(),
        throwsFormatException,
      );
    });
  });

  group('GTN1 Lua sandbox', () {
    test('executes the bundled activity contract and captures bounded logs',
        () async {
      final result = await LuaSandbox().execute(
        scriptId: 'number_rush',
        source: _script,
      );

      expect(result.payload['title'], 'Number Rush');
      expect(result.payload['prompt'], 'Which number is prime?');
      expect(result.payload['options'], ['21', '29', '39', '51']);
      expect(result.payload['correctOption'], 1);
      expect(result.logs, ['Number Rush loaded']);
    });

    test('does not expose filesystem or operating-system libraries', () async {
      const restrictedScript = r'''
      return {
        title = "Sandbox check",
        description = "Restricted libraries",
        prompt = (io == nil and os == nil and package == nil and debug == nil)
          and "Libraries removed" or "Libraries available",
        options = { "Yes", "No" },
        correct_option = 1,
        success_message = "Correct!",
        failure_message = "Wrong.",
        hidden = (io == nil and os == nil and package == nil and debug == nil)
      }
      ''';
      final result = await LuaSandbox().execute(
        scriptId: 'sandbox_check',
        source: restrictedScript,
      );

      expect(result.payload['title'], 'Sandbox check');
      expect(result.payload['prompt'], 'Libraries removed');
    });

    test('terminates scripts that exceed the execution time budget', () async {
      await expectLater(
        LuaSandbox().execute(
          scriptId: 'infinite_loop',
          source: 'while true do end',
        ),
        throwsA(isA<LuaBudgetExceededError>()),
      );
    });
  });

  group('GTN1 Lua activity lifecycle', () {
    test('starts Number Rush, validates one answer and stops by instance ID',
        () async {
      final engine = LuaEngine(repository: _repository());
      final started = await engine.startFeaturedActivity();

      expect(started.isStarted, isTrue);
      final activity = started.activity!;
      expect(activity.id, 'number_rush');
      expect(activity.options, ['21', '29', '39', '51']);
      expect(engine.status().activeInstanceId, activity.instanceId);

      final answer = engine.submitAnswer(activity.correctOption);
      expect(answer.accepted, isTrue);
      expect(answer.correct, isTrue);
      expect(answer.message, 'Correct!');
      expect(engine.submitAnswer(activity.correctOption).accepted, isFalse);

      expect(engine.stop('stale-instance'), isFalse);
      expect(engine.status().activeInstanceId, activity.instanceId);
      expect(engine.stop(activity.instanceId), isTrue);
      expect(engine.status().activeInstanceId, isNull);
    });

    test('invalid answers do not consume the single answer submission',
        () async {
      final engine = LuaEngine(repository: _repository());
      final activity = (await engine.startFeaturedActivity()).activity!;

      expect(engine.submitAnswer(-1).accepted, isFalse);
      expect(engine.submitAnswer(activity.options.length).accepted, isFalse);
      expect(engine.submitAnswer(activity.correctOption).accepted, isTrue);
      expect(engine.submitAnswer(activity.correctOption).accepted, isFalse);
    });
  });
}
