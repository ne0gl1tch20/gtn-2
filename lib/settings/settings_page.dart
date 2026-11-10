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
    return Scaffold(
      appBar: GtnExpressiveAppBar(title: Text(AppLocalizations.text('settings', 'Settings'))),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
            child: GtnExpressiveDropdown<String>(
              initialValue: settings.localeCode,
              decoration: InputDecoration(
                labelText: AppLocalizations.text('language', 'Language'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final locale in AppLocalizations.supportedLocales)
                  DropdownMenuItem<String>(value: locale.$1, child: Text(locale.$2)),
              ],
              onChanged: (code) {
                if (code != null) onChanged(settings.copyWith(localeCode: code));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: GtnExpressiveDropdown<String>(
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
                if (id != null) onChanged(settings.copyWith(difficultyId: id));
              },
            ),
          ),
          GtnExpressiveSwitchTile(
            secondary: const Icon(Icons.dark_mode_rounded),
            title: Text(AppLocalizations.text('dark_mode', 'Dark theme')),
            subtitle: Text(AppLocalizations.text('dark_mode_desc', 'Use the darker GTN 2 appearance.')),
            value: settings.darkMode,
            onChanged: (value) => onChanged(settings.copyWith(darkMode: value)),
          ),
          GtnExpressiveSwitchTile(
            secondary: const Icon(Icons.motion_photos_off_rounded),
            title: Text(AppLocalizations.text('reduce_motion', 'Reduce motion')),
            subtitle: Text(AppLocalizations.text('reduce_motion_desc', 'Disable most interface animations.')),
            value: settings.reduceMotion,
            onChanged: (value) => onChanged(settings.copyWith(reduceMotion: value)),
          ),
        ],
      ),
    );
  }
}
