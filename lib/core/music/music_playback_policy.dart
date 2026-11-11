enum MusicPlaybackAction {
  pause,
  resume,
  replayCurrent,
  playQueue,
  importTracks,
}

/// Resolves the Play/Pause control without assuming a saved path is already
/// loaded into the current AudioPlayer instance.
class MusicPlaybackPolicy {
  const MusicPlaybackPolicy._();

  static MusicPlaybackAction resolve({
    required bool isPlaying,
    required bool playerIsPaused,
    required bool currentTrackExists,
    required bool hasQueuedTracks,
  }) {
    if (isPlaying) return MusicPlaybackAction.pause;
    if (playerIsPaused) return MusicPlaybackAction.resume;
    if (currentTrackExists) return MusicPlaybackAction.replayCurrent;
    if (hasQueuedTracks) return MusicPlaybackAction.playQueue;
    return MusicPlaybackAction.importTracks;
  }
}
