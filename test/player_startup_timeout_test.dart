import 'dart:async';

import 'package:argentino_play/services/player_startup_timeout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('initializePlayerWithTimeout', () {
    test('returns when player initialization completes in time', () async {
      final result = await initializePlayerWithTimeout(
        Future<int>.value(42),
      );

      expect(result, 42);
    });

    test('throws a timeout when initialization takes too long', () async {
      final pendingInitialization = Completer<void>();

      await expectLater(
        initializePlayerWithTimeout(
          pendingInitialization.future,
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('preserves initialization errors', () async {
      final failure = StateError('decoder unavailable');

      await expectLater(
        initializePlayerWithTimeout<void>(
          Future<void>.error(failure),
        ),
        throwsA(same(failure)),
      );
    });
  });
}
