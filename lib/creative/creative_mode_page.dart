import 'dart:math' show Random;

import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_ui/material_ui.dart';

import '../core/creative/creative_mode.dart';
import '../data/saves/save_data.dart';
import '../data/saves/save_storage.dart';
import '../design/expressive_widgets.dart';

class CreativeModePage extends StatefulWidget {
  const CreativeModePage({super.key, required this.slot, this.storage});

  final int slot;
  final SaveStorage? storage;

  @override
  State<CreativeModePage> createState() => _CreativeModePageState();
}

class _CreativeModePageState extends State<CreativeModePage> {
  final _nameController = TextEditingController();
  final _minimumController = TextEditingController(text: '1');
  final _maximumController = TextEditingController(text: '100');
  final _guessController = TextEditingController();

  SaveStorage? _storage;
  SaveData? _save;
  CreativeModeSave _config = const CreativeModeSave();
  CreativeModeRun? _run;
  int _rangeScale = 1;
  int _extraHints = 0;
  int _attemptLimit = 0;
  bool _loading = true;
  bool _saving = false;
  bool _enabled = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minimumController.dispose();
    _maximumController.dispose();
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final storage =
          widget.storage ??
          await SaveStorage.inApplicationDocuments(slot: widget.slot);
      final save = await storage.load();
      if (save == null) {
        throw StateError('This save slot is empty.');
      }
      final config = save.creativeMode ?? const CreativeModeSave();
      final rules = CreativeModeEffectPolicy.resolve(config);
      if (!mounted) return;
      setState(() {
        _storage = storage;
        _save = save;
        _config = config;
        _run = CreativeModeRuntime.resume(config);
        _nameController.text = config.name;
        _minimumController.text = config.rangeMin.toString();
        _maximumController.text = config.rangeMax.toString();
        _enabled = config.enabled;
        _rangeScale = config.effects
            .where((effect) => effect.type == CreativeEffectType.rangeScale)
            .fold(1, (value, effect) => value * effect.value)
            .clamp(1, 5)
            .toInt();
        _extraHints = config.effects
            .where((effect) => effect.type == CreativeEffectType.extraHints)
            .fold(0, (value, effect) => value + effect.value)
            .clamp(0, 5)
            .toInt();
        _attemptLimit =
            config.effects
                .where(
                  (effect) => effect.type == CreativeEffectType.attemptLimit,
                )
                .map((effect) => effect.value)
                .fold<int?>(
                  null,
                  (value, effect) =>
                      value == null || value > effect ? effect : value,
                ) ??
            0;
        _message = rules == null
            ? 'Creative Mode configuration is invalid.'
            : _run == null
            ? 'Configure your sandbox and start a run.'
            : 'Your previous Creative Mode run has been restored.';
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = 'Could not load this save: $error';
          _loading = false;
        });
      }
    }
  }

  CreativeModeSave? _buildConfig() {
    final minimum = int.tryParse(_minimumController.text);
    final maximum = int.tryParse(_maximumController.text);
    if (minimum == null ||
        maximum == null ||
        minimum < 1 ||
        maximum < minimum ||
        maximum > CreativeModeSave.maxRange) {
      setState(() => _message = 'Enter a valid range from 1 to 1,000,000.');
      return null;
    }
    final effects = <CreativeModeEffect>[];
    if (_rangeScale > 1) {
      effects.add(
        CreativeModeEffect(
          id: 'range-scale',
          type: CreativeEffectType.rangeScale,
          value: _rangeScale,
        ),
      );
    }
    if (_extraHints > 0) {
      effects.add(
        CreativeModeEffect(
          id: 'extra-hints',
          type: CreativeEffectType.extraHints,
          value: _extraHints,
        ),
      );
    }
    if (_attemptLimit > 0) {
      effects.add(
        CreativeModeEffect(
          id: 'attempt-limit',
          type: CreativeEffectType.attemptLimit,
          value: _attemptLimit,
        ),
      );
    }
    final config = CreativeModeSave(
      name: _nameController.text.trim().isEmpty
          ? 'My Creative Mode'
          : _nameController.text.trim(),
      enabled: _enabled,
      rangeMin: minimum,
      rangeMax: maximum,
      effects: effects,
    );
    if (!CreativeModeSave.validate(config)) {
      setState(() => _message = 'The Creative Mode settings are invalid.');
      return null;
    }
    return config;
  }

  Future<void> _saveConfiguration() async {
    if (_saving || _save == null || _storage == null) return;
    final config = _buildConfig();
    if (config == null) return;
    setState(() {
      _saving = true;
      _run = null;
    });
    try {
      final updated = _save!.copyWith(creativeMode: config);
      await _storage!.save(updated);
      if (!mounted) return;
      setState(() {
        _save = updated;
        _config = config;
        _message = 'Creative Mode settings saved to Slot ${widget.slot}.';
      });
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not save settings: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _startRun() async {
    if (_saving) return;
    final config = _buildConfig();
    if (config == null) return;
    if (!config.enabled) {
      setState(() => _message = 'Enable Creative Mode before starting a run.');
      return;
    }
    final rules = CreativeModeEffectPolicy.resolve(config);
    if (rules == null) {
      setState(() => _message = 'Creative Mode configuration is invalid.');
      return;
    }
    final width = rules.rangeMax - rules.rangeMin + 1;
    final target = rules.rangeMin + Random.secure().nextInt(width);
    final run = CreativeModeRuntime.start(config, target);
    if (run == null) {
      setState(() => _message = 'Could not start a run with these settings.');
      return;
    }
    final persisted = CreativeModeRuntime.persist(config, run);
    if (persisted == null) {
      setState(() => _message = 'Could not validate the new run.');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = _save!.copyWith(creativeMode: persisted);
      await _storage!.save(updated);
      if (!mounted) return;
      setState(() {
        _save = updated;
        _config = persisted;
        _run = run;
        _guessController.clear();
        _message = 'New run started. Find the secret number!';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Could not save the new run: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitGuess() async {
    final run = _run;
    if (run == null || _saving) return;
    final guess = int.tryParse(_guessController.text.trim());
    if (guess == null) {
      setState(() => _message = 'Enter a whole number first.');
      return;
    }
    final decision = CreativeModeRuntime.submitGuess(_config, run, guess);
    final message = switch (decision.outcome) {
      CreativeGuessOutcome.tooLow => 'Too low. Try a higher number.',
      CreativeGuessOutcome.tooHigh => 'Too high. Try a lower number.',
      CreativeGuessOutcome.correct =>
        'Correct! You completed this Creative Mode run.',
      CreativeGuessOutcome.outOfRange =>
        'That guess is outside the configured range.',
      CreativeGuessOutcome.attemptLimit =>
        'You have used all allowed attempts.',
      CreativeGuessOutcome.completed =>
        'This run is already complete. Start another run.',
      CreativeGuessOutcome.invalidConfiguration =>
        'The run no longer matches its saved configuration.',
    };
    if (!decision.accepted) {
      setState(() => _message = message);
      return;
    }
    final persisted = CreativeModeRuntime.persist(_config, decision.run);
    if (persisted == null) {
      setState(() => _message = 'The updated run failed validation.');
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = _save!.copyWith(creativeMode: persisted);
      await _storage!.save(updated);
      if (!mounted) return;
      setState(() {
        _save = updated;
        _config = persisted;
        _run = decision.run;
        _guessController.clear();
        _message = message;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _message = 'Could not save this guess: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = CreativeModeEffectPolicy.resolve(_config);
    final run = _run;
    return Scaffold(
      appBar: GtnExpressiveAppBar(
        title: Text('Creative Mode · Slot ${widget.slot}'),
      ),
      body: _loading
          ? const Center(child: M3EProgressIndicator.circular())
          : _save == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_message, textAlign: TextAlign.center),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'A separate sandbox run. It does not award Money, progression or other main-game rewards.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                GtnExpressiveSwitchTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Creative Mode'),
                  subtitle: const Text(
                    'Use a custom range and optional rule modifiers.',
                  ),
                  value: _enabled,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _enabled = value;
                          _run = null;
                        }),
                ),
                GtnExpressiveTextField(
                  controller: _nameController,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Mode name'),
                ),
                Row(
                  children: [
                    Expanded(
                      child: GtnExpressiveTextField(
                        controller: _minimumController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Minimum'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GtnExpressiveTextField(
                        controller: _maximumController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Maximum'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Range scale: $_rangeScale×'),
                M3ESlider(
                  value: _rangeScale.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: '$_rangeScale×',
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _rangeScale = value.round();
                          _run = null;
                        }),
                ),
                Text('Extra hints: $_extraHints'),
                M3ESlider(
                  value: _extraHints.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: '$_extraHints',
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _extraHints = value.round();
                          _run = null;
                        }),
                ),
                Text(
                  _attemptLimit == 0
                      ? 'Attempt limit: unlimited'
                      : 'Attempt limit: $_attemptLimit',
                ),
                M3ESlider(
                  value: _attemptLimit.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  label: _attemptLimit == 0 ? 'Unlimited' : '$_attemptLimit',
                  onChanged: _saving
                      ? null
                      : (value) => setState(() {
                          _attemptLimit = value.round();
                          _run = null;
                        }),
                ),
                const SizedBox(height: 8),
                M3EButton.tonal(
                  onPressed: _saving ? null : _saveConfiguration,
                  child: const Text('Save configuration'),
                ),
                if (rules != null) ...[
                  const SizedBox(height: 8),
                  Text('Effective range: ${rules.rangeMin}–${rules.rangeMax}'),
                  Text('Available hint credits: ${rules.extraHints}'),
                  Text('Attempt limit: ${rules.attemptLimit ?? 'Unlimited'}'),
                ],
                const Divider(height: 32),
                Text('Play', style: Theme.of(context).textTheme.titleLarge),
                M3EButton.filled(
                  onPressed: _saving || !_enabled ? null : _startRun,
                  child: const Text('Start new run'),
                ),
                if (run != null) ...[
                  const SizedBox(height: 12),
                  GtnExpressiveCard(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            run.completed ? 'Run complete' : 'Run in progress',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text('Attempts: ${run.attemptsUsed}'),
                          Text('Correct guesses: ${run.correctGuesses}'),
                          Text(
                            'Hints used: ${run.hintsUsed} / ${rules?.extraHints ?? 0}',
                          ),
                          const SizedBox(height: 12),
                          GtnExpressiveTextField(
                            controller: _guessController,
                            keyboardType: TextInputType.number,
                            enabled: !run.completed && !_saving,
                            decoration: const InputDecoration(
                              labelText: 'Your guess',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _submitGuess(),
                          ),
                          const SizedBox(height: 8),
                          M3EButton.filled(
                            onPressed: run.completed || _saving
                                ? null
                                : _submitGuess,
                            child: const Text('Submit guess'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Text(_message),
                if (_saving) const M3EProgressIndicator.linearWavy(),
              ],
            ),
    );
  }
}
