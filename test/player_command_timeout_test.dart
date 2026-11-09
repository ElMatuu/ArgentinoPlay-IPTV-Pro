import 'dart:async';

import 'package:argentino_play/services/player_command_timeout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('runPlayerCommandWithTimeout', () {
    test('returns when a player command completes in time', () async {
      final result = await runPlayerCommandWithTimeout(
        Future<int>.value(42),
      );

      expect(result, 42);
    });

    test('throws a timeout when a player command stalls', () async {
      final pendingCommand = Completer<void>();

      await expectLater(
        runPlayerCommandWithTimeout(
          pendingCommand.future,
          timeout: const Duration(milliseconds: 10),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('preserves player command errors', () async {
      final failure = StateError('decoder unavailable');

      await expectLater(
        runPlayerCommandWithTimeout<void>(Future<void>.error(failure)),
        throwsA(same(failure)),
      );
    });
  });
}
