import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:lua_dardo_plus/lua.dart';

typedef LuaAssetLoader = Future<String> Function(String path);

class LuaScriptEntry {
  const LuaScriptEntry({
    required this.id,
    required this.file,
    required this.title,
    required this.description,
    required this.featured,
    required this.hostApiVersion,
    this.source = 'bundled',
  });

  final String id;
  final String file;
  final String title;
  final String description;
  final bool featured;
  final int hostApiVersion;
  final String source;

  factory LuaScriptEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final file = json['file'];
    final title = json['title'];
    final description = json['description'];
    final featured = json['featured'] ?? false;
    final hostApiVersion = json['hostApiVersion'] ?? 1;
    if (id is! String ||
        !RegExp(r'^[a-z0-9_-]{1,64}$').hasMatch(id) ||
        file is! String ||
        !RegExp(r'^[a-zA-Z0-9_./-]{1,128}$').hasMatch(file) ||
        file.split('/').contains('..') ||
        title is! String ||
        title.trim().isEmpty ||
        title.length > 100 ||
        description is! String ||
        description.trim().isEmpty ||
        description.length > 240 ||
        featured is! bool ||
        hostApiVersion is! int ||
        hostApiVersion != 1) {
      throw const FormatException('Invalid GTN1 Lua script entry.');
    }
    return LuaScriptEntry(
      id: id,
      file: file,
      title: title.trim(),
      description: description.trim(),
      featured: featured,
      hostApiVersion: hostApiVersion,
      source: 'bundled',
    );
  }
}

class LuaActivityDefinition {
  const LuaActivityDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.prompt,
    required this.options,
    required this.correctOption,
    required this.successMessage,
    required this.failureMessage,
    required this.instanceId,
  });

  final String id;
  final String title;
  final String description;
  final String prompt;
  final List<String> options;
  final int correctOption;
  final String successMessage;
  final String failureMessage;
  final String instanceId;
}

class LuaEngineStatus {
  const LuaEngineStatus({
    required this.runtimeAvailable,
    required this.hostApiVersion,
    required this.activeInstanceId,
    required this.lastError,
  });

  final bool runtimeAvailable;
  final int hostApiVersion;
  final String? activeInstanceId;
  final String? lastError;
}

class LuaStartResult {
  const LuaStartResult.started(this.activity) : reason = null;
  const LuaStartResult.rejected(this.reason) : activity = null;

  final LuaActivityDefinition? activity;
  final String? reason;
  bool get isStarted => activity != null;
}

class LuaAnswerResult {
  const LuaAnswerResult({
    required this.accepted,
    required this.correct,
    required this.message,
  });

  final bool accepted;
  final bool correct;
  final String message;
}

class LuaScriptCatalogRepository {
  LuaScriptCatalogRepository({
    LuaAssetLoader? loadAsset,
  }) : _loadAsset = loadAsset ?? rootBundle.loadString;

  static const manifestPath = 'assets/gtn1/scripts/manifest.json';
  final LuaAssetLoader _loadAsset;

  Future<List<LuaScriptEntry>> listScripts() async {
    final decoded = jsonDecode(await _loadAsset(manifestPath));
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['hostApiVersion'] != 1 ||
        decoded['scripts'] is! List) {
      throw const FormatException('Unsupported GTN1 Lua script catalog.');
    }
    final rawEntries = decoded['scripts'] as List;
    if (rawEntries.isEmpty || rawEntries.length > 32) {
      throw const FormatException('GTN1 Lua script catalog size is invalid.');
    }
    final entries = rawEntries.map((raw) {
      if (raw is! Map<String, dynamic>) {
        throw const FormatException('Invalid GTN1 Lua script catalog entry.');
      }
      return LuaScriptEntry.fromJson(raw);
    }).toList(growable: false);
    final ids = entries.map((entry) => entry.id).toSet();
    if (ids.length != entries.length) {
      throw const FormatException('GTN1 Lua script IDs must be unique.');
    }
    return entries;
  }

  Future<String> readScript(LuaScriptEntry entry) async {
    final source =
        await _loadAsset('assets/gtn1/scripts/${entry.file}');
    if (source.isEmpty || source.length > LuaSandbox.maxSourceChars) {
      throw const FormatException('Lua script source is empty or too large.');
    }
    return source;
  }
}

class LuaSandboxResult {
  const LuaSandboxResult({
    required this.payload,
    required this.logs,
  });

  final Map<String, Object?> payload;
  final List<String> logs;
}

class LuaBudgetExceededError implements Exception {
  const LuaBudgetExceededError();

  @override
  String toString() => 'Lua script exceeded its execution time budget.';
}

class LuaSandbox {
  static const maxSourceChars = 32768;
  static const maxLogLines = 32;
  static const maxLogChars = 500;
  static const executionBudget = Duration(milliseconds: 500);

  Future<LuaSandboxResult> execute({
    required String scriptId,
    required String source,
  }) async {
    if (source.isEmpty || source.length > maxSourceChars) {
      throw const FormatException('Lua source is empty or exceeds 32 KB.');
    }
    final receivePort = ReceivePort();
    final isolate = await Isolate.spawn<List<Object?>>(
      _luaWorker,
      <Object?>[receivePort.sendPort, scriptId, source],
      errorsAreFatal: true,
    );
    try {
      final response = await receivePort.first.timeout(executionBudget);
      if (response is! Map<Object?, Object?> || response['ok'] != true) {
        final reason = response is Map ? response['error'] : null;
        throw FormatException(
          reason is String ? reason : 'Lua script execution failed.',
        );
      }
      final payload = response['payload'];
      final logs = response['logs'];
      if (payload is! Map<Object?, Object?> || logs is! List) {
        throw const FormatException('Lua sandbox returned an invalid result.');
      }
      return LuaSandboxResult(
        payload: payload.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        logs: logs.whereType<String>().take(maxLogLines).toList(growable: false),
      );
    } on TimeoutException {
      isolate.kill(priority: Isolate.immediate);
      throw const LuaBudgetExceededError();
    } finally {
      receivePort.close();
    }
  }
}

void _luaWorker(List<Object?> request) {
  final sendPort = request[0] as SendPort;
  final scriptId = request[1] as String;
  final source = request[2] as String;
  try {
    final logs = <String>[];
    final state = LuaState.newState();
    state.openLibs();

    for (final name in [
      'io',
      'os',
      'package',
      'debug',
      'coroutine',
      'string',
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
      state.setGlobal(name);
    }

    int logMessage(LuaState lua) {
      final value = lua.checkString(1) ?? '';
      if (logs.length < LuaSandbox.maxLogLines) {
        logs.add(value.length > LuaSandbox.maxLogChars
            ? value.substring(0, LuaSandbox.maxLogChars)
            : value);
      }
      return 0;
    }

    state.pushDartFunction(logMessage);
    state.setGlobal('print');
    state.newTable();
    state.pushDartFunction(logMessage);
    state.setField(-2, 'log');
    state.setGlobal('gtn');

    final loaded = state.loadString(source);
    if (loaded != ThreadStatus.luaOk) {
      throw FormatException(state.toStr(-1) ?? 'Lua script did not compile.');
    }
    final executed = state.pCall(0, 1, 0);
    if (executed != ThreadStatus.luaOk) {
      throw StateError(state.toStr(-1) ?? 'Lua script execution failed.');
    }
    if (!state.isTable(-1)) {
      throw const FormatException('Lua activity must return a table.');
    }

    String readText(String field, int maxLength) {
      state.getField(-1, field);
      if (state.type(-1) != LuaType.luaString) {
        state.pop(1);
        throw FormatException('Lua activity field "$field" must be a string.');
      }
      final value = (state.toStr(-1) ?? '').trim();
      state.pop(1);
      if (value.isEmpty || value.length > maxLength) {
        throw FormatException(
          'Lua activity field "$field" must be nonblank and at most $maxLength characters.',
        );
      }
      return value;
    }

    final title = readText('title', 100);
    final description = readText('description', 240);
    final prompt = readText('prompt', 240);
    final successMessage = readText('success_message', 240);
    final failureMessage = readText('failure_message', 240);

    state.getField(-1, 'options');
    if (!state.isTable(-1)) {
      state.pop(1);
      throw const FormatException('Lua activity must define an options list.');
    }
    final optionCount = state.len2(-1) ?? 0;
    if (optionCount < 2 || optionCount > 6) {
      state.pop(1);
      throw const FormatException('Activity must provide 2 to 6 answer options.');
    }
    final options = <String>[];
    for (var index = 1; index <= optionCount; index++) {
      state.getI(-1, index);
      if (state.type(-1) != LuaType.luaString) {
        state.pop(2);
        throw const FormatException('Activity answer options must be strings.');
      }
      final option = (state.toStr(-1) ?? '').trim();
      state.pop(1);
      if (option.isEmpty || option.length > 120) {
        state.pop(1);
        throw const FormatException(
          'Activity answer options must be nonblank and at most 120 characters.',
        );
      }
      options.add(option);
    }
    state.pop(1);

    state.getField(-1, 'correct_option');
    if (!state.isInteger(-1)) {
      state.pop(1);
      throw const FormatException('Activity answer key must be an integer.');
    }
    final correctOption = state.toInteger(-1) - 1;
    state.pop(1);
    if (correctOption < 0 || correctOption >= options.length) {
      throw const FormatException('Activity answer key is outside the option list.');
    }

    sendPort.send(<String, Object?>{
      'ok': true,
      'payload': <String, Object?>{
        'id': scriptId,
        'title': title,
        'description': description,
        'prompt': prompt,
        'options': options,
        'correctOption': correctOption,
        'successMessage': successMessage,
        'failureMessage': failureMessage,
      },
      'logs': logs,
    });
  } catch (error) {
    sendPort.send(<String, Object?>{
      'ok': false,
      'error': error.toString(),
    });
  }
}

class LuaEngine {
  LuaEngine({
    LuaScriptCatalogRepository? repository,
    LuaSandbox? sandbox,
  })  : _repository = repository ?? LuaScriptCatalogRepository(),
        _sandbox = sandbox ?? LuaSandbox();

  static const hostApiVersion = 1;
  final LuaScriptCatalogRepository _repository;
  final LuaSandbox _sandbox;
  final Random _random = Random();
  LuaActivityDefinition? _activeActivity;
  bool? _lastAnswerCorrect;
  bool _starting = false;
  String? _lastError;
  bool _runtimeAvailable = false;
  List<String> _diagnostics = [];

  LuaActivityDefinition? currentActivity() => _activeActivity;

  LuaEngineStatus status() => LuaEngineStatus(
        runtimeAvailable: _runtimeAvailable,
        hostApiVersion: hostApiVersion,
        activeInstanceId: _activeActivity?.instanceId,
        lastError: _lastError,
      );

  List<String> recentDiagnostics() => List.unmodifiable(_diagnostics);

  Future<List<LuaScriptEntry>> listScripts() async {
    final scripts = await _repository.listScripts();
    _runtimeAvailable = scripts.isNotEmpty;
    return scripts;
  }

  Future<LuaScriptEntry?> inspectScript(String scriptId) async {
    final scripts = await listScripts();
    for (final script in scripts) {
      if (script.id == scriptId) return script;
    }
    return null;
  }

  Future<String> executeConsoleCommand(String command) async {
    if (!kDebugMode) return 'Lua developer commands are disabled in release builds.';
    final args = command.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (args.isEmpty || args.first != '/lua') return 'Use /lua help.';
    switch (args.length > 1 ? args[1].toLowerCase() : 'help') {
      case 'help':
        return '/lua status | list | inspect <id> | run <id> | stop [instance-id] | logs | eval';
      case 'status':
        final current = status();
        return "Lua runtime: ${current.runtimeAvailable ? 'ready' : 'unavailable'}; host API v${current.hostApiVersion}; active instance: ${current.activeInstanceId ?? 'none'}; last error: ${current.lastError ?? 'none'}";
      case 'list':
        final scripts = await listScripts();
        return scripts.isEmpty
            ? 'No registered Lua scripts.'
            : scripts.map((script) => '${script.id} — ${script.title} [${script.source}, API v${script.hostApiVersion}]').join('\n');
      case 'inspect':
        if (args.length < 3) return 'Usage: /lua inspect <id>';
        final entry = await inspectScript(args[2]);
        if (entry == null) return 'Unknown script ID: ${args[2]}';
        return 'ID: ${entry.id}\\nTitle: ${entry.title}\\nSource: ${entry.source}\\nFile: ${entry.file}\\nHost API: ${entry.hostApiVersion}\\nFeatured: ${entry.featured}';
      case 'run':
        if (args.length < 3) return 'Usage: /lua run <id>';
        final result = await start(args[2]);
        if (!result.isStarted) return 'Lua start rejected: ${result.reason}';
        return 'Started ${result.activity!.title} (instance ${result.activity!.instanceId}).';
      case 'stop':
        final stopped = stop(args.length > 2 ? args[2] : null);
        return stopped ? 'Lua activity stopped.' : 'No matching active Lua instance.';
      case 'logs':
        final logs = recentDiagnostics().toList();
        final recent = logs.length > 40 ? logs.sublist(logs.length - 40) : logs;
        return recent.isEmpty ? 'No Lua diagnostics yet.' : recent.join('\n');
      case 'eval':
        return 'Lua REPL is disabled. Run a registered script with /lua run <id>.';
      default:
        return 'Unknown Lua command. Use /lua help.';
    }
  }

  Future<LuaStartResult> startFeaturedActivity() async {
    final scripts = await listScripts();
    final featured = scripts.where((entry) => entry.featured);
    if (featured.isEmpty) {
      return const LuaStartResult.rejected(
        'No featured Lua activity is available.',
      );
    }
    return start(featured.first.id);
  }

  Future<LuaStartResult> start(String scriptId) async {
    final current = _activeActivity;
    if (current != null) {
      return current.id == scriptId
          ? LuaStartResult.started(current)
          : const LuaStartResult.rejected(
              'Another Lua activity is already running.',
            );
    }
    if (_starting) {
      return const LuaStartResult.rejected(
        'A Lua activity is already starting.',
      );
    }
    _starting = true;
    try {
      final scripts = await listScripts();
      final matching = scripts.where((script) => script.id == scriptId);
      if (matching.isEmpty) {
        return LuaStartResult.rejected('Unknown script ID: $scriptId');
      }
      final entry = matching.first;
      if (entry.hostApiVersion != hostApiVersion) {
        return const LuaStartResult.rejected(
          'This script requires an unsupported host API version.',
        );
      }
      final source = await _repository.readScript(entry);
      final result = await _sandbox.execute(scriptId: scriptId, source: source);
      final payload = result.payload;
      final options = payload['options'];
      if (options is! List || options.length < 2 || options.length > 6) {
        throw const FormatException('Activity options are invalid.');
      }
      final correctOption = payload['correctOption'];
      if (correctOption is! int ||
          correctOption < 0 ||
          correctOption >= options.length) {
        throw const FormatException('Activity answer key is invalid.');
      }
      final instanceId =
          '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 24)}';
      final activity = LuaActivityDefinition(
        id: scriptId,
        title: payload['title'] as String,
        description: payload['description'] as String,
        prompt: payload['prompt'] as String,
        options: options.cast<String>(),
        correctOption: correctOption,
        successMessage: payload['successMessage'] as String,
        failureMessage: payload['failureMessage'] as String,
        instanceId: instanceId,
      );
      _activeActivity = activity;
      _lastAnswerCorrect = null;
      _lastError = null;
      _diagnostics = [
        ..._diagnostics,
        ...result.logs.map((line) => '[lua:$scriptId] $line'),
        '[lua:$scriptId] Activity started.',
      ].take(200).toList(growable: false);
      return LuaStartResult.started(activity);
    } catch (error) {
      _lastError = error.toString();
      _diagnostics = [
        ..._diagnostics,
        '[lua:$scriptId] Activity rejected: $_lastError!',
      ].take(200).toList(growable: false);
      return LuaStartResult.rejected(_lastError!);
    } finally {
      _starting = false;
    }
  }

  LuaAnswerResult submitAnswer(int optionIndex) {
    final activity = _activeActivity;
    if (activity == null) {
      return const LuaAnswerResult(
        accepted: false,
        correct: false,
        message: 'No Lua activity is running.',
      );
    }
    if (optionIndex < 0 || optionIndex >= activity.options.length) {
      return const LuaAnswerResult(
        accepted: false,
        correct: false,
        message: 'Invalid answer option.',
      );
    }
    if (_lastAnswerCorrect != null) {
      return const LuaAnswerResult(
        accepted: false,
        correct: false,
        message: 'This activity has already been answered.',
      );
    }
    final correct = optionIndex == activity.correctOption;
    _lastAnswerCorrect = correct;
    return LuaAnswerResult(
      accepted: true,
      correct: correct,
      message: correct ? activity.successMessage : activity.failureMessage,
    );
  }

  bool stop([String? instanceId]) {
    final current = _activeActivity;
    if (current == null || (instanceId != null && instanceId != current.instanceId)) {
      return false;
    }
    _activeActivity = null;
    _lastAnswerCorrect = null;
    return true;
  }
}
