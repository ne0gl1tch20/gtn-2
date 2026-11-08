import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

import '../core/lua/lua_script_engine.dart';

class LuaTestingHubPage extends StatefulWidget {
  const LuaTestingHubPage({
    super.key,
    this.engine,
  });

  final LuaEngine? engine;

  @override
  State<LuaTestingHubPage> createState() => _LuaTestingHubPageState();
}

class _LuaTestingHubPageState extends State<LuaTestingHubPage> {
  late final LuaEngine _engine = widget.engine ?? LuaEngine();
  final TextEditingController _command = TextEditingController(text: '/lua help');
  List<LuaScriptEntry> _scripts = const [];
  LuaEngineStatus? _status;
  String _output = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) _refresh();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final scripts = await _engine.listScripts();
      final status = _engine.status();
      if (!mounted) return;
      setState(() {
        _scripts = scripts;
        _status = status;
        _output = 'Script list and runtime status refreshed.';
      });
    } catch (error) {
      if (mounted) setState(() => _output = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runCommand() async {
    if (_busy || _command.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final result = await _engine.executeConsoleCommand(_command.text);
      if (!mounted) return;
      setState(() {
        _output = result;
        _status = _engine.status();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _runScript(LuaScriptEntry script) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await _engine.start(script.id);
      if (!mounted) return;
      setState(() {
        _output = result.isStarted
            ? 'Started ${result.activity!.title} (instance ${result.activity!.instanceId}).'
            : 'Script rejected: ${result.reason}';
        _status = _engine.status();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _stop() {
    final stopped = _engine.stop();
    setState(() {
      _status = _engine.status();
      _output = stopped
          ? 'Active Lua activity stopped.'
          : 'No Lua activity was running.';
    });
  }

  @override
  void dispose() {
    _engine.stop();
    _command.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lua Testing Hub')),
        body: const Center(
          child: Text('This developer-only screen is unavailable in release builds.'),
        ),
      );
    }

    final status = _status;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Lua Testing Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Runtime status', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(status?.runtimeAvailable == true ? 'Ready' : 'Unavailable'),
                  Text('Host API version: ${status?.hostApiVersion ?? LuaEngine.hostApiVersion}'),
                  Text('Active instance: ${status?.activeInstanceId ?? 'none'}'),
                  if (status?.lastError != null)
                    Text(
                      'Last error: ${status!.lastError}',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    'Registered scripts run through the same restricted Lua engine as Activity Hub. Raw Lua evaluation is disabled.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _command,
            decoration: const InputDecoration(
              labelText: 'Typed Lua command',
              hintText: '/lua help',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _runCommand(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _runCommand,
                  child: const Text('Run command'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _refresh,
                  child: const Text('Refresh status'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : _stop,
            icon: const Icon(Icons.stop_rounded),
            label: const Text('Stop active activity'),
          ),
          if (_output.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: SelectableText(_output),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Registered scripts (${_scripts.length})',
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final script in _scripts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(script.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(script.description),
                    const SizedBox(height: 4),
                    Text('ID: ${script.id}'),
                    Text('Source: ${script.source} · Host API v${script.hostApiVersion}'),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: _busy || status?.activeInstanceId != null
                          ? null
                          : () => _runScript(script),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Test script'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
