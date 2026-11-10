import 'package:material_ui/material_ui.dart';

import '../core/game/difficulty_rules.dart';
import '../design/expressive_widgets.dart';
import '../i18n/app_localizations.dart';
import 'game_settings.dart';

typedef SettingsChanged = Future<void> Function(GameSettings settings);

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.settings, required this.onChanged, this.onOpenMenuStudio});
  final GameSettings settings;
  final SettingsChanged onChanged;
  final VoidCallback? onOpenMenuStudio;

  void _update(GameSettings next) => onChanged(next);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: Text(AppLocalizations.text('settings', 'Settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('GAME PREFERENCES', style: TextStyle(color: GtnUiTokens.cyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.4)),
              const SizedBox(height: 5),
              Text('Settings', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -.8)),
              const SizedBox(height: 5),
              Text('Customize how Guess The Number looks and plays.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
            ]),
          ),
          _SettingsSection(eyebrow: '01 / LANGUAGE & NUMBERS', title: 'Language & Numbers', description: 'Choose the language and how large values are displayed.', children: [
            _dropdown<String>('Language', settings.localeCode, [for (final locale in AppLocalizations.supportedLocales) DropdownMenuItem(value: locale.$1, child: Text(locale.$2))], (v) { if (v != null) _update(settings.copyWith(localeCode: v)); }),
            _dropdown<String>('Number notation', settings.numberNotation, const [DropdownMenuItem(value: 'Standard', child: Text('Standard')), DropdownMenuItem(value: 'Scientific', child: Text('Scientific')), DropdownMenuItem(value: 'Engineering', child: Text('Engineering'))], (v) { if (v != null) _update(settings.copyWith(numberNotation: v)); }),
            _dropdown<String>('Difficulty', settings.difficultyId, [for (final id in DifficultyRules.ids) DropdownMenuItem(value: id, child: Text(DifficultyRules.name(id)))], (v) { if (v != null) _update(settings.copyWith(difficultyId: v)); }),
          ]),
          _SettingsSection(eyebrow: '02 / APPEARANCE', title: 'Appearance', description: 'Tune the theme while keeping the original GTN cosmic identity.', children: [
            _dropdown<String>('Theme mode', settings.themeMode, const [DropdownMenuItem(value: 'System', child: Text('System')), DropdownMenuItem(value: 'Dark', child: Text('Dark')), DropdownMenuItem(value: 'Light', child: Text('Light')), DropdownMenuItem(value: 'AMOLED', child: Text('AMOLED'))], (v) { if (v != null) _update(settings.copyWith(themeMode: v, darkMode: v == 'Dark' || v == 'AMOLED')); }),
            _dropdown<String>('Theme preset', settings.themePreset, const [DropdownMenuItem(value: 'Neon', child: Text('Neon')), DropdownMenuItem(value: 'Sunset', child: Text('Sunset')), DropdownMenuItem(value: 'Ocean', child: Text('Ocean')), DropdownMenuItem(value: 'Forest', child: Text('Forest')), DropdownMenuItem(value: 'Custom', child: Text('Custom'))], (v) {
              if (v == null) return;
              const presets = {'Neon': ['#7C4DFF', '#00BCD4', '#00C853'], 'Sunset': ['#FF4081', '#FF9800', '#FFC107'], 'Ocean': ['#2196F3', '#00BCD4', '#3F51B5'], 'Forest': ['#4CAF50', '#009688', '#8BC34A']};
              final colors = presets[v];
              _update(settings.copyWith(themePreset: v, customPrimaryColor: colors?[0], customSecondaryColor: colors?[1], customTertiaryColor: colors?[2]));
            }),
            _ColorSetting(label: 'Primary color', value: settings.customPrimaryColor, onSubmitted: (v) => _update(settings.copyWith(themePreset: 'Custom', customPrimaryColor: v))),
            _ColorSetting(label: 'Secondary color', value: settings.customSecondaryColor, onSubmitted: (v) => _update(settings.copyWith(themePreset: 'Custom', customSecondaryColor: v))),
            _ColorSetting(label: 'Tertiary color', value: settings.customTertiaryColor, onSubmitted: (v) => _update(settings.copyWith(themePreset: 'Custom', customTertiaryColor: v))),
          ]),
          _SettingsSection(eyebrow: '03 / AUDIO & HAPTICS', title: 'Audio & Haptics', description: 'Control background music, effects and interaction feedback.', children: [
            _toggle('Background music', settings.musicEnabled, (v) => _update(settings.copyWith(musicEnabled: v))),
            _toggle('Sound effects', settings.soundEnabled, (v) => _update(settings.copyWith(soundEnabled: v))),
            _toggle('Vibration', settings.vibrationEnabled, (v) => _update(settings.copyWith(vibrationEnabled: v))),
            _SettingsSlider(label: 'Master volume', value: settings.volume, onChanged: (v) => _update(settings.copyWith(volume: v))),
            _SettingsSlider(label: 'Sound effects volume', value: settings.sfxVolume, onChanged: (v) => _update(settings.copyWith(sfxVolume: v))),
          ]),
          _SettingsSection(eyebrow: '04 / NOTIFICATIONS', title: 'Notifications', description: 'Preferences are saved. Scheduled delivery still needs platform integration.', children: [
            _toggle('Game reminders', settings.notificationsEnabled, (v) => _update(settings.copyWith(notificationsEnabled: v))),
            _dropdown<int>('Reminder frequency', settings.notificationIntervalHours, const [DropdownMenuItem(value: 12, child: Text('12 hours')), DropdownMenuItem(value: 24, child: Text('24 hours')), DropdownMenuItem(value: 48, child: Text('48 hours'))], (v) { if (v != null) _update(settings.copyWith(notificationIntervalHours: v)); }),
            _toggle('Reminder notifications', settings.notificationRemindersEnabled, (v) => _update(settings.copyWith(notificationRemindersEnabled: v))),
            _toggle('Progression milestones', settings.notificationProgressionEnabled, (v) => _update(settings.copyWith(notificationProgressionEnabled: v))),
            _toggle('Game events', settings.notificationEventsEnabled, (v) => _update(settings.copyWith(notificationEventsEnabled: v))),
          ]),
          _SettingsSection(eyebrow: '05 / UPDATES', title: 'Updates', description: 'Choose how often the app should check for new versions.', children: [
            _dropdown<int>('Automatic update checks', settings.updateCheckIntervalHours, const [DropdownMenuItem(value: 0, child: Text('None')), DropdownMenuItem(value: 1, child: Text('Every hour')), DropdownMenuItem(value: 6, child: Text('Every 6 hours')), DropdownMenuItem(value: 12, child: Text('Every 12 hours')), DropdownMenuItem(value: 24, child: Text('Every 24 hours')), DropdownMenuItem(value: 168, child: Text('Every 7 days'))], (v) { if (v != null) _update(settings.copyWith(updateCheckIntervalHours: v)); }),
            const Text('The preference is stored; background scheduling is not yet connected.', style: TextStyle(color: GtnUiTokens.muted, fontSize: 11)),
          ]),
          _SettingsSection(eyebrow: '06 / ACCESSIBILITY', title: 'Accessibility', description: 'Reduce motion and sudden visual changes.', children: [
            _toggle('Reduced motion', settings.reduceMotion, (v) => _update(settings.copyWith(reduceMotion: v))),
            _toggle('Reduce flashes', settings.reduceFlashes, (v) => _update(settings.copyWith(reduceFlashes: v))),
          ]),
          _SettingsSection(eyebrow: '07 / DEVELOPER & SAVE', title: 'Developer & Save Preferences', description: 'Control diagnostic logging, matching the original GTN1 settings.', children: [
            _toggle('Save logs to storage', settings.saveLogsToStorage, (v) => _update(settings.copyWith(saveLogsToStorage: v))),
            _toggle('Verbose logging', settings.verboseLogging, (v) => _update(settings.copyWith(verboseLogging: v))),
          ]),
          if (onOpenMenuStudio != null)
            GtnExpressiveCard(
              child: ListTile(
                leading: const Icon(Icons.palette_rounded),
                title: const Text('Menu Studio'),
                subtitle: const Text('Reorder More destinations and customize their colors.'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: onOpenMenuStudio,
              ),
            ),
          const Padding(padding: EdgeInsets.fromLTRB(8, 10, 8, 0), child: Text('Preferences are saved with your active game profile. Tutorial replay remains a separate migration task.', style: TextStyle(color: GtnUiTokens.muted, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _dropdown<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) => GtnExpressiveDropdown<T>(
    initialValue: value,
    decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    items: items,
    onChanged: onChanged,
  );

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) => GtnExpressiveSwitchTile(
    title: Text(label), value: value, onChanged: onChanged,
  );
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.eyebrow, required this.title, required this.description, required this.children});
  final String eyebrow, title, description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GtnExpressiveCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: GtnUiTokens.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(eyebrow, style: const TextStyle(color: GtnUiTokens.cyan, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        const SizedBox(height: 5),
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(description, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
        const SizedBox(height: 14),
        ...children,
      ]),
    );
  }
}

class _SettingsSlider extends StatelessWidget {
  const _SettingsSlider({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('${label} · ${(value * 100).round()}%'),
    Slider(value: value, min: 0, max: 1, onChanged: onChanged),
  ]);
}

class _ColorSetting extends StatelessWidget {
  const _ColorSetting({required this.label, required this.value, required this.onSubmitted});
  final String label, value;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) => TextFormField(
    key: ValueKey('${label}-${value}'),
    initialValue: value,
    decoration: InputDecoration(labelText: label, helperText: 'Hex color, for example #9B7CFF', border: const OutlineInputBorder()),
    onFieldSubmitted: (raw) {
      final normalized = raw.trim().toUpperCase();
      if (RegExp(r'^#[0-9A-F]{6}$').hasMatch(normalized)) onSubmitted(normalized);
    },
  );
}
