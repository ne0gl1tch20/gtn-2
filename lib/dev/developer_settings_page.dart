import 'dart:convert';

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../data/saves/save_data.dart';
import '../design/expressive_widgets.dart';
import 'jui_preview_page.dart';

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
          const SizedBox(height: 12),
          M3EButton.filled(
            onPressed: _busy
                ? null
                : () async {
                    await Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => const JuiPreviewPage(),
                      ),
                    );
                  },
            child: const Text('Open JUI screen preview'),
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
          M3EButton.filled(
            onPressed: _busy ? null : _applyJson,
            child: const Text('Apply JSON to current slot'),
          ),
        ],
      ),
    );
  }
}
