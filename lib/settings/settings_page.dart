import 'package:material_ui/material_ui.dart';

import '../design/expressive_widgets.dart';
import '../design/gtn_color_picker_dialog.dart';
import '../i18n/app_localizations.dart';
import 'game_settings.dart';

typedef SettingsChanged = Future<void> Function(GameSettings settings);

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
    this.onOpenMenuStudio,
    this.onReplayTutorial,
  });
  final GameSettings settings;
  final SettingsChanged onChanged;
  final VoidCallback? onOpenMenuStudio;
  final VoidCallback? onReplayTutorial;

  void _update(GameSettings next) => onChanged(next);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GtnExpressiveAppBar(
        title: const Text('Settings & Save Management'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _SettingsSection(
            eyebrow: 'GAME PREFERENCES',
            title: 'Game Preferences',
            description: 'Choose the language used for game text and menus.',
            children: [
              _dropdown<String>(
                'Language',
                settings.localeCode,
                [
                  for (final locale in AppLocalizations.supportedLocales)
                    DropdownMenuItem(value: locale.$1, child: Text(locale.$2)),
                ],
                (value) {
                  if (value != null) {
                    _update(settings.copyWith(localeCode: value));
                  }
                },
              ),
            ],
          ),
          _SettingsSection(
            eyebrow: 'THEME APPEARANCE',
            title: 'Theme Appearance',
            description: 'Choose whether the app follows your device theme or uses Dark, Light or AMOLED mode.',
            children: [
              _dropdown<String>(
                'Theme mode',
                settings.themeMode,
                const [
                  DropdownMenuItem(value: 'System', child: Text('System')),
                  DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                  DropdownMenuItem(value: 'Light', child: Text('Light')),
                  DropdownMenuItem(value: 'AMOLED', child: Text('AMOLED')),
                ],
                (value) {
                  if (value != null) {
                    _update(
                      settings.copyWith(
                        themeMode: value,
                        darkMode: value == 'Dark' || value == 'AMOLED',
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          _SettingsSection(
            eyebrow: 'THEME COLORS',
            title: 'Theme Colors',
            description: 'Customize the app’s primary, secondary and tertiary colors. Changes apply immediately.',
            children: [
              Builder(
                builder: (context) {
                  final scheme = Theme.of(context).colorScheme;
                  Color parsePreviewColor(String value, Color fallback) {
                    final parsed = int.tryParse(
                      value.replaceFirst('#', ''),
                      radix: 16,
                    );
                    return parsed == null
                        ? fallback
                        : Color(0xFF000000 | parsed);
                  }

                  final primary = parsePreviewColor(
                    settings.customPrimaryColor,
                    scheme.primary,
                  );
                  final secondary = parsePreviewColor(
                    settings.customSecondaryColor,
                    scheme.secondary,
                  );
                  final tertiary = parsePreviewColor(
                    settings.customTertiaryColor,
                    scheme.tertiary,
                  );
                  return Card(
                    color: scheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Live preview',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nice guess!',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Secret number found. Your streak keeps growing.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: scheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  child: Text(
                                    'Guess',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: scheme.onPrimary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              for (final color in [
                                primary,
                                secondary,
                                tertiary,
                              ])
                                Expanded(
                                  child: Container(
                                    height: 8,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Row(
                children: [
                  for (final hex in [
                    settings.customPrimaryColor,
                    settings.customSecondaryColor,
                    settings.customTertiaryColor,
                  ])
                    Expanded(
                      child: Container(
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: Color(
                            0xFF000000 |
                                (int.tryParse(
                                      hex.replaceFirst('#', ''),
                                      radix: 16,
                                    ) ??
                                    0x7C4DFF),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                ],
              ),
              _dropdown<String>(
                'Theme preset',
                settings.themePreset,
                const [
                  DropdownMenuItem(value: 'Neon', child: Text('Neon')),
                  DropdownMenuItem(value: 'Sunset', child: Text('Sunset')),
                  DropdownMenuItem(value: 'Ocean', child: Text('Ocean')),
                  DropdownMenuItem(value: 'Forest', child: Text('Forest')),
                  DropdownMenuItem(value: 'Custom', child: Text('Custom')),
                ],
                (value) {
                  if (value == null) return;
                  const presets = {
                    'Neon': ['#7C4DFF', '#00BCD4', '#00C853'],
                    'Sunset': ['#FF4081', '#FF9800', '#FFC107'],
                    'Ocean': ['#2196F3', '#00BCD4', '#3F51B5'],
                    'Forest': ['#4CAF50', '#009688', '#8BC34A'],
                  };
                  final colors = presets[value];
                  _update(
                    settings.copyWith(
                      themePreset: value,
                      customPrimaryColor: colors?[0],
                      customSecondaryColor: colors?[1],
                      customTertiaryColor: colors?[2],
                    ),
                  );
                },
              ),
              _ColorSetting(
                label: 'Primary',
                value: settings.customPrimaryColor,
                onSubmitted: (value) => _update(
                  settings.copyWith(
                    themePreset: 'Custom',
                    customPrimaryColor: value,
                  ),
                ),
              ),
              _ColorSetting(
                label: 'Secondary',
                value: settings.customSecondaryColor,
                onSubmitted: (value) => _update(
                  settings.copyWith(
                    themePreset: 'Custom',
                    customSecondaryColor: value,
                  ),
                ),
              ),
              _ColorSetting(
                label: 'Tertiary',
                value: settings.customTertiaryColor,
                onSubmitted: (value) => _update(
                  settings.copyWith(
                    themePreset: 'Custom',
                    customTertiaryColor: value,
                  ),
                ),
              ),
            ],
          ),
          _SettingsSection(
            eyebrow: 'NUMBER NOTATION',
            title: 'Number Notation',
            description: 'Choose how large numbers are displayed: Standard, Scientific or Engineering.',
            children: [
              _dropdown<String>(
                'Number notation',
                settings.numberNotation,
                const [
                  DropdownMenuItem(value: 'Standard', child: Text('Standard')),
                  DropdownMenuItem(
                    value: 'Scientific',
                    child: Text('Scientific'),
                  ),
                  DropdownMenuItem(
                    value: 'Engineering',
                    child: Text('Engineering'),
                  ),
                ],
                (value) {
                  if (value != null) {
                    _update(settings.copyWith(numberNotation: value));
                  }
                },
              ),
            ],
          ),
          _SettingsSection(
            eyebrow: 'PUSH NOTIFICATIONS & REMINDERS',
            title: 'Push Notifications & Reminders',
            description: 'Enable optional game reminders and notifications. You can turn them off at any time.',
            children: [
              _toggle(
                'Notifications',
                settings.notificationsEnabled,
                (value) =>
                    _update(settings.copyWith(notificationsEnabled: value)),
              ),
              if (settings.notificationsEnabled) ...[
                _dropdown<int>(
                  'Reminder Frequency',
                  settings.notificationIntervalHours,
                  const [
                    DropdownMenuItem(value: 12, child: Text('12 Hours')),
                    DropdownMenuItem(value: 24, child: Text('24 Hours')),
                    DropdownMenuItem(value: 48, child: Text('48 Hours')),
                  ],
                  (value) {
                    if (value != null) {
                      _update(
                        settings.copyWith(notificationIntervalHours: value),
                      );
                    }
                  },
                ),
                _toggle(
                  'Reminders',
                  settings.notificationRemindersEnabled,
                  (value) => _update(
                    settings.copyWith(notificationRemindersEnabled: value),
                  ),
                ),
                _toggle(
                  'Progression milestones',
                  settings.notificationProgressionEnabled,
                  (value) => _update(
                    settings.copyWith(notificationProgressionEnabled: value),
                  ),
                ),
                _toggle(
                  'Game events',
                  settings.notificationEventsEnabled,
                  (value) => _update(
                    settings.copyWith(notificationEventsEnabled: value),
                  ),
                ),
              ],
            ],
          ),
          _SettingsSection(
            eyebrow: 'SOUND FX',
            title: 'Sound FX',
            description:
                'Turn sound effects for in-game interactions on or off.',
            children: [
              _toggle(
                'Sound effects',
                settings.soundEnabled,
                (value) => _update(settings.copyWith(soundEnabled: value)),
              ),
              _toggle(
                'Vibration',
                settings.vibrationEnabled,
                (value) => _update(settings.copyWith(vibrationEnabled: value)),
              ),
            ],
          ),
          _SettingsSection(
            eyebrow: 'VISUAL COMFORT & ACCESSIBILITY',
            title: 'Visual comfort & accessibility',
            description:
                'Reduce flashes and soften animated screen transitions.',
            children: [
              _toggle(
                'Reduce Flashes',
                settings.reduceFlashes,
                (value) => _update(settings.copyWith(reduceFlashes: value)),
              ),
              _toggle(
                'Reduced Motion',
                settings.reduceMotion,
                (value) => _update(settings.copyWith(reduceMotion: value)),
              ),
            ],
          ),
          _SettingsSection(
            eyebrow: 'AUDIO LEVELS',
            title: 'Volume',
            description: 'Adjust the app and sound-effect audio levels.',
            children: [
              _SettingsSlider(
                label: 'Master Volume',
                value: settings.volume,
                onChanged: (value) => _update(settings.copyWith(volume: value)),
              ),
              _SettingsSlider(
                label: 'Sound Effects Volume',
                value: settings.sfxVolume,
                onChanged: settings.soundEnabled
                    ? (value) => _update(settings.copyWith(sfxVolume: value))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>(
    String label,
    T value,
    List<DropdownMenuItem<T>> items,
    ValueChanged<T?> onChanged,
  ) => GtnExpressiveDropdown<T>(
    initialValue: value,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: items,
    onChanged: onChanged,
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      GtnExpressiveSwitchTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
      );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.children,
  });
  final String eyebrow, title, description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GtnExpressiveCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: GtnUiTokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            eyebrow,
            style: const TextStyle(
              color: GtnUiTokens.cyan,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final double value;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label · ${(value * 100).round()}%'),
      Slider(value: value, min: 0, max: 1, onChanged: onChanged),
    ],
  );
}

class _ColorSetting extends StatelessWidget {
  const _ColorSetting({
    required this.label,
    required this.value,
    required this.onSubmitted,
  });
  final String label, value;
  final ValueChanged<String> onSubmitted;

  Color get _color {
    final normalized = value.replaceFirst('#', '');
    final parsed = int.tryParse(normalized, radix: 16) ?? 0x7C4DFF;
    return Color(0xFF000000 | parsed);
  }

  Future<void> _showPicker(BuildContext context) async {
    final result = await showGtnColorPickerDialog(
      context,
      initialHex: value,
      title: 'Choose $label',
    );
    if (result?.hex != null) onSubmitted(result!.hex!);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(
                value.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _showPicker(context),
          icon: const Icon(Icons.colorize_rounded),
          label: const Text('Choose'),
        ),
      ],
    ),
  );
}
