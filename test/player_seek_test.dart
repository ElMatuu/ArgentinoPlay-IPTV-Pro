import 'package:argentino_play/services/player_seek.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateSeekTarget', () {
    const duration = Duration(minutes: 2);

    test('applies a forward seek inside the media duration', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 30),
          duration: duration,
          offset: const Duration(seconds: 10),
        ),
        const Duration(seconds: 40),
      );
    });

    test('clamps a backward seek at the beginning', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 5),
          duration: duration,
          offset: const Duration(seconds: -10),
        ),
        Duration.zero,
      );
    });

    test('clamps a forward seek at the end', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 115),
          duration: duration,
          offset: const Duration(seconds: 10),
        ),
        duration,
      );
    });

    test('returns null when duration is unknown or zero', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 5),
          duration: Duration.zero,
          offset: const Duration(seconds: 10),
        ),
        isNull,
      );
    });

    test('returns null for a negative duration', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 5),
          duration: const Duration(seconds: -1),
          offset: const Duration(seconds: 10),
        ),
        isNull,
      );
    });

    test('clamps an out-of-range current position before seeking', () {
      expect(
        calculateSeekTarget(
          position: const Duration(minutes: 3),
          duration: duration,
          offset: const Duration(seconds: -10),
        ),
        duration,
      );
    });

    test('handles offsets larger than the media duration', () {
      expect(
        calculateSeekTarget(
          position: const Duration(seconds: 30),
          duration: duration,
          offset: const Duration(hours: 1),
        ),
        duration,
      );
    });
  });
}
