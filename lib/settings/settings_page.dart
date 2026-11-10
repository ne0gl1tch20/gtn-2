import 'package:material_ui/material_ui.dart';

import '../core/game/difficulty_rules.dart';
import '../design/expressive_widgets.dart';
import '../i18n/app_localizations.dart';
import 'game_settings.dart';

typedef SettingsChanged = Future<void> Function(GameSettings settings);

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final GameSettings settings;
  final SettingsChanged onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GtnExpressiveAppBar(
        title: Text(AppLocalizations.text('settings', 'Settings')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 28),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'GAME PREFERENCES',
                  style: TextStyle(
                    color: GtnUiTokens.cyan,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  AppLocalizations.text('settings', 'Settings'),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.8,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Customize how Guess The Number looks and plays.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          _SettingsSection(
            eyebrow: '01 / LANGUAGE',
            title: 'Language & gameplay',
            description: 'Choose the language and challenge level used in your game.',
            children: [
              GtnExpressiveDropdown<String>(
                initialValue: settings.localeCode,
                decoration: InputDecoration(
                  labelText: AppLocalizations.text('language', 'Language'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  for (final locale in AppLocalizations.supportedLocales)
                    DropdownMenuItem<String>(
                      value: locale.$1,
                      child: Text(locale.$2),
                    ),
                ],
                onChanged: (code) {
                  if (code != null) {
                    onChanged(settings.copyWith(localeCode: code));
                  }
                },
              ),
              GtnExpressiveDropdown<String>(
                initialValue: settings.difficultyId,
                decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  helperText: 'Changes the target range, rewards and wrong-guess penalty.',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final id in DifficultyRules.ids)
                    DropdownMenuItem<String>(
                      value: id,
                      child: Text(DifficultyRules.name(id)),
                    ),
                ],
                onChanged: (id) {
                  if (id != null) {
                    onChanged(settings.copyWith(difficultyId: id));
                  }
                },
              ),
            ],
          ),
          _SettingsSection(
            eyebrow: '02 / APPEARANCE',
            title: 'Appearance',
            description: 'Keep the cosmic interface comfortable in different lighting.',
            children: [
              GtnExpressiveSwitchTile(
                secondary: const Icon(Icons.dark_mode_rounded),
                title: Text(AppLocalizations.text('dark_mode', 'Dark theme')),
                subtitle: Text(
                  AppLocalizations.text(
                    'dark_mode_desc',
                    'Use the darker GTN 2 appearance.',
                  ),
                ),
                value: settings.darkMode,
                onChanged: (value) => onChanged(
                  settings.copyWith(darkMode: value),
                ),
              ),
            ],
          ),
          _SettingsSection(
            eyebrow: '03 / ACCESSIBILITY',
            title: 'Visual comfort',
            description: 'Reduce interface movement when you prefer a calmer experience.',
            children: [
              GtnExpressiveSwitchTile(
                secondary: const Icon(Icons.motion_photos_off_rounded),
                title: Text(
                  AppLocalizations.text('reduce_motion', 'Reduce motion'),
                ),
                subtitle: Text(
                  AppLocalizations.text(
                    'reduce_motion_desc',
                    'Disable most interface animations.',
                  ),
                ),
                value: settings.reduceMotion,
                onChanged: (value) => onChanged(
                  settings.copyWith(reduceMotion: value),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(8, 10, 8, 0),
            child: Text(
              'Settings are saved with your active game profile.',
              style: TextStyle(
                color: GtnUiTokens.muted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.children,
  });

  final String eyebrow;
  final String title;
  final String description;
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
