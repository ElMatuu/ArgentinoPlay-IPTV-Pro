import 'package:flutter/services.dart';

enum PlayerRemoteAction {
  toggle,
  play,
  pause,
  seekBackward,
  seekForward,
  back,
}

PlayerRemoteAction? playerRemoteActionForKey(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.mediaPlayPause ||
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.space) {
    return PlayerRemoteAction.toggle;
  }
  if (key == LogicalKeyboardKey.mediaPlay) return PlayerRemoteAction.play;
  if (key == LogicalKeyboardKey.mediaPause) return PlayerRemoteAction.pause;
  if (key == LogicalKeyboardKey.arrowLeft) {
    return PlayerRemoteAction.seekBackward;
  }
  if (key == LogicalKeyboardKey.arrowRight) {
    return PlayerRemoteAction.seekForward;
  }
  if (key == LogicalKeyboardKey.goBack ||
      key == LogicalKeyboardKey.escape ||
      key == LogicalKeyboardKey.browserBack) {
    return PlayerRemoteAction.back;
  }
  return null;
}
