import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/scripting/lua_sandbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

  test(
    'does not expose filesystem, process, loader or debug libraries',
    () async {
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
    },
  );

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
    const bounded = LuaSandbox(executionBudget: Duration(milliseconds: 150));
    await expectLater(
      bounded.execute(scriptId: 'infinite_loop', source: 'while true do end'),
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
          for (var i = 0; i < LuaSandbox.maxInputEntries + 1; i++)
            'key_$i': 'v',
        },
      ),
      throwsA(isA<LuaScriptException>()),
    );
  });

  test('bundled random event selector returns an approved event ID', () async {
    final source = await rootBundle.loadString(
      'assets/scripts/events/random_event.lua',
    );
    final result = await sandbox.execute(
      scriptId: 'random_event',
      source: source,
    );
    final value = result.value as Map<String, Object?>;
    expect(value['trigger'], isA<bool>());
    expect({
      'CASH_BURST',
      'NEBULA_RAIN',
      'JACKPOT',
      'STREAK_SURGE',
      'RANGE_SHUFFLE',
      'TAX_REFUND',
      'COSMIC_GIFT',
    }, contains(value['type']));
  });

  test('bundled seasonal event catalog returns versioned data', () async {
    final source = await rootBundle.loadString(
      'assets/scripts/events/seasonal_events.lua',
    );
    final result = await sandbox.execute(
      scriptId: 'seasonal_events',
      source: source,
    );
    final value = result.value as Map<String, Object?>;
    expect(value['schemaVersion'], 1);
    expect(value['manifestVersion'], 2);
    expect(value['events'], isA<List<Object?>>());
    expect((value['events'] as List<Object?>).length, 2);
  });

  test('bundled Number Rush script returns its presentation model', () async {
    final source = await rootBundle.loadString(
      'assets/scripts/minigames/number_rush.lua',
    );
    final result = await sandbox.execute(
      scriptId: 'number_rush',
      source: source,
    );
    final value = result.value as Map<String, Object?>;
    expect(value['title'], 'Number Rush');
    expect(value['prompt'], isA<String>());
    expect(value['options'], isA<List<Object?>>());
    expect((value['options'] as List<Object?>).length, 4);
    expect(value['correct_option'], 2);
  });

  test(
    'bundled invisible trait selector returns helper and bonus IDs',
    () async {
      final source = await rootBundle.loadString(
        'assets/scripts/traits/invisible_traits.lua',
      );
      final result = await sandbox.execute(
        scriptId: 'invisible_traits',
        source: source,
        input: const {
          'failed_guesses': '6',
          'correct_guesses': '10',
          'long_streaks_observed': '1',
          'current_streak': '5',
          'total_guesses': '20',
          'accuracy_score': '0.4',
          'prestige_count': '1',
          'ultra_count': '0',
        },
      );
      final value = result.value as Map<String, Object?>;
      expect(value['helpers'], contains('mistake_insurance'));
      expect(value['helpers'], contains('range_scout'));
      expect(value['bonuses'], contains('first_prestige_bonus'));
    },
  );

  test('caps individual returned string values', () async {
    await expectLater(
      sandbox.execute(
        scriptId: 'oversized_result',
        source: 'return string.rep("x", 4097)',
      ),
      throwsA(isA<LuaScriptException>()),
    );
  });
}
