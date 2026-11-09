import 'dart:async';

const playerStartupTimeout = Duration(seconds: 30);

Future<T> initializePlayerWithTimeout<T>(
  Future<T> initialization, {
  Duration timeout = playerStartupTimeout,
}) {
  return initialization.timeout(
    timeout,
    onTimeout: () => throw TimeoutException(
      'Player initialization exceeded the allowed startup time.',
      timeout,
    ),
  );
}
