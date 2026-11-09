import 'dart:async';

const playerCommandTimeout = Duration(seconds: 15);

Future<T> runPlayerCommandWithTimeout<T>(
  Future<T> command, {
  Duration timeout = playerCommandTimeout,
}) {
  return command.timeout(
    timeout,
    onTimeout: () => throw TimeoutException(
      'Player command exceeded the allowed response time.',
      timeout,
    ),
  );
}
