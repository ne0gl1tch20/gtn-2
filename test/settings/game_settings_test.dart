import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/settings/game_settings.dart';

void main() {
  test('GTN1 preferences round-trip through the save model', () {
    final settings = GameSettings.initial.copyWith(
      themeMode: 'AMOLED',
      darkMode: true,
      numberNotation: 'Scientific',
      localeCode: 'fil',
      difficultyId: 'hard',
      reduceMotion: true,
      musicEnabled: false,
      soundEnabled: false,
      vibrationEnabled: false,
      notificationsEnabled: false,
      notificationRemindersEnabled: false,
      notificationProgressionEnabled: true,
      notificationEventsEnabled: false,
      notificationIntervalHours: 48,
      volume: .72,
      sfxVolume: .35,
      reduceFlashes: true,
      saveLogsToStorage: true,
      verboseLogging: true,
      backgroundMusicPath: '/music/current.mp3',
      musicLibraryPaths: const ['/music/a.mp3', '/music/b.mp3'],
      musicQueuePaths: const ['/music/b.mp3', '/music/a.mp3'],
      musicPlaylistPaths: const {
        'favorites': ['/music/a.mp3'],
      },
      musicRepeatMode: 'all',
      musicShuffle: true,
      themePreset: 'Custom',
      customPrimaryColor: '#2196F3',
      customSecondaryColor: '#00BCD4',
      customTertiaryColor: '#00C853',
      moreScreenOrder: const ['music', 'settings', 'about'],
      moreScreenButtonColors: const {'music': '#2196F3'},
      webMenuStudioLayout: '{"areas":{"music":"more"}}',
      tutorialCompleted: true,
      tutorialSeenFeatures: const {'arcade', 'worlds'},
      updateCheckIntervalHours: 168,
    );
    final restored = GameSettings.fromJson(settings.toJson());
    expect(restored.themeMode, 'AMOLED');
    expect(restored.darkMode, isTrue);
    expect(restored.numberNotation, 'Scientific');
    expect(restored.localeCode, 'fil');
    expect(restored.difficultyId, 'hard');
    expect(restored.reduceMotion, isTrue);
    expect(restored.musicEnabled, isFalse);
    expect(restored.soundEnabled, isFalse);
    expect(restored.vibrationEnabled, isFalse);
    expect(restored.notificationsEnabled, isFalse);
    expect(restored.notificationRemindersEnabled, isFalse);
    expect(restored.notificationProgressionEnabled, isTrue);
    expect(restored.notificationEventsEnabled, isFalse);
    expect(restored.notificationIntervalHours, 48);
    expect(restored.volume, .72);
    expect(restored.sfxVolume, .35);
    expect(restored.reduceFlashes, isTrue);
    expect(restored.saveLogsToStorage, isTrue);
    expect(restored.verboseLogging, isTrue);
    expect(restored.backgroundMusicPath, '/music/current.mp3');
    expect(restored.musicLibraryPaths, ['/music/a.mp3', '/music/b.mp3']);
    expect(restored.musicQueuePaths, ['/music/b.mp3', '/music/a.mp3']);
    expect(restored.musicPlaylistPaths, {
      'favorites': ['/music/a.mp3'],
    });
    expect(restored.musicRepeatMode, 'all');
    expect(restored.musicShuffle, isTrue);
    expect(restored.themePreset, 'Custom');
    expect(restored.customPrimaryColor, '#2196F3');
    expect(restored.customSecondaryColor, '#00BCD4');
    expect(restored.customTertiaryColor, '#00C853');
    expect(restored.moreScreenOrder, ['music', 'settings', 'about']);
    expect(restored.moreScreenButtonColors, {'music': '#2196F3'});
    expect(restored.webMenuStudioLayout, '{"areas":{"music":"more"}}');
    expect(restored.tutorialCompleted, isTrue);
    expect(restored.tutorialSeenFeatures, {'arcade', 'worlds'});
    expect(restored.updateCheckIntervalHours, 168);
  });

  test('older GTN2 settings retain their original defaults', () {
    final restored = GameSettings.fromJson({
      'darkMode': false,
      'reduceMotion': true,
      'localeCode': 'en_us',
      'difficultyId': 'hard',
    });
    expect(restored.darkMode, isFalse);
    expect(restored.reduceMotion, isTrue);
    expect(restored.themeMode, 'Light');
    expect(restored.musicEnabled, isTrue);
    expect(restored.numberNotation, 'Standard');
  });

  test('invalid preference values are rejected', () {
    expect(
      () => GameSettings.fromJson({
        'darkMode': true,
        'reduceMotion': false,
        'volume': 2,
      }),
      throwsFormatException,
    );
  });

  test('system theme preserves the legacy dark mode fallback', () {
    final settings = GameSettings.initial;
    final restored = GameSettings.fromJson(settings.toJson());
    expect(restored.themeMode, 'System');
    expect(restored.darkMode, isTrue);
  });
}
