import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/legacy/trait_catalog_repository.dart';
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
    this.loadTraitCatalog,
  });

  final SaveData save;
  final DeveloperCommand onCommand;
  final DeveloperSaveApply onApplySave;
  final Future<List<TraitCatalogEntry>> Function()? loadTraitCatalog;

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
  late final Future<List<_RegisteredLuaScript>> _luaScripts = _loadLuaScripts();
  String? _selectedLuaScriptId;
  bool _luaBusy = false;
  String? _luaOutput;
  List<String> _luaLogs = [];
  final _traitSearch = TextEditingController();
  final _diagnosticSearch = TextEditingController();
  String _diagnosticLevel = 'ALL';
  final List<_DeveloperDiagnosticEntry> _diagnostics = [];
  late final Future<List<TraitCatalogEntry>> _traitCatalog =
      widget.loadTraitCatalog?.call() ?? TraitCatalogRepository().load();

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
          entry['file'] is! String ||
          entry['title'] is! String) {
        throw const FormatException('Invalid registered Lua script entry.');
      }
      final id = entry['id'] as String;
      final validId =
          id.isNotEmpty &&
          id.length <= 64 &&
          id.codeUnits.first >= 97 &&
          id.codeUnits.first <= 122 &&
          id.codeUnits.every(
            (unit) =>
                (unit >= 97 && unit <= 122) ||
                (unit >= 48 && unit <= 57) ||
                unit == 95,
          );
      if (!validId) {
        throw const FormatException('Invalid registered Lua script ID.');
      }
      final file = entry['file'] as String;
      if (!file.endsWith('.lua') ||
          file.startsWith('/') ||
          file.split('/').contains('..') ||
          file.contains(String.fromCharCode(92))) {
        throw const FormatException('Invalid Lua script asset path.');
      }
      scripts.add(
        _RegisteredLuaScript(
          id: id,
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

  Future<void> _runRegisteredLuaScript(_RegisteredLuaScript script) async {
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
          'failed_guesses':
              (progression.totalGuesses - progression.correctGuesses)
                  .toString(),
          'current_streak': progression.currentStreak.toString(),
          'best_streak': progression.bestStreak.toString(),
          'long_streaks_observed': profile.longStreaksObserved.toString(),
          'accuracy_score': profile.accuracyScore.toString(),
          'prestige_count': progression.prestigeResets.toString(),
          'ultra_count': progression.ultraResets.toString(),
          'first_prestige_awarded':
              profile.awardedBonuses.contains('first_prestige_bonus')
              ? '1'
              : '0',
          'first_ultra_awarded':
              profile.awardedBonuses.contains('first_ultra_bonus') ? '1' : '0',
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
      _recordDiagnostic(
        'INFO',
        'LUA_SCRIPT_COMPLETED',
        'Executed ${script.id}; ${result.logs.length} log lines returned.',
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _luaOutput = 'Lua execution failed: $error');
      _recordDiagnostic('ERROR', 'LUA_SCRIPT_FAILED', '${script.id}: $error');
    } finally {
      if (mounted) setState(() => _luaBusy = false);
    }
  }

  @override
  void dispose() {
    _command.dispose();
    _json.dispose();
    _traitSearch.dispose();
    _diagnosticSearch.dispose();
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
        _recordDiagnostic('INFO', 'COMMAND_EXECUTED', command);
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
      _recordDiagnostic(
        'INFO',
        'SAVE_JSON_APPLIED',
        'Applied schema ${save.schemaVersion} save data to the current slot.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Developer save applied.')),
        );
      }
    } on Object catch (error) {
      _recordDiagnostic('ERROR', 'SAVE_JSON_REJECTED', error.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not apply save: $error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _recordDiagnostic(String level, String event, String message) {
    if (!mounted) return;
    setState(() {
      _diagnostics.insert(
        0,
        _DeveloperDiagnosticEntry(
          timestamp: DateTime.now(),
          level: level,
          event: event,
          message: message,
        ),
      );
      if (_diagnostics.length > 200) {
        _diagnostics.removeRange(200, _diagnostics.length);
      }
    });
  }

  Widget _buildTraitRegistryInspector() {
    return FutureBuilder<List<TraitCatalogEntry>>(
      future: _traitCatalog,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const GtnExpressiveCard(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: LinearProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return GtnExpressiveCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Trait catalog failed validation: ${snapshot.error}'),
            ),
          );
        }
        final traits = snapshot.data ?? const <TraitCatalogEntry>[];
        final query = _traitSearch.text.trim().toLowerCase();
        final filtered = traits
            .where((trait) {
              if (query.isEmpty) return true;
              return <String>[
                trait.id,
                trait.title,
                trait.description,
                trait.category,
                trait.catalogId,
                trait.packageFolder,
                trait.visibility,
                ...trait.effects,
                ...trait.dependencies,
                ...trait.conflicts,
                trait.seasonId ?? '',
              ].any((value) => value.toLowerCase().contains(query));
            })
            .toList(growable: false);
        final hidden = traits.where((trait) => trait.isHidden).length;
        final discovered =
            widget.save.progression.legacySystems.discoveredTraits;
        return GtnExpressiveCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trait Registry Inspector',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${traits.length} validated GTN1 traits · ${traits.length - hidden} visible · $hidden hidden',
                ),
                Text(
                  '${discovered.length} discovered in this save · pinned source ${TraitCatalogRepository.sourceCommit.substring(0, 8)}',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _traitSearch,
                  decoration: InputDecoration(
                    labelText: 'Search ID, title, category, effect or season',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _traitSearch.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear trait search',
                            onPressed: () {
                              _traitSearch.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  'Showing ${filtered.length > 40 ? 40 : filtered.length} of ${filtered.length} matching traits',
                ),
                const Divider(),
                if (filtered.isEmpty)
                  const Text('No traits match this search.')
                else
                  for (final trait in filtered.take(40)) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  trait.title,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                              ),
                              Text(
                                trait.isHidden ? 'HIDDEN' : 'VISIBLE',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                          SelectableText(trait.id),
                          Text(
                            '${trait.category} · ${trait.catalogId} · ${trait.packageFolder}',
                          ),
                          Text('Effects: ${trait.effects.join(', ')}'),
                          Text(
                            'Requirements: level ${trait.minimumLevel} · prestige ${trait.minimumPrestige} · ${trait.minimumCorrectGuesses} correct guesses',
                          ),
                          if (trait.dependencies.isNotEmpty)
                            Text(
                              'Dependencies: ${trait.dependencies.join(', ')}',
                            ),
                          if (trait.conflicts.isNotEmpty)
                            Text('Conflicts: ${trait.conflicts.join(', ')}'),
                          if (trait.seasonId != null)
                            Text('Season: ${trait.seasonId}'),
                          Text(
                            discovered.contains(trait.id)
                                ? 'Discovered in current save'
                                : 'Not discovered in current save',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                if (filtered.length > 40)
                  const Text(
                    'Refine the search to inspect additional entries.',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRuntimeInspector() {
    final progression = widget.save.progression;
    return GtnExpressiveCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Runtime Inspector',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _runtimeValue('Platform', Platform.operatingSystem),
            _runtimeValue('OS version', Platform.operatingSystemVersion),
            _runtimeValue('Dart runtime', Platform.version.split(' ').first),
            _runtimeValue('Debug build', kDebugMode ? 'Yes' : 'No'),
            _runtimeValue(
              'Available processors',
              Platform.numberOfProcessors.toString(),
            ),
            _runtimeValue('Save schema', widget.save.schemaVersion.toString()),
            _runtimeValue(
              'Current range',
              '${widget.save.minimum}–${widget.save.maximum}',
            ),
            _runtimeValue('Total guesses', progression.totalGuesses.toString()),
            _runtimeValue(
              'Lua execution budget',
              '${_luaSandbox.executionBudget.inMilliseconds} ms',
            ),
            _runtimeValue(
              'Lua source limit',
              '${LuaSandbox.maxSourceCharacters} characters',
            ),
            _runtimeValue(
              'Lua result limit',
              '${LuaSandbox.maxResultNodes} nodes / depth ${LuaSandbox.maxResultDepth}',
            ),
            const SizedBox(height: 6),
            const Text(
              'Read-only process and save diagnostics. No process memory or private filesystem data is collected.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _runtimeValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 142,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }

  Widget _buildDiagnosticLogViewer() {
    final query = _diagnosticSearch.text.trim().toLowerCase();
    final filtered = _diagnostics
        .where((entry) {
          final matchesLevel =
              _diagnosticLevel == 'ALL' || entry.level == _diagnosticLevel;
          final matchesQuery =
              query.isEmpty ||
              entry.event.toLowerCase().contains(query) ||
              entry.message.toLowerCase().contains(query) ||
              entry.level.toLowerCase().contains(query);
          return matchesLevel && matchesQuery;
        })
        .toList(growable: false);
    final export = filtered.map((entry) => entry.toLogLine()).join('\n');
    return GtnExpressiveCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Diagnostic Log Viewer',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              '${filtered.length} matching entries · in-memory developer session · max 200',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _diagnosticSearch,
              decoration: const InputDecoration(
                labelText: 'Filter event, level or message',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _diagnosticLevel,
              decoration: const InputDecoration(
                labelText: 'Log level',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('All levels')),
                DropdownMenuItem(value: 'INFO', child: Text('Info')),
                DropdownMenuItem(value: 'ERROR', child: Text('Error')),
              ],
              onChanged: (value) =>
                  setState(() => _diagnosticLevel = value ?? 'ALL'),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                M3EButton.text(
                  onPressed: filtered.isEmpty
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: export));
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Diagnostic logs copied.'),
                            ),
                          );
                        },
                  child: const Text('Copy filtered logs'),
                ),
                M3EButton.text(
                  onPressed: _diagnostics.isEmpty
                      ? null
                      : () => setState(_diagnostics.clear),
                  child: const Text('Clear logs'),
                ),
              ],
            ),
            const Divider(),
            if (filtered.isEmpty)
              const Text(
                'No diagnostic entries yet. Run a developer command, execute a Lua script or apply save JSON to create entries.',
              )
            else
              for (final entry in filtered.take(80))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: SelectableText(entry.toLogLine()),
                ),
            if (filtered.length > 80)
              const Text('Showing the newest 80 matching entries.'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: const Text('Developer Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTraitRegistryInspector(),
          const SizedBox(height: 16),
          _buildRuntimeInspector(),
          const SizedBox(height: 16),
          _buildDiagnosticLogViewer(),
          const SizedBox(height: 24),
          Text('Lua Console', style: Theme.of(context).textTheme.titleLarge),
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
              final selectedId =
                  scripts.any((script) => script.id == _selectedLuaScriptId)
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
                        initialValue: selectedId,
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
                        for (final line in _luaLogs) SelectableText(line),
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

class _DeveloperDiagnosticEntry {
  const _DeveloperDiagnosticEntry({
    required this.timestamp,
    required this.level,
    required this.event,
    required this.message,
  });

  final DateTime timestamp;
  final String level;
  final String event;
  final String message;

  String toLogLine() {
    final time = timestamp.toLocal().toIso8601String();
    return '[$time][$level][$event] $message';
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
