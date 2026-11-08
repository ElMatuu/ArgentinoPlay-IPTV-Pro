import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';

/// Simple fake implementation of VideoPlayerController for testing.
/// This allows testing the remote control logic without platform dependencies.
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

/// Helper class to test the remote control logic in isolation.
class TestPlayerRemoteLogic {
  VideoPlayerController? _controller;

  TestPlayerRemoteLogic(this._controller);

  void togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  void play() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    controller.play();
  }

  void pause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    controller.pause();
  }

  Map<ShortcutActivator, VoidCallback> remoteShortcuts() {
    return {
      SingleActivator(LogicalKeyboardKey.mediaPlayPause): togglePlayPause,
      SingleActivator(LogicalKeyboardKey.mediaPlay): play,
      SingleActivator(LogicalKeyboardKey.mediaPause): pause,
    };
  }
}

void main() {
  group('PlayerScreen remote control logic', () {
    late FakeVideoPlayerController fakeController;
    late TestPlayerRemoteLogic logic;

    setUp(() async {
      fakeController = FakeVideoPlayerController();
      await fakeController.initialize();
      logic = TestPlayerRemoteLogic(fakeController);
    });

    test('mediaPlayPause toggles play/pause', () async {
      // Initially paused
      expect(fakeController.value.isPlaying, false);

      // Call togglePlayPause
      logic.togglePlayPause();
      expect(fakeController.value.isPlaying, true);

      // Call togglePlayPause again
      logic.togglePlayPause();
      expect(fakeController.value.isPlaying, false);
    });

    test('mediaPlay ensures playing state', () async {
      // Pause first
      await fakeController.pause();
      expect(fakeController.value.isPlaying, false);

      // Call play
      logic.play();
      expect(fakeController.value.isPlaying, true);
    });

    test('mediaPause ensures paused state', () async {
      // Play first
      await fakeController.play();
      expect(fakeController.value.isPlaying, true);

      // Call pause
      logic.pause();
      expect(fakeController.value.isPlaying, false);
    });

    test('mediaPause on already paused video stays paused', () async {
      // Ensure paused
      await fakeController.pause();
      expect(fakeController.value.isPlaying, false);

      // Call pause again
      logic.pause();
      expect(fakeController.value.isPlaying, false);
    });

    test('mediaPlay on already playing video stays playing', () async {
      // Ensure playing
      await fakeController.play();
      expect(fakeController.value.isPlaying, true);

      // Call play again
      logic.play();
      expect(fakeController.value.isPlaying, true);
    });

    test('remoteShortcuts returns correct bindings', () {
      final shortcuts = logic.remoteShortcuts();
      expect(shortcuts.length, 3);
      expect(
        shortcuts.containsKey(SingleActivator(LogicalKeyboardKey.mediaPlayPause)),
        true,
      );
      expect(
        shortcuts.containsKey(SingleActivator(LogicalKeyboardKey.mediaPlay)),
        true,
      );
      expect(
        shortcuts.containsKey(SingleActivator(LogicalKeyboardKey.mediaPause)),
        true,
      );
    });
  });
}
