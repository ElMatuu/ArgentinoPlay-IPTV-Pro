import 'package:argentino_play/services/player_remote_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

/// Fake implementation of VideoPlayerController for testing.
class FakeVideoPlayerController implements VideoPlayerController {
  bool _isPlaying = false;
  bool _isInitialized = false;
  Duration _position = Duration.zero;

  @override
  VideoPlayerValue get value => VideoPlayerValue(
        isInitialized: _isInitialized,
        isPlaying: _isPlaying,
        position: _position,
        duration: const Duration(seconds: 10),
        size: const Size(1920, 1080),
        rotationCorrection: 0,
        isLooping: false,
        isBuffering: false,
        errorDescription: null,
      );

  @override
  Future<void> initialize() async {
    _isInitialized = true;
  }

  @override
  Future<void> play() async {
    _isPlaying = true;
  }

  @override
  Future<void> pause() async {
    _isPlaying = false;
  }

  @override
  Future<void> seekTo(Duration moment) async {
    _position = moment;
  }

  @override
  Future<void> setLooping(bool looping) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  Stream<VideoEvent> get stream => Stream.value(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 10),
          size: const Size(1920, 1080),
          rotationCorrection: 0,
          isLooping: false,
        ),
      );

  @override
  Future<Duration> get position async => _position;

  @override
  void dispose() {}
}

void main() {
  group('PlayerRemoteController', () {
    late FakeVideoPlayerController fakeController;
    late PlayerRemoteController remoteController;

    setUp(() async {
      fakeController = FakeVideoPlayerController();
      await fakeController.initialize();
      remoteController = PlayerRemoteController(fakeController);
    });

    test('togglePlayPause toggles play/pause', () async {
      expect(fakeController.value.isPlaying, false);

      remoteController.togglePlayPause();
      expect(fakeController.value.isPlaying, true);

      remoteController.togglePlayPause();
      expect(fakeController.value.isPlaying, false);
    });

    test('play ensures playing state', () async {
      await fakeController.pause();
      expect(fakeController.value.isPlaying, false);

      remoteController.play();
      expect(fakeController.value.isPlaying, true);
    });

    test('pause ensures paused state', () async {
      await fakeController.play();
      expect(fakeController.value.isPlaying, true);

      remoteController.pause();
      expect(fakeController.value.isPlaying, false);
    });

    test('pause on already paused video stays paused', () async {
      await fakeController.pause();
      expect(fakeController.value.isPlaying, false);

      remoteController.pause();
      expect(fakeController.value.isPlaying, false);
    });

    test('play on already playing video stays playing', () async {
      await fakeController.play();
      expect(fakeController.value.isPlaying, true);

      remoteController.play();
      expect(fakeController.value.isPlaying, true);
    });

    test('remoteShortcuts returns correct bindings', () {
      final shortcuts = remoteController.remoteShortcuts();
      expect(shortcuts.length, 3);
      expect(
        shortcuts
            .containsKey(SingleActivator(LogicalKeyboardKey.mediaPlayPause)),
        true,
      );
      expect(
        shortcuts
            .containsKey(SingleActivator(LogicalKeyboardKey.mediaPlay)),
        true,
      );
      expect(
        shortcuts
            .containsKey(SingleActivator(LogicalKeyboardKey.mediaPause)),
        true,
      );
    });
  });
}
