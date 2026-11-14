import 'package:flutter/material.dart';

import '../core/game/game_engine.dart';
import '../core/progression/progression_state.dart';
import '../shop/upgrade_catalog.dart';
import '../design/expressive_widgets.dart';
import '../i18n/app_localizations.dart';

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
  String _t(String key, String fallback) =>
      AppLocalizations.text(key, fallback);

  String _localizedUpgradeName(GameUpgrade upgrade) {
    final id = upgrade.definition.id;
    final key = switch (_upgradeKey(upgrade).split(':').first) {
      'upgradeLevel' => 'upgrade_${id}_name',
      'prestigeUpgradeLevel' => 'prestige_${id}_name',
      'ultraUpgradeLevel' => 'ultra_${id}_name',
      _ => id,
    };
    return _t(key, upgrade.name);
  }

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
    'correctGuesses' => widget.game.correctGuesses.toString(),
    'streak' => widget.game.streak.toString(),
    'bestStreak' => widget.game.bestStreak.toString(),
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
      setState(
        () => _status = _t(
          'web_ui_enter_a_valid_range_from_1_to_1_000_000',
          'Enter a valid range from 1 to 1,000,000.',
        ),
      );
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
      _status = '${_t('web_ui_saving', 'Saving')}…';
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

  Widget _field(
    String key,
    String label, {
    bool numeric = false,
    int? maxLength,
  }) => TextField(
    controller: _controller(key),
    focusNode: _focusNode(key),
    enabled: !_saving,
    maxLength: maxLength,
    keyboardType: numeric ? TextInputType.number : TextInputType.text,
    decoration: InputDecoration(
      labelText: label,
      isDense: true,
      counterText: '',
      border: const OutlineInputBorder(),
    ),
  );

  Widget _upgradeGroup(
    String title,
    List<GameUpgrade> upgrades, {
    required String emptyText,
  }) {
    if (upgrades.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(emptyText),
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
                      Text(
                        _localizedUpgradeName(upgrade),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${_t('web_ui_level', 'Level')} ${_levelFor(upgrade)} / ${upgrade.definition.maxLevel ?? 0}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: Semantics(
                    label: _t(
                      'web_creative_level_aria',
                      'Creative level for %s',
                    ).replaceFirst('%s', _localizedUpgradeName(upgrade)),
                    child: TextField(
                      controller: _controller(
                        _upgradeKey(upgrade),
                        _levelFor(upgrade).toString(),
                      ),
                      focusNode: _focusNode(_upgradeKey(upgrade)),
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      maxLength: 7,
                      decoration: InputDecoration(
                        labelText: _t('web_ui_level', 'Level'),
                        counterText: '',
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56,
                  child: M3EButton.filled(
                    onPressed: _saving
                        ? null
                        : () => _applyValue(_upgradeKey(upgrade)),
                    child: Text(_t('web_ui_set', 'Set')),
                  ),
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
      margin: const EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.all(
        (MediaQuery.sizeOf(context).width * 0.04).clamp(16.0, 24.0),
      ),
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
                      _t('web_ui_creative_save', 'CREATIVE SAVE'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Creative Tools',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: (MediaQuery.sizeOf(context).width * 0.055)
                            .clamp(20.0, 26.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'web_ui_changes_are_validated_and_saved_by_the_android_game_upda',
              'Changes are validated and saved by the Android game. Updating the range starts a fresh guessing round.',
            ),
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 14),
          if (MediaQuery.sizeOf(context).width <= 390)
            Column(
              children: [
                _field(
                  'rangeMin',
                  _t('web_ui_range_minimum', 'Range minimum'),
                  numeric: true,
                  maxLength: 7,
                ),
                const SizedBox(height: 10),
                _field(
                  'rangeMax',
                  _t('web_ui_range_maximum', 'Range maximum'),
                  numeric: true,
                  maxLength: 7,
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _field(
                    'rangeMin',
                    _t('web_ui_range_minimum', 'Range minimum'),
                    numeric: true,
                    maxLength: 7,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    'rangeMax',
                    _t('web_ui_range_maximum', 'Range maximum'),
                    numeric: true,
                    maxLength: 7,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: M3EButton.filled(
              onPressed: _saving ? null : _applyRange,
              child: const Text('Apply range'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _t('web_ui_game_values', 'Game values'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _t(
              'web_ui_set_currencies_and_run_counters_directly_values_are_chec',
              'Set currencies and run counters directly. Values are checked before saving.',
            ),
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width <= 390 ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: [
              _field(
                'money',
                _t('builder_kind_money', 'Money'),
                maxLength: 100,
              ),
              _field('prestige', _t('prestige', 'Prestige'), maxLength: 100),
              _field(
                'ultra',
                _t('currency_ultra_label', 'Ultra'),
                maxLength: 100,
              ),
              _field(
                'nebula',
                _t('currency_nebula_label', 'Nebula'),
                maxLength: 100,
              ),
              _field(
                'attempts',
                _t('web_ui_attempts_2', 'Attempts'),
                numeric: true,
                maxLength: 13,
              ),
              _field(
                'correctGuesses',
                _t('web_ui_correct_guesses', 'Correct guesses'),
                numeric: true,
                maxLength: 13,
              ),
              _field(
                'streak',
                _t('web_ui_current_streak', 'Current streak'),
                numeric: true,
                maxLength: 7,
              ),
              _field(
                'bestStreak',
                _t('web_ui_best_streak', 'Best streak'),
                numeric: true,
                maxLength: 7,
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width <= 390 ? 1 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 3.2,
            children: [
              for (final item in [
                ('money', _t('web_creative_set_money', 'Set money')),
                ('prestige', _t('web_creative_set_prestige', 'Set prestige')),
                ('ultra', _t('web_creative_set_ultra', 'Set ultra')),
                ('nebula', _t('web_creative_set_nebula', 'Set nebula')),
                ('attempts', _t('web_creative_set_attempts', 'Set attempts')),
                (
                  'correctGuesses',
                  _t('web_creative_set_correct_guesses', 'Set correct guesses'),
                ),
                ('streak', _t('web_creative_set_streak', 'Set streak')),
                (
                  'bestStreak',
                  _t('web_creative_set_best_streak', 'Set best streak'),
                ),
              ])
                M3EButton.outlined(
                  onPressed: _saving ? null : () => _applyValue(item.$1),
                  child: Text(item.$2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _t(
              'web_ui_set_owned_upgrade_levels_directly_within_each_upgrade_s',
              'Set owned upgrade levels directly, within each upgrade’s configured maximum.',
            ),
          ),
          _upgradeGroup(
            _t('web_ui_upgrade_levels', 'Upgrade levels'),
            UpgradeCatalog.all,
            emptyText: _t(
              'web_ui_upgrade_catalog_unavailable',
              'Upgrade catalog unavailable.',
            ),
          ),
          _upgradeGroup(
            _t('web_ui_prestige_upgrades', 'Prestige upgrades'),
            UpgradeCatalog.prestige,
            emptyText: _t(
              'web_ui_prestige_upgrade_catalog_unavailable',
              'Prestige upgrade catalog unavailable.',
            ),
          ),
          _upgradeGroup(
            _t('web_ui_ultra_upgrades', 'Ultra upgrades'),
            UpgradeCatalog.ultra,
            emptyText: _t(
              'web_ui_ultra_upgrade_catalog_unavailable',
              'Ultra upgrade catalog unavailable.',
            ),
          ),
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
