import 'package:argentino_play/services/player_remote_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeRemotePlaybackController implements RemotePlaybackController {
  bool initialized = true;
  bool playing = false;

  @override
  bool get isInitialized => initialized;

  @override
  bool get isPlaying => playing;

  @override
  Future<void> play() async {
    playing = true;
  }

  @override
  Future<void> pause() async {
    playing = false;
  }
}

void main() {
  group('PlayerRemoteController', () {
    late FakeRemotePlaybackController fakeController;
    late PlayerRemoteController remoteController;

    setUp(() {
      fakeController = FakeRemotePlaybackController();
      remoteController = PlayerRemoteController(fakeController);
    });

    test('togglePlayPause toggles play/pause', () {
      expect(fakeController.isPlaying, false);

      remoteController.togglePlayPause();
      expect(fakeController.isPlaying, true);

      remoteController.togglePlayPause();
      expect(fakeController.isPlaying, false);
    });

    test('play ensures playing state', () {
      remoteController.play();
      expect(fakeController.isPlaying, true);
    });

    test('pause ensures paused state', () {
      fakeController.playing = true;

      remoteController.pause();
      expect(fakeController.isPlaying, false);
    });

    test('pause on already paused video stays paused', () {
      remoteController.pause();
      expect(fakeController.isPlaying, false);
    });

    test('play on already playing video stays playing', () {
      fakeController.playing = true;

      remoteController.play();
      expect(fakeController.isPlaying, true);
    });

    test('does nothing before the player is initialized', () {
      fakeController.initialized = false;

      remoteController.play();
      remoteController.pause();
      remoteController.togglePlayPause();

      expect(fakeController.isPlaying, false);
    });

    test('remoteShortcuts returns all three media-key bindings', () {
      final shortcuts = remoteController.remoteShortcuts();

      expect(shortcuts.length, 3);
      expect(
        shortcuts.containsKey(
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause),
        ),
        isTrue,
      );
      expect(
        shortcuts.containsKey(
          const SingleActivator(LogicalKeyboardKey.mediaPlay),
        ),
        isTrue,
      );
      expect(
        shortcuts.containsKey(
          const SingleActivator(LogicalKeyboardKey.mediaPause),
        ),
        isTrue,
      );
    });
  });
}
