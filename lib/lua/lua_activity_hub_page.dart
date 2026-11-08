import 'package:flutter/material.dart';

import '../core/lua/lua_script_engine.dart';

class LuaActivityHubPage extends StatefulWidget {
  const LuaActivityHubPage({
    super.key,
    this.engine,
  });

  final LuaEngine? engine;

  @override
  State<LuaActivityHubPage> createState() => _LuaActivityHubPageState();
}

class _LuaActivityHubPageState extends State<LuaActivityHubPage> {
  late final LuaEngine _engine = widget.engine ?? LuaEngine();
  List<LuaScriptEntry> _scripts = const [];
  LuaActivityDefinition? _activity;
  int _selectedAnswer = -1;
  String? _answerMessage;
  String? _feedback;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadScripts();
  }

  Future<void> _loadScripts() async {
    try {
      final scripts = await _engine.listScripts();
      if (!mounted) return;
      setState(() {
        _scripts = scripts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _feedback = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _startFeatured() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _feedback = null;
    });
    final result = await _engine.startFeaturedActivity();
    if (!mounted) return;
    setState(() {
      _activity = result.activity;
      _selectedAnswer = -1;
      _answerMessage = null;
      _feedback = result.reason;
      _busy = false;
    });
  }

  void _submitAnswer() {
    final result = _engine.submitAnswer(_selectedAnswer);
    setState(() {
      if (result.accepted) {
        _answerMessage = result.message;
      } else {
        _feedback = result.message;
      }
    });
  }

  void _finishActivity() {
    _engine.stop(_activity?.instanceId);
    setState(() {
      _activity = null;
      _selectedAnswer = -1;
      _answerMessage = null;
      _feedback = null;
    });
  }

  @override
  void dispose() {
    _engine.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final featured = _scripts.where((script) => script.featured);
    final featuredScript = featured.isEmpty ? null : featured.first;
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Hub')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Script-powered activities',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Quick activities run offline from the app bundle. Scripts are sandboxed and can only return a validated activity.',
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _loading
                        ? 'Loading activities…'
                        : '${_scripts.length} registered activities',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _activity == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Featured activity',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          featuredScript?.title ?? 'No featured activity',
                          style: theme.textTheme.headlineSmall,
                        ),
                        if (featuredScript != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(featuredScript.description),
                          ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: !_loading && !_busy && featuredScript != null
                              ? _startFeatured
                              : null,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.play_arrow_rounded),
                          label: const Text('GO'),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_activity!.title,
                            style: theme.textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        Text(_activity!.description),
                        const Divider(height: 24),
                        Text(_activity!.prompt,
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        RadioGroup<int>(
                          groupValue: _selectedAnswer,
                          onChanged: (value) {
                            if (_answerMessage != null) return;
                            setState(() => _selectedAnswer = value ?? -1);
                          },
                          child: Column(
                            children: [
                              for (var index = 0;
                                  index < _activity!.options.length;
                                  index++)
                                RadioListTile<int>(
                                  contentPadding: EdgeInsets.zero,
                                  value: index,
                                  title: Text(_activity!.options[index]),
                                ),
                            ],
                          ),
                        ),
                        if (_answerMessage == null)
                          FilledButton(
                            onPressed:
                                _selectedAnswer >= 0 ? _submitAnswer : null,
                            child: const Text('Submit answer'),
                          )
                        else ...[
                          Text(_answerMessage!,
                              style: theme.textTheme.titleMedium),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _finishActivity,
                            child: const Text('Done'),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          if (_scripts.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Available scripts', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final script in _scripts)
              Card(
                child: ListTile(
                  title: Text(script.title),
                  subtitle: Text(script.description),
                  trailing: script.featured
                      ? const Icon(Icons.star_rounded)
                      : const Icon(Icons.code_rounded),
                ),
              ),
          ],
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _feedback!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
