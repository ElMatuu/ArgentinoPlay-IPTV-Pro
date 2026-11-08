import 'package:flutter/material.dart';

/// Minimal playback contract used by remote-control actions.
abstract interface class RemotePlaybackController {
  bool get isInitialized;
  bool get isPlaying;
  Future<void> play();
  Future<void> pause();
}

/// Adapts the app's video_player controller to the remote playback contract.
class VideoPlayerRemotePlaybackController
    implements RemotePlaybackController {
  VideoPlayerRemotePlaybackController(this._controller);

  final VideoPlayerController _controller;

  @override
  bool get isInitialized => _controller.value.isInitialized;

  @override
  bool get isPlaying => _controller.value.isPlaying;

  @override
  Future<void> play() => _controller.play();

  @override
  Future<void> pause() => _controller.pause();
}

/// Handles media-key actions independently from the concrete video player.
class PlayerRemoteController {
  PlayerRemoteController(this._controller);

  /// Creates a remote controller backed by the app's video player.
  factory PlayerRemoteController.fromVideoPlayer(
    VideoPlayerController? controller,
  ) {
    return PlayerRemoteController(
      controller == null
          ? null
          : VideoPlayerRemotePlaybackController(controller),
    );
  }

  final RemotePlaybackController? _controller;

  /// Toggles between play and pause states.
  void togglePlayPause() {
    final controller = _controller;
    if (controller == null || !controller.isInitialized) {
      return;
    }
    if (controller.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  /// Ensures playback is started when the player is initialized.
  void play() {
    final controller = _controller;
    if (controller == null || !controller.isInitialized) {
      return;
    }
    controller.play();
  }

  /// Ensures playback is paused when the player is initialized.
  void pause() {
    final controller = _controller;
    if (controller == null || !controller.isInitialized) {
      return;
    }
    controller.pause();
  }

  /// Returns the shortcut bindings for Android TV media keys.
  Map<ShortcutActivator, VoidCallback> remoteShortcuts() {
    return {
      const SingleActivator(LogicalKeyboardKey.mediaPlayPause):
          togglePlayPause,
      const SingleActivator(LogicalKeyboardKey.mediaPlay): play,
      const SingleActivator(LogicalKeyboardKey.mediaPause): pause,
    };
  }
}
