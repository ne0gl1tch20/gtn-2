import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/scripting/lua_sandbox.dart';

void main() {
  const sandbox = LuaSandbox();

  test('executes Lua and returns bounded typed data', () async {
    final result = await sandbox.execute(
      scriptId: 'test_result',
      source: '''
        local amount = tonumber(gtn.input.amount or "0") or 0
        gtn.log("amount " .. amount)
        return { value = amount + 1, ok = true, choices = { "a", "b" } }
      ''',
      input: const {'amount': '41'},
    );

    expect(result.value, {
      'value': 42,
      'ok': true,
      'choices': ['a', 'b'],
    });
    expect(result.logs, ['amount 41']);
  });

  test('does not expose filesystem, process, loader or debug libraries', () async {
    final result = await sandbox.execute(
      scriptId: 'sandbox_surface',
      source: '''
        return {
          os = os ~= nil,
          io = io ~= nil,
          package = package ~= nil,
          debug = debug ~= nil,
          dofile = dofile ~= nil,
          loadfile = loadfile ~= nil,
          load = load ~= nil,
          require = require ~= nil,
          rawset = rawset ~= nil,
          setmetatable = setmetatable ~= nil
        }
      ''',
    );

    expect(result.value, {
      'os': false,
      'io': false,
      'package': false,
      'debug': false,
      'dofile': false,
      'loadfile': false,
      'load': false,
      'require': false,
      'rawset': false,
      'setmetatable': false,
    });
  });

  test('validation compiles without executing the chunk', () async {
    await sandbox.validate(
      scriptId: 'compile_only',
      source: 'while true do end',
    );
  });

  test('rejects malformed source', () async {
    await expectLater(
      sandbox.validate(scriptId: 'broken', source: 'function('),
      throwsA(isA<LuaScriptException>()),
    );
  });

  test('interrupts an infinite loop by terminating its isolate', () async {
    const bounded = LuaSandbox(
      executionBudget: Duration(milliseconds: 150),
    );
    await expectLater(
      bounded.execute(
        scriptId: 'infinite_loop',
        source: 'while true do end',
      ),
      throwsA(isA<LuaBudgetExceededException>()),
    );
  });

  test('enforces source and input limits before creating an isolate', () async {
    await expectLater(
      sandbox.execute(
        scriptId: 'too_large',
        source: 'x' * (LuaSandbox.maxSourceCharacters + 1),
      ),
      throwsA(isA<LuaScriptException>()),
    );
    await expectLater(
      sandbox.execute(
        scriptId: 'too_many_inputs',
        source: 'return true',
        input: {
          for (var i = 0; i < LuaSandbox.maxInputEntries + 1; i++) 'key_$i': 'v',
        },
      ),
      throwsA(isA<LuaScriptException>()),
    );
  });
}
