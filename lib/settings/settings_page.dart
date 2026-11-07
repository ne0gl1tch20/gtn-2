import 'package:flutter/material.dart';

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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_rounded),
            title: const Text('Dark theme'),
            subtitle: const Text('Use the darker GTN 2 appearance.'),
            value: settings.darkMode,
            onChanged: (value) => onChanged(settings.copyWith(darkMode: value)),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.motion_photos_off_rounded),
            title: const Text('Reduce motion'),
            subtitle: const Text('Disable most interface animations.'),
            value: settings.reduceMotion,
            onChanged: (value) => onChanged(settings.copyWith(reduceMotion: value)),
          ),
        ],
      ),
    );
  }
}
