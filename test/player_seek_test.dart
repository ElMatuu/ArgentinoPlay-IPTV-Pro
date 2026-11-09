import 'package:argentino_play/services/player_seek.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateSeekTarget', () {
    const duration = Duration(minutes: 2);

    test('advances by the requested offset', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 30),
          duration: duration,
          offset: const Duration(seconds: 10),
        ),
        const Duration(seconds: 40),
      );
    });

    test('rewinds by the requested offset', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 30),
          duration: duration,
          offset: const Duration(seconds: -10),
        ),
        const Duration(seconds: 20),
      );
    });

    test('clamps rewind at the beginning', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 3),
          duration: duration,
          offset: const Duration(seconds: -10),
        ),
        Duration.zero,
      );
    });

    test('clamps fast forward at the media duration', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 115),
          duration: duration,
          offset: const Duration(seconds: 10),
        ),
        duration,
      );
    });

    test('returns null when duration is zero or negative', () {
      for (final invalidDuration in [
        Duration.zero,
        const Duration(seconds: -1),
      ]) {
        expect(
          calculateSeekTarget(
            position: const Duration(seconds: 10),
            duration: invalidDuration,
            offset: const Duration(seconds: 10),
          ),
          isNull,
        );
      }
    });

    test('preserves millisecond precision', () {
      expect(
        calculateSeekTarget(
          position: const Duration(milliseconds: 1234),
          duration: duration,
          offset: const Duration(milliseconds: 567),
        ),
        const Duration(milliseconds: 1801),
      );
    });
  });
}
