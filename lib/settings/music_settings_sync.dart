import '../core/legacy/legacy_systems_state.dart';
import 'game_settings.dart';

bool _hasMusicInSettings(GameSettings settings) =>
    settings.musicLibraryPaths.isNotEmpty ||
    settings.musicQueuePaths.isNotEmpty ||
    settings.musicPlaylistPaths.isNotEmpty ||
    settings.backgroundMusicPath != null ||
    settings.musicRepeatMode != 'off' ||
    settings.musicShuffle;

bool _hasMusicInLegacySystems(LegacySystemsState systems) =>
    systems.musicLibrary.isNotEmpty ||
    systems.musicQueue.isNotEmpty ||
    systems.musicPlaylists.isNotEmpty ||
    systems.currentTrackId != null ||
    systems.musicRepeatMode != 'off' ||
    systems.musicShuffle;

/// Migrates music data from the older settings-backed representation only
/// when the progression-backed music state is still empty.
LegacySystemsState restoreMusicStateFromSettings({
  required GameSettings settings,
  required LegacySystemsState systems,
}) {
  if (_hasMusicInLegacySystems(systems) || !_hasMusicInSettings(settings)) {
    return systems;
  }
  return systems.copyWith(
    musicLibrary: settings.musicLibraryPaths,
    musicQueue: settings.musicQueuePaths,
    musicPlaylists: settings.musicPlaylistPaths,
    musicRepeatMode: settings.musicRepeatMode,
    musicShuffle: settings.musicShuffle,
    currentTrackId: settings.backgroundMusicPath,
    clearCurrentTrack: settings.backgroundMusicPath == null,
  );
}

/// Mirrors the active progression-backed music state into GameSettings so
/// existing GTN1 settings readers and save migrations see the same library.
GameSettings syncMusicSettingsFromLegacy({
  required GameSettings settings,
  required LegacySystemsState systems,
}) => settings.copyWith(
  backgroundMusicPath: systems.currentTrackId,
  clearBackgroundMusicPath: systems.currentTrackId == null,
  musicLibraryPaths: systems.musicLibrary,
  musicQueuePaths: systems.musicQueue,
  musicPlaylistPaths: systems.musicPlaylists,
  musicRepeatMode: systems.musicRepeatMode,
  musicShuffle: systems.musicShuffle,
);
