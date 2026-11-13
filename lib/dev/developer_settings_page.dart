import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/scripting/lua_sandbox.dart';
import '../data/saves/save_data.dart';
import '../design/expressive_widgets.dart';

typedef DeveloperCommand = Future<String> Function(String command);
typedef DeveloperSaveApply = Future<void> Function(SaveData save);

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({
    super.key,
    required this.save,
    required this.onCommand,
    required this.onApplySave,
  });

  final SaveData save;
  final DeveloperCommand onCommand;
  final DeveloperSaveApply onApplySave;

  @override
  State<DeveloperSettingsPage> createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {
  final _command = TextEditingController();
  late final _json = TextEditingController(
    text: const JsonEncoder.withIndent('  ').convert(widget.save.toJson()),
  );
  final List<String> _logs = [];
  bool _busy = false;
  final LuaSandbox _luaSandbox = const LuaSandbox();
  late final Future<List<_RegisteredLuaScript>> _luaScripts =
      _loadLuaScripts();
  String? _selectedLuaScriptId;
  bool _luaBusy = false;
  String? _luaOutput;
  List<String> _luaLogs = [];

  Future<List<_RegisteredLuaScript>> _loadLuaScripts() async {
    final source = await rootBundle.loadString('assets/scripts/manifest.json');
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic> ||
        decoded['schemaVersion'] != 1 ||
        decoded['hostApiVersion'] != 1 ||
        decoded['scripts'] is! List) {
      throw const FormatException('Invalid Lua script manifest.');
    }

    final scripts = <_RegisteredLuaScript>[];
    for (final entry in decoded['scripts'] as List) {
      if (entry is! Map ||
          entry['hostApiVersion'] != 1 ||
          entry['id'] is! String ||
          !RegExp(r'^[a-z][a-z0-9_]{0,63}
  @override
  void dispose() {
    _command.dispose();
    _json.dispose();
    super.dispose();
  }

  Future<void> _runCommand() async {
    final command = _command.text.trim();
    if (command.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onCommand(command);
      if (mounted) {
        setState(() {
          _logs.insert(0, '\$ $command');
          _logs.insert(1, result);
          if (_logs.length > 30) _logs.removeRange(30, _logs.length);
        });
      }
      _command.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final decoded = jsonDecode(_json.text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Save JSON must be an object.');
      }
      final save = SaveData.fromJson(decoded);
      await widget.onApplySave(save);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Developer save applied.')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not apply save: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('Developer Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Lua Console',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Run registered Lua scripts against a read-only snapshot of this save. Scripts cannot write saves, change settings or grant rewards.',
          ),
          const SizedBox(height: 8),
          FutureBuilder<List<_RegisteredLuaScript>>(
            future: _luaScripts,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const LinearProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Could not load Lua manifest: ${snapshot.error}');
              }
              final scripts = snapshot.data ?? const <_RegisteredLuaScript>[];
              if (scripts.isEmpty) {
                return const Text('No registered Lua scripts are available.');
              }
              final selectedId = scripts.any(
                (script) => script.id == _selectedLuaScriptId,
              )
                  ? _selectedLuaScriptId!
                  : scripts.first.id;
              final selected = scripts.firstWhere(
                (script) => script.id == selectedId,
              );
              return GtnExpressiveCard(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedId,
                        decoration: const InputDecoration(
                          labelText: 'Registered script',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final script in scripts)
                            DropdownMenuItem(
                              value: script.id,
                              child: Text(script.title),
                            ),
                        ],
                        onChanged: _luaBusy
                            ? null
                            : (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedLuaScriptId = value;
                                    _luaOutput = null;
                                    _luaLogs = [];
                                  });
                                }
                              },
                      ),
                      if (selected.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(selected.description),
                      ],
                      const SizedBox(height: 8),
                      M3EButton.filled(
                        onPressed: _luaBusy
                            ? null
                            : () => _runRegisteredLuaScript(selected),
                        child: Text(
                          _luaBusy ? 'Running…' : 'Execute registered script',
                        ),
                      ),
                      if (_luaLogs.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Text('Lua logs'),
                        for (final line in _luaLogs)
                          SelectableText(line),
                      ],
                      if (_luaOutput != null) ...[
                        const SizedBox(height: 12),
                        const Text('Read-only result'),
                        SelectableText(_luaOutput!),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Developer Console',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try /help, /money 1000000, /prestige 10, /ultra 1, /nebula 100 or /reset.',
          ),
          const SizedBox(height: 12),
          GtnExpressiveTextField(
            controller: _command,
            decoration: const InputDecoration(
              labelText: 'Developer command',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _runCommand(),
          ),
          const SizedBox(height: 8),
          M3EButton.filled(
            onPressed: _busy ? null : _runCommand,
            child: const Text('Run command'),
          ),
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            GtnExpressiveCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Console output'),
                    const SizedBox(height: 8),
                    for (final line in _logs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SelectableText(line),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Save Editor (JSON)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Edit the current slot save directly. Invalid or incompatible JSON is rejected.',
          ),
          const SizedBox(height: 8),
          GtnExpressiveTextField(
            controller: _json,
            minLines: 12,
            maxLines: 24,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Raw save JSON',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: M3EButton.text(
                  onPressed: _busy
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: _json.text),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Save JSON copied.')),
                          );
                        },
                  child: const Text('Copy JSON'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: M3EButton.filled(
                  onPressed: _busy ? null : _applyJson,
                  child: const Text('Apply JSON to current slot'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
).hasMatch(entry['id'] as String) ||
          entry['file'] is! String ||
          entry['title'] is! String) {
        throw const FormatException('Invalid registered Lua script entry.');
      }
      final file = entry['file'] as String;
      if (!file.endsWith('.lua') ||
          file.startsWith('/') ||
          file.split('/').contains('..') ||
          file.contains(r'\\')) {
        throw const FormatException('Invalid Lua script asset path.');
      }
      scripts.add(
        _RegisteredLuaScript(
          id: entry['id'] as String,
          file: file,
          title: entry['title'] as String,
          description: entry['description'] is String
              ? entry['description'] as String
              : '',
        ),
      );
    }
    return List.unmodifiable(scripts);
  }

  Future<void> _runRegisteredLuaScript(
    _RegisteredLuaScript script,
  ) async {
    if (_luaBusy) return;
    setState(() {
      _luaBusy = true;
      _luaOutput = null;
      _luaLogs = [];
    });
    try {
      final source = await rootBundle.loadString(
        'assets/scripts/${script.file}',
      );
      final progression = widget.save.progression;
      final profile = progression.legacySystems.adaptiveTraitProfile;
      final result = await _luaSandbox.execute(
        scriptId: script.id,
        source: source,
        input: {
          'money': progression.money.toString(),
          'prestige': progression.prestige.toString(),
          'ultra': progression.ultra.toString(),
          'nebula': progression.nebula.toString(),
          'total_guesses': progression.totalGuesses.toString(),
          'correct_guesses': progression.correctGuesses.toString(),
          'failed_guesses': (progression.totalGuesses -
                  progression.correctGuesses)
              .toString(),
          'current_streak': progression.currentStreak.toString(),
          'best_streak': progression.bestStreak.toString(),
          'long_streaks_observed': profile.longStreaksObserved.toString(),
          'accuracy_score': profile.accuracyScore.toString(),
          'prestige_count': progression.prestigeResets.toString(),
          'ultra_count': progression.ultraResets.toString(),
          'first_prestige_awarded': profile.awardedBonuses.contains(
                'first_prestige_bonus',
              )
              ? '1'
              : '0',
          'first_ultra_awarded': profile.awardedBonuses.contains(
                'first_ultra_bonus',
              )
              ? '1'
              : '0',
          'veteran_awarded': profile.awardedBonuses.contains('veteran_bonus')
              ? '1'
              : '0',
          'playtime_seconds': progression.playtimeSeconds.toString(),
          'attempts': widget.save.attempts.toString(),
          'range_min': widget.save.minimum.toString(),
          'range_max': widget.save.maximum.toString(),
          'active_world_id': progression.legacySystems.activeWorldId,
        },
        capabilities: const {'log', 'read_snapshot'},
      );
      if (!mounted) return;
      setState(() {
        _luaOutput = const JsonEncoder.withIndent('  ').convert(result.value);
        _luaLogs = result.logs;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _luaOutput = 'Lua execution failed: $error');
    } finally {
      if (mounted) setState(() => _luaBusy = false);
    }
  }

  @override
  void dispose() {
    _command.dispose();
    _json.dispose();
    super.dispose();
  }

  Future<void> _runCommand() async {
    final command = _command.text.trim();
    if (command.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final result = await widget.onCommand(command);
      if (mounted) {
        setState(() {
          _logs.insert(0, '\$ $command');
          _logs.insert(1, result);
          if (_logs.length > 30) _logs.removeRange(30, _logs.length);
        });
      }
      _command.clear();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _applyJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final decoded = jsonDecode(_json.text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Save JSON must be an object.');
      }
      final save = SaveData.fromJson(decoded);
      await widget.onApplySave(save);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Developer save applied.')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not apply save: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('Developer Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Developer Console',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Try /help, /money 1000000, /prestige 10, /ultra 1, /nebula 100 or /reset.',
          ),
          const SizedBox(height: 12),
          GtnExpressiveTextField(
            controller: _command,
            decoration: const InputDecoration(
              labelText: 'Developer command',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _runCommand(),
          ),
          const SizedBox(height: 8),
          M3EButton.filled(
            onPressed: _busy ? null : _runCommand,
            child: const Text('Run command'),
          ),
          if (_logs.isNotEmpty) ...[
            const SizedBox(height: 12),
            GtnExpressiveCard(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Console output'),
                    const SizedBox(height: 8),
                    for (final line in _logs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SelectableText(line),
                      ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Save Editor (JSON)',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Edit the current slot save directly. Invalid or incompatible JSON is rejected.',
          ),
          const SizedBox(height: 8),
          GtnExpressiveTextField(
            controller: _json,
            minLines: 12,
            maxLines: 24,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              labelText: 'Raw save JSON',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: M3EButton.text(
                  onPressed: _busy
                      ? null
                      : () async {
                          await Clipboard.setData(
                            ClipboardData(text: _json.text),
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Save JSON copied.')),
                          );
                        },
                  child: const Text('Copy JSON'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: M3EButton.filled(
                  onPressed: _busy ? null : _applyJson,
                  child: const Text('Apply JSON to current slot'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _RegisteredLuaScript {
  const _RegisteredLuaScript({
    required this.id,
    required this.file,
    required this.title,
    required this.description,
  });

  final String id;
  final String file;
  final String title;
  final String description;
}
