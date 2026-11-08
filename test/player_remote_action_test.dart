import 'package:argentino_play/services/player_remote_action.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('playerRemoteActionForKey', () {
    test('maps select, enter, space and media toggle to toggle', () {
      for (final key in [
        LogicalKeyboardKey.mediaPlayPause,
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.enter,
        LogicalKeyboardKey.numpadEnter,
        LogicalKeyboardKey.space,
      ]) {
        expect(playerRemoteActionForKey(key), PlayerRemoteAction.toggle);
      }
    });

    test('maps dedicated media keys to play and pause', () {
      expect(
        playerRemoteActionForKey(LogicalKeyboardKey.mediaPlay),
        PlayerRemoteAction.play,
      );
      expect(
        playerRemoteActionForKey(LogicalKeyboardKey.mediaPause),
        PlayerRemoteAction.pause,
      );
    });

    test('maps left and right arrows to ten-second seeking', () {
      expect(
        playerRemoteActionForKey(LogicalKeyboardKey.arrowLeft),
        PlayerRemoteAction.seekBackward,
      );
      expect(
        playerRemoteActionForKey(LogicalKeyboardKey.arrowRight),
        PlayerRemoteAction.seekForward,
      );
    });

    test('ignores navigation keys without a player action', () {
      expect(playerRemoteActionForKey(LogicalKeyboardKey.arrowUp), isNull);
      expect(playerRemoteActionForKey(LogicalKeyboardKey.escape), isNull);
    });
  });
}
