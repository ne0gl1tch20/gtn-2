import 'package:flutter_test/flutter_test.dart';
import 'package:gtn_2/core/music/music_playback_policy.dart';

void main() {
  test('playing player pauses', () {
    expect(
      MusicPlaybackPolicy.resolve(
        isPlaying: true,
        playerIsPaused: false,
        currentTrackExists: true,
        hasQueuedTracks: true,
      ),
      MusicPlaybackAction.pause,
    );
  });

  test('paused loaded source resumes', () {
    expect(
      MusicPlaybackPolicy.resolve(
        isPlaying: false,
        playerIsPaused: true,
        currentTrackExists: true,
        hasQueuedTracks: true,
      ),
      MusicPlaybackAction.resume,
    );
  });

  test('saved current track is loaded again after player restart', () {
    expect(
      MusicPlaybackPolicy.resolve(
        isPlaying: false,
        playerIsPaused: false,
        currentTrackExists: true,
        hasQueuedTracks: true,
      ),
      MusicPlaybackAction.replayCurrent,
    );
  });

  test('falls back to queue when saved current track is missing', () {
    expect(
      MusicPlaybackPolicy.resolve(
        isPlaying: false,
        playerIsPaused: false,
        currentTrackExists: false,
        hasQueuedTracks: true,
      ),
      MusicPlaybackAction.playQueue,
    );
  });

  test('requests import when no saved track or queue exists', () {
    expect(
      MusicPlaybackPolicy.resolve(
        isPlaying: false,
        playerIsPaused: false,
        currentTrackExists: false,
        hasQueuedTracks: false,
      ),
      MusicPlaybackAction.importTracks,
    );
  });
}
