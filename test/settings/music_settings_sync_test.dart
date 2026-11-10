import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/legacy/legacy_systems_state.dart';
import 'package:gtn_2/settings/game_settings.dart';
import 'package:gtn_2/settings/music_settings_sync.dart';

void main() {
  test('migrates older settings-backed music into progression state', () {
    final settings = GameSettings.initial.copyWith(
      backgroundMusicPath: '/music/current.mp3',
      musicLibraryPaths: const ['/music/a.mp3', '/music/b.mp3'],
      musicQueuePaths: const ['/music/b.mp3', '/music/a.mp3'],
      musicPlaylistPaths: const {
        'Favorites': ['/music/a.mp3'],
      },
      musicRepeatMode: 'all',
      musicShuffle: true,
    );

    final restored = restoreMusicStateFromSettings(
      settings: settings,
      systems: LegacySystemsState.initial,
    );

    expect(restored.musicLibrary, ['/music/a.mp3', '/music/b.mp3']);
    expect(restored.musicQueue, ['/music/b.mp3', '/music/a.mp3']);
    expect(restored.musicPlaylists, {
      'Favorites': ['/music/a.mp3'],
    });
    expect(restored.musicRepeatMode, 'all');
    expect(restored.musicShuffle, isTrue);
    expect(restored.currentTrackId, '/music/current.mp3');

    final synchronized = syncMusicSettingsFromLegacy(
      settings: GameSettings.initial,
      systems: restored,
    );
    expect(synchronized.musicLibraryPaths, restored.musicLibrary);
    expect(synchronized.musicQueuePaths, restored.musicQueue);
    expect(synchronized.musicPlaylistPaths, restored.musicPlaylists);
    expect(synchronized.musicRepeatMode, restored.musicRepeatMode);
    expect(synchronized.musicShuffle, restored.musicShuffle);
    expect(synchronized.backgroundMusicPath, restored.currentTrackId);
  });

  test('prefers progression music when both saved representations exist', () {
    final progression = LegacySystemsState.initial.copyWith(
      musicLibrary: const ['/music/progression.mp3'],
      musicQueue: const ['/music/progression.mp3'],
    );
    final settings = GameSettings.initial.copyWith(
      musicLibraryPaths: const ['/music/settings.mp3'],
    );

    final restored = restoreMusicStateFromSettings(
      settings: settings,
      systems: progression,
    );

    expect(restored.musicLibrary, ['/music/progression.mp3']);
    expect(restored.musicQueue, ['/music/progression.mp3']);
  });

  test('leaves empty music preferences unchanged', () {
    final systems = LegacySystemsState.initial;
    final restored = restoreMusicStateFromSettings(
      settings: GameSettings.initial,
      systems: systems,
    );
    expect(restored, same(systems));
  });
}
