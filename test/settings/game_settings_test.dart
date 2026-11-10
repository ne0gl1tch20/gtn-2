import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/settings/game_settings.dart';

void main() {
  test('GTN1 preferences round-trip through the save model', () {
    final settings = GameSettings.initial.copyWith(
      themeMode: 'AMOLED', darkMode: true, numberNotation: 'Scientific',
      musicEnabled: false, soundEnabled: false, vibrationEnabled: false,
      notificationsEnabled: true, notificationIntervalHours: 48,
      volume: .72, sfxVolume: .35, reduceFlashes: true,
      updateCheckIntervalHours: 24, themePreset: 'Ocean',
      customPrimaryColor: '#2196F3',
      musicLibraryPaths: const ['/music/a.mp3'],
      musicQueuePaths: const ['/music/a.mp3'], musicRepeatMode: 'all',
      musicShuffle: true, tutorialSeenFeatures: const {'arcade', 'worlds'},
    );
    final restored = GameSettings.fromJson(settings.toJson());
    expect(restored.themeMode, 'AMOLED');
    expect(restored.numberNotation, 'Scientific');
    expect(restored.musicEnabled, isFalse);
    expect(restored.notificationIntervalHours, 48);
    expect(restored.volume, .72);
    expect(restored.sfxVolume, .35);
    expect(restored.reduceFlashes, isTrue);
    expect(restored.updateCheckIntervalHours, 24);
    expect(restored.customPrimaryColor, '#2196F3');
    expect(restored.musicLibraryPaths, ['/music/a.mp3']);
    expect(restored.musicRepeatMode, 'all');
    expect(restored.musicShuffle, isTrue);
    expect(restored.tutorialSeenFeatures, {'arcade', 'worlds'});
  });

  test('older GTN2 settings retain their original defaults', () {
    final restored = GameSettings.fromJson({
      'darkMode': false, 'reduceMotion': true,
      'localeCode': 'en_us', 'difficultyId': 'hard',
    });
    expect(restored.darkMode, isFalse);
    expect(restored.reduceMotion, isTrue);
    expect(restored.themeMode, 'Light');
    expect(restored.musicEnabled, isTrue);
    expect(restored.numberNotation, 'Standard');
  });

  test('invalid preference values are rejected', () {
    expect(
      () => GameSettings.fromJson({'darkMode': true, 'reduceMotion': false, 'volume': 2}),
      throwsFormatException,
    );
  });
}
