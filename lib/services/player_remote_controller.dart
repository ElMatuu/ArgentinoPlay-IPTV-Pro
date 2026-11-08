import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Handles remote control actions for video playback.
///
/// This class provides a clean separation between the remote control logic
/// and the UI, allowing for easier testing and reusability.
class PlayerRemoteController {
  final VideoPlayerController? _controller;

  /// Creates a [PlayerRemoteController] for the given video player controller.
  PlayerRemoteController(this._controller);

  /// Toggles between play and pause states.
  ///
  /// If the controller is playing, it will be paused. If paused, it will play.
  /// Does nothing if the controller is null or not initialized.
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

  /// Ensures the video is playing.
  ///
  /// If the controller is already playing, this is a no-op.
  /// If paused, it will start playing.
  /// Does nothing if the controller is null or not initialized.
  void play() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    controller.play();
  }

  /// Ensures the video is paused.
  ///
  /// If the controller is already paused, this is a no-op.
  /// If playing, it will be paused.
  /// Does nothing if the controller is null or not initialized.
  void pause() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    controller.pause();
  }

  /// Returns the shortcut bindings for remote control keys.
  ///
  /// Maps media keys to their respective actions:
  /// - mediaPlayPause: toggles play/pause
  /// - mediaPlay: ensures playing
  /// - mediaPause: ensures paused
  Map<ShortcutActivator, VoidCallback> remoteShortcuts() {
    return {
      SingleActivator(LogicalKeyboardKey.mediaPlayPause): togglePlayPause,
      SingleActivator(LogicalKeyboardKey.mediaPlay): play,
      SingleActivator(LogicalKeyboardKey.mediaPause): pause,
    };
  }
}
