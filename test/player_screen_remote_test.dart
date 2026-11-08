import 'package:argentino_play/domain/tv_channel.dart';
import 'package:argentino_play/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  group('PlayerScreen remote control', () {
    late VideoPlayerPlatform fakePlatform;

    setUp(() {
      fakePlatform = FakeVideoPlayerPlatform();
      VideoPlayerPlatform.instance = fakePlatform;
    });

    tearDown(() {
      VideoPlayerPlatform.instance = null;
    });

    testWidgets('mediaPlayPause toggles play/pause', (WidgetTester tester) async {
      final channel = TvChannel(
        name: 'Test Channel',
        url: 'https://example.com/stream.m3u8',
        logo: '',
        group: 'Test',
        tvgId: 'test',
        country: '',
        language: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(channel: channel),
        ),
      );

      // Esperar a que el controlador se inicialice
      await tester.pumpAndSettle();

      // Simular tecla mediaPlayPause
      await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.pumpAndSettle();

      // Verificar que el video está reproduciéndose
      final fakeController = fakePlatform.fakeController;
      expect(fakeController?.isPlaying, true);

      // Simular tecla mediaPlayPause de nuevo
      await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlayPause);
      await tester.pumpAndSettle();

      // Verificar que el video está pausado
      expect(fakeController?.isPlaying, false);
    });

    testWidgets('mediaPlay ensures playing state', (WidgetTester tester) async {
      final channel = TvChannel(
        name: 'Test Channel',
        url: 'https://example.com/stream.m3u8',
        logo: '',
        group: 'Test',
        tvgId: 'test',
        country: '',
        language: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(channel: channel),
        ),
      );

      await tester.pumpAndSettle();

      // Pausar el video
      final fakeController = fakePlatform.fakeController;
      fakeController?.pause();
      await tester.pumpAndSettle();
      expect(fakeController?.isPlaying, false);

      // Simular tecla mediaPlay
      await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlay);
      await tester.pumpAndSettle();

      // Verificar que el video está reproduciéndose
      expect(fakeController?.isPlaying, true);
    });

    testWidgets('mediaPause ensures paused state', (WidgetTester tester) async {
      final channel = TvChannel(
        name: 'Test Channel',
        url: 'https://example.com/stream.m3u8',
        logo: '',
        group: 'Test',
        tvgId: 'test',
        country: '',
        language: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(channel: channel),
        ),
      );

      await tester.pumpAndSettle();

      // Asegurar que el video está reproduciéndose
      final fakeController = fakePlatform.fakeController;
      fakeController?.play();
      await tester.pumpAndSettle();
      expect(fakeController?.isPlaying, true);

      // Simular tecla mediaPause
      await tester.sendKeyEvent(LogicalKeyboardKey.mediaPause);
      await tester.pumpAndSettle();

      // Verificar que el video está pausado
      expect(fakeController?.isPlaying, false);
    });

    testWidgets('mediaPause on already paused video stays paused', (WidgetTester tester) async {
      final channel = TvChannel(
        name: 'Test Channel',
        url: 'https://example.com/stream.m3u8',
        logo: '',
        group: 'Test',
        tvgId: 'test',
        country: '',
        language: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(channel: channel),
        ),
      );

      await tester.pumpAndSettle();

      // Asegurar que el video está pausado
      final fakeController = fakePlatform.fakeController;
      fakeController?.pause();
      await tester.pumpAndSettle();
      expect(fakeController?.isPlaying, false);

      // Simular tecla mediaPause
      await tester.sendKeyEvent(LogicalKeyboardKey.mediaPause);
      await tester.pumpAndSettle();

      // Verificar que el video sigue pausado
      expect(fakeController?.isPlaying, false);
    });

    testWidgets('mediaPlay on already playing video stays playing', (WidgetTester tester) async {
      final channel = TvChannel(
        name: 'Test Channel',
        url: 'https://example.com/stream.m3u8',
        logo: '',
        group: 'Test',
        tvgId: 'test',
        country: '',
        language: '',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PlayerScreen(channel: channel),
        ),
      );

      await tester.pumpAndSettle();

      // Asegurar que el video está reproduciéndose
      final fakeController = fakePlatform.fakeController;
      fakeController?.play();
      await tester.pumpAndSettle();
      expect(fakeController?.isPlaying, true);

      // Simular tecla mediaPlay
      await tester.sendKeyEvent(LogicalKeyboardKey.mediaPlay);
      await tester.pumpAndSettle();

      // Verificar que el video sigue reproduciéndose
      expect(fakeController?.isPlaying, true);
    });
  });
}

/// Fake implementation of VideoPlayerPlatform for testing
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  FakeVideoPlayerController? fakeController;

  @override
  Future<void> init() async {}

  @override
  Future<int?> create(DataSource dataSource) async {
    fakeController = FakeVideoPlayerController();
    return 0;
  }

  @override
  Future<void> dispose(int textureId) async {
    fakeController = null;
  }

  @override
  Widget buildView(int textureId) {
    return const SizedBox();
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return Stream.value(VideoEvent(
      eventType: VideoEventType.initialized,
      duration: const Duration(seconds: 10),
      size: const Size(1920, 1080),
      rotationCorrection: 0,
      isLooping: false,
    ));
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {}

  @override
  Future<void> setVolume(int textureId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {}

  @override
  Future<Duration> getPosition(int textureId) async => Duration.zero;

  @override
  Future<void> seekTo(int textureId, Duration position) async {}

  @override
  Future<void> pause(int textureId) async {
    fakeController?.pause();
  }

  @override
  Future<void> play(int textureId) async {
    fakeController?.play();
  }
}

class FakeVideoPlayerController {
  bool isPlaying = false;

  void play() {
    isPlaying = true;
  }

  void pause() {
    isPlaying = false;
  }
}
