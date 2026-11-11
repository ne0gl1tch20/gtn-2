import 'dart:async';
import 'dart:isolate';

import 'package:lua_dardo/lua.dart';

class LuaExecutionResult {
  const LuaExecutionResult({required this.value, required this.logs});

  final Object? value;
  final List<String> logs;
}

class LuaScriptException implements Exception {
  const LuaScriptException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LuaBudgetExceededException extends LuaScriptException {
  const LuaBudgetExceededException()
    : super('Lua script exceeded its execution time budget.');
}

/// Runs GTN1 Lua scripts in a disposable isolate with a deliberately small host
/// surface. Scripts return data only; the Dart caller validates and applies it.
class LuaSandbox {
  const LuaSandbox({
    this.executionBudget = const Duration(milliseconds: 500),
  });

  static const int maxSourceCharacters = 32768;
  static const int maxInputEntries = 64;
  static const int maxInputKeyCharacters = 48;
  static const int maxInputValueCharacters = 256;
  static const int maxLogLines = 32;
  static const int maxLogCharacters = 500;
  static const int maxResultNodes = 512;
  static const int maxResultDepth = 8;

  final Duration executionBudget;

  Future<void> validate({
    required String scriptId,
    required String source,
  }) async {
    _validateSource(source);
    await _runIsolated(
      scriptId: scriptId,
      source: source,
      input: const {},
      capabilities: const {},
      validateOnly: true,
    );
  }

  Future<LuaExecutionResult> execute({
    required String scriptId,
    required String source,
    Map<String, String> input = const {},
    Set<String> capabilities = const {'log', 'read_snapshot'},
  }) async {
    _validateSource(source);
    if (input.length > maxInputEntries) {
      throw const LuaScriptException('Lua input contains too many fields.');
    }
    for (final entry in input.entries) {
      if (!RegExp(
        '^[A-Za-z][A-Za-z0-9_]{0,${maxInputKeyCharacters - 1}}$',
      ).hasMatch(entry.key)) {
        throw const LuaScriptException('Lua input contains an invalid key.');
      }
      if (entry.value.length > maxInputValueCharacters) {
        throw const LuaScriptException('Lua input value is too long.');
      }
    }
    final allowedCapabilities = {'log', 'read_snapshot'};
    if (!allowedCapabilities.containsAll(capabilities)) {
      throw const LuaScriptException('Lua capability is not supported.');
    }
    final result = await _runIsolated(
      scriptId: scriptId,
      source: source,
      input: capabilities.contains('read_snapshot') ? input : const {},
      capabilities: capabilities,
      validateOnly: false,
    );
    return LuaExecutionResult(
      value: result['value'],
      logs: List<String>.unmodifiable(
        (result['logs'] as List<Object?>? ?? const []).whereType<String>(),
      ),
    );
  }

  Future<Map<String, Object?>> _runIsolated({
    required String scriptId,
    required String source,
    required Map<String, String> input,
    required Set<String> capabilities,
    required bool validateOnly,
  }) async {
    final replies = ReceivePort();
    final errors = ReceivePort();
    final exits = ReceivePort();
    final completer = Completer<Map<String, Object?>>();
    StreamSubscription<Object?>? replySubscription;
    StreamSubscription<Object?>? errorSubscription;
    StreamSubscription<Object?>? exitSubscription;
    Isolate? isolate;
    Timer? timeout;

    replySubscription = replies.listen((message) {
      if (message is Map) {
        final result = Map<String, Object?>.from(message);
        if (!completer.isCompleted) {
          if (result['ok'] == true) {
            completer.complete(result);
          } else {
            completer.completeError(
              LuaScriptException(
                (result['error'] as String?) ?? 'Lua script failed.',
              ),
            );
          }
        }
      }
    });
    errorSubscription = errors.listen((message) {
      if (!completer.isCompleted) {
        final details = message is List && message.isNotEmpty
            ? message.first.toString()
            : 'Lua isolate failed.';
        completer.completeError(LuaScriptException(details));
      }
    });
    exitSubscription = exits.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(
          LuaScriptException('Lua isolate exited without returning a result.'),
        );
      }
    });

    try {
      isolate = await Isolate.spawn<Map<String, Object?>>(
        _luaWorker,
        {
          'scriptId': scriptId,
          'source': source,
          'input': Map<String, String>.from(input),
          'capabilities': capabilities.toList(),
          'validateOnly': validateOnly,
          'replyTo': replies.sendPort,
        },
        onError: errors.sendPort,
        onExit: exits.sendPort,
        errorsAreFatal: true,
      );
      timeout = Timer(executionBudget, () {
        isolate?.kill(priority: Isolate.immediate);
        if (!completer.isCompleted) {
          completer.completeError(const LuaBudgetExceededException());
        }
      });
      return await completer.future;
    } finally {
      timeout?.cancel();
      isolate?.kill(priority: Isolate.immediate);
      await replySubscription.cancel();
      await errorSubscription.cancel();
      await exitSubscription.cancel();
      replies.close();
      errors.close();
      exits.close();
    }
  }

  static void _validateSource(String source) {
    if (source.trim().isEmpty) {
      throw const LuaScriptException('Lua source is empty.');
    }
    if (source.length > maxSourceCharacters) {
      throw const LuaScriptException(
        'Lua source exceeds the 32,768 character limit.',
      );
    }
  }
}

void _luaWorker(Map<String, Object?> message) {
  final replyTo = message['replyTo'] as SendPort;
  final scriptId = message['scriptId'] as String;
  final source = message['source'] as String;
  final input = message['input'] as Map<String, String>;
  final capabilities = (message['capabilities'] as List<Object?>).cast<String>();
  final validateOnly = message['validateOnly'] as bool;
  final logs = <String>[];

  try {
    final state = LuaState.newState();
    state.openLibs();

    // Remove every standard-library surface that can reach the host, load
    // another chunk, mutate metatables, or bypass the declared API.
    for (final global in const [
      'os',
      'io',
      'package',
      'debug',
      'dofile',
      'loadfile',
      'load',
      'require',
      'collectgarbage',
      'getmetatable',
      'setmetatable',
      'rawset',
      'rawget',
    ]) {
      state.pushNil();
      state.setGlobal(global);
    }

    state.newTable(); // gtn
    state.newTable(); // gtn.input
    for (final entry in input.entries) {
      state.pushString(entry.key);
      state.pushString(entry.value);
      state.setTable(-3);
    }
    state.setField(-2, 'input');

    if (capabilities.contains('log')) {
      state.pushDartFunction((lua) {
        if (logs.length < LuaSandbox.maxLogLines) {
          final line = (lua.toString2(1) ?? '').take(LuaSandbox.maxLogCharacters);
          logs.add(line);
        }
        return 0;
      });
      state.setField(-2, 'log');
    } else {
      state.pushNil();
      state.setField(-2, 'log');
    }
    state.setGlobal('gtn');

    if (capabilities.contains('log')) {
      state.pushDartFunction((lua) {
        if (logs.length < LuaSandbox.maxLogLines) {
          final parts = <String>[];
          for (var i = 1; i <= lua.getTop(); i++) {
            parts.add((lua.toString2(i) ?? '').take(LuaSandbox.maxLogCharacters));
          }
          logs.add(parts.join(' ').take(LuaSandbox.maxLogCharacters));
        }
        return 0;
      });
      state.setGlobal('print');
    } else {
      state.pushNil();
      state.setGlobal('print');
    }

    final loadStatus = state.loadString(source);
    if (loadStatus != ThreadStatus.luaOk) {
      throw LuaScriptException(
        'Lua syntax error in $scriptId: ${state.toStr(-1) ?? loadStatus.name}',
      );
    }
    if (validateOnly) {
      replyTo.send({'ok': true, 'value': null, 'logs': logs});
      return;
    }

    final callStatus = state.pCall(0, 1, 0);
    if (callStatus != ThreadStatus.luaOk) {
      throw LuaScriptException(
        'Lua execution failed in $scriptId: ${state.toStr(-1) ?? callStatus.name}',
      );
    }
    final value = _readLuaValue(
      state,
      -1,
      depth: 0,
      nodeCount: [0],
    );
    replyTo.send({'ok': true, 'value': value, 'logs': logs});
  } catch (error) {
    replyTo.send({
      'ok': false,
      'error': error.toString().take(240),
      'logs': logs,
    });
  }
}

Object? _readLuaValue(
  LuaState state,
  int index, {
  required int depth,
  required List<int> nodeCount,
}) {
  nodeCount[0]++;
  if (nodeCount[0] > LuaSandbox.maxResultNodes ||
      depth > LuaSandbox.maxResultDepth) {
    throw const LuaScriptException('Lua result exceeds the output limits.');
  }
  if (state.isNil(index)) return null;
  if (state.isBoolean(index)) return state.toBoolean(index);
  if (state.isNumber(index)) return state.toNumber(index);
  if (state.isString(index)) return state.toStr(index);
  if (!state.isTable(index)) {
    throw const LuaScriptException('Lua returned an unsupported value type.');
  }

  final tableIndex = state.absIndex(index);
  final values = <String, Object?>{};
  state.pushNil();
  while (state.next(tableIndex)) {
    final key = state.isInteger(-2)
        ? state.toInteger(-2).toString()
        : state.toStr(-2);
    if (key == null || key.length > 128 || values.containsKey(key)) {
      throw const LuaScriptException('Lua returned an invalid table key.');
    }
    values[key] = _readLuaValue(
      state,
      -1,
      depth: depth + 1,
      nodeCount: nodeCount,
    );
    if (values.length > LuaSandbox.maxResultNodes) {
      throw const LuaScriptException('Lua returned too many table entries.');
    }
    state.pop(1);
  }

  final numericKeys = values.keys
      .map(int.tryParse)
      .toList(growable: false);
  if (values.isNotEmpty &&
      numericKeys.every((key) => key != null && key > 0)) {
    final indices = numericKeys.cast<int>()..sort();
    final isDense = indices.length == indices.last && 
        indices.asMap().entries.every((entry) => entry.value == entry.key + 1);
    if (isDense) {
      return List<Object?>.unmodifiable([
        for (var i = 1; i <= indices.length; i++) values['$i'],
      ]);
    }
  }
  return Map<String, Object?>.unmodifiable(values);
}

extension _LuaBoundedString on String {
  String take(int maxLength) =>
      length <= maxLength ? this : substring(0, maxLength);
}
