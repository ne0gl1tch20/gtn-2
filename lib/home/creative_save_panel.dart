import 'package:flutter/material.dart';

import '../core/game/game_engine.dart';
import '../core/progression/progression_state.dart';
import '../shop/upgrade_catalog.dart';
import '../design/expressive_widgets.dart';

class CreativeSavePanel extends StatefulWidget {
  const CreativeSavePanel({
    super.key,
    required this.game,
    required this.progression,
    required this.onRange,
    required this.onValue,
  });

  final GameState game;
  final ProgressionState progression;
  final Future<bool> Function(int minimum, int maximum) onRange;
  final Future<bool> Function(String key, String value) onValue;

  @override
  State<CreativeSavePanel> createState() => _CreativeSavePanelState();
}

class _CreativeSavePanelState extends State<CreativeSavePanel> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  bool _saving = false;
  String _status = '';

  String _valueFor(String key) => switch (key) {
    'rangeMin' => widget.game.minimum.toString(),
    'rangeMax' => widget.game.maximum.toString(),
    'money' => widget.progression.money.toString(),
    'prestige' => widget.progression.prestige.toString(),
    'ultra' => widget.progression.ultra.toString(),
    'nebula' => widget.progression.nebula.toString(),
    'attempts' => widget.game.attempts.toString(),
    'correctGuesses' => widget.progression.correctGuesses.toString(),
    'streak' => widget.progression.currentStreak.toString(),
    'bestStreak' => widget.progression.bestStreak.toString(),
    _ => '0',
  };

  TextEditingController _controller(String key, [String? value]) {
    return _controllers.putIfAbsent(
      key,
      () => TextEditingController(text: value ?? _valueFor(key)),
    );
  }

  FocusNode _focusNode(String key) =>
      _focusNodes.putIfAbsent(key, FocusNode.new);

  @override
  void didUpdateWidget(covariant CreativeSavePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final key in [
      'rangeMin',
      'rangeMax',
      'money',
      'prestige',
      'ultra',
      'nebula',
      'attempts',
      'correctGuesses',
      'streak',
      'bestStreak',
    ]) {
      final controller = _controllers[key];
      if (controller != null && !(_focusNodes[key]?.hasFocus ?? false)) {
        controller.text = _valueFor(key);
      }
    }
    for (final upgrade in [
      ...UpgradeCatalog.all,
      ...UpgradeCatalog.prestige,
      ...UpgradeCatalog.ultra,
    ]) {
      final key = _upgradeKey(upgrade);
      final controller = _controllers[key];
      if (controller != null && !(_focusNodes[key]?.hasFocus ?? false)) {
        controller.text = _levelFor(upgrade).toString();
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _upgradeKey(GameUpgrade upgrade) {
    final id = upgrade.definition.id;
    if (UpgradeCatalog.prestige.any((item) => item.definition.id == id)) {
      return 'prestigeUpgradeLevel:$id';
    }
    if (UpgradeCatalog.ultra.any((item) => item.definition.id == id)) {
      return 'ultraUpgradeLevel:$id';
    }
    return 'upgradeLevel:$id';
  }

  int _levelFor(GameUpgrade upgrade) {
    final id = upgrade.definition.id;
    if (UpgradeCatalog.prestige.any((item) => item.definition.id == id)) {
      return widget.progression.prestigeUpgrades[id] ?? 0;
    }
    if (UpgradeCatalog.ultra.any((item) => item.definition.id == id)) {
      return widget.progression.ultraUpgrades[id] ?? 0;
    }
    return widget.progression.upgrades[id] ?? 0;
  }

  Future<void> _applyRange() async {
    final minimum = int.tryParse(_controller('rangeMin').text);
    final maximum = int.tryParse(_controller('rangeMax').text);
    if (minimum == null || maximum == null) {
      setState(() => _status = 'Enter whole numbers for the range.');
      return;
    }
    await _run(() => widget.onRange(minimum, maximum));
  }

  Future<void> _applyValue(String key) async {
    await _run(() => widget.onValue(key, _controller(key).text));
  }

  Future<void> _run(Future<bool> Function() action) async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _status = 'Saving…';
    });
    try {
      final saved = await action();
      if (!mounted) return;
      setState(() {
        _status = saved
            ? 'Creative Save updated.'
            : 'That value is invalid or could not be saved.';
      });
    } catch (_) {
      if (mounted) {
        setState(() => _status = 'Could not save this Creative Save change.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String key, String label, {bool numeric = false}) =>
      TextField(
        controller: _controller(key),
        focusNode: _focusNode(key),
        enabled: !_saving,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
      );

  Widget _upgradeGroup(String title, List<GameUpgrade> upgrades) {
    if (upgrades.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text('$title catalog unavailable.'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        for (final upgrade in upgrades)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(upgrade.name),
                      Text(
                        'Level ${_levelFor(upgrade)} / ${upgrade.definition.maxLevel ?? 0}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _controller(
                      _upgradeKey(upgrade),
                      _levelFor(upgrade).toString(),
                    ),
                    focusNode: _focusNode(_upgradeKey(upgrade)),
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Level',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                M3EButton.filled(
                  onPressed: _saving
                      ? null
                      : () => _applyValue(_upgradeKey(upgrade)),
                  child: const Text('Set'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GtnExpressiveCard(
      key: const Key('creative-save-panel'),
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_fix_high_rounded, color: Color(0xFF22D3EE)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CREATIVE SAVE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Creative Tools',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Changes are validated and saved by the Android game. Updating the range starts a fresh guessing round.',
          ),
          const SizedBox(height: 14),
          Text('Number range', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field('rangeMin', 'Range minimum', numeric: true)),
              const SizedBox(width: 10),
              Expanded(child: _field('rangeMax', 'Range maximum', numeric: true)),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: M3EButton.filled(
              onPressed: _saving ? null : _applyRange,
              child: const Text('Apply range'),
            ),
          ),
          const SizedBox(height: 16),
          Text('Game values', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          const Text(
            'Set currencies and run counters directly. Values are checked before saving.',
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width >= 720 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: [
              _field('money', 'Money'),
              _field('prestige', 'Prestige'),
              _field('ultra', 'Ultra'),
              _field('nebula', 'Nebula'),
              _field('attempts', 'Attempts', numeric: true),
              _field('correctGuesses', 'Correct guesses', numeric: true),
              _field('streak', 'Current streak', numeric: true),
              _field('bestStreak', 'Best streak', numeric: true),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in [
                ('money', 'Set money'),
                ('prestige', 'Set prestige'),
                ('ultra', 'Set ultra'),
                ('nebula', 'Set nebula'),
                ('attempts', 'Set attempts'),
                ('correctGuesses', 'Set correct guesses'),
                ('streak', 'Set streak'),
                ('bestStreak', 'Set best streak'),
              ])
                M3EButton.outlined(
                  onPressed: _saving ? null : () => _applyValue(item.$1),
                  child: Text(item.$2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Set owned upgrade levels directly, within each upgrade’s configured maximum.',
          ),
          _upgradeGroup('Upgrade levels', UpgradeCatalog.all),
          _upgradeGroup('Prestige upgrades', UpgradeCatalog.prestige),
          _upgradeGroup('Ultra upgrades', UpgradeCatalog.ultra),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              _status,
              key: const Key('creative-save-status'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
